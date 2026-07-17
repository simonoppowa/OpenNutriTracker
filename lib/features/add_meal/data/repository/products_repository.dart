import 'dart:io';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/off_country.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ProductsRepository {
  static final _log = Logger('ProductsRepository');

  // Number of re-ranked OFF results to surface from the larger relevance pool.
  static const _searchResultLimit = 25;

  // Reciprocal-rank-fusion constant. Lower values let relevance dominate (keeps
  // specific multi-word queries sharp); higher values let popularity dominate.
  // 10 keeps exact matches near the top while floating popular, well-maintained
  // products up and sinking sparse/duplicate entries — validated across brand
  // ("nutella"), descriptive ("oat milk", "greek yogurt") and specific queries.
  static const _rankFusionK = 10;

  // Soft multiplier applied to the fused score of products sold in the user's
  // country. 1.3 lifts locally-available products a clear notch without burying
  // a much more popular/relevant global match — non-local products still
  // appear, just lower. Tuned against live results for a GB user.
  static const _localCountryBoost = 1.3;

  final OFFDataSource _offDataSource;
  final FDCDataSource _fdcDataSource;
  final SpFoodDataSource _spBackendDataSource;

  ProductsRepository(
    this._offDataSource,
    this._fdcDataSource,
    this._spBackendDataSource,
  );

  Future<List<MealEntity>> getOFFProductsByString(String searchString) async {
    final offWordResponse = await _offDataSource.fetchSearchWordResults(
      searchString,
    );

    // The API returns hits in relevance order. Keep that as the relevance
    // signal, drop items without nutriments or that fail plausibility, then
    // re-rank by fusing relevance position with OFF's popularity_key so
    // popular, well-maintained products surface first — without letting
    // popularity drag in off-topic matches the way a hard popularity sort does.
    final userCountryTag = OffCountry.fromLocale(Platform.localeName);
    final candidates = <_RankedOffProduct>[];
    for (var i = 0; i < offWordResponse.products.length; i++) {
      final dto = offWordResponse.products[i];
      if (dto.nutriments == null) continue;
      final meal = MealEntity.fromOFFProduct(dto);
      if (!_keepIfConsistent(meal)) continue;
      final inUserCountry = userCountryTag != null &&
          (dto.countries_tags?.contains(userCountryTag) ?? false);
      candidates.add(
        _RankedOffProduct(meal, dto.popularity_key ?? 0, i, inUserCountry),
      );
    }

    return _fuseRelevanceAndPopularity(candidates);
  }

  /// Re-orders the relevance-ordered candidate pool by reciprocal-rank fusion
  /// of each item's relevance position and its popularity rank, then trims to
  /// [_searchResultLimit]. Items with no popularity_key sort to the bottom of
  /// the popularity dimension, so sparse/never-scanned entries sink.
  List<MealEntity> _fuseRelevanceAndPopularity(
    List<_RankedOffProduct> candidates,
  ) {
    final byPopularity = [...candidates]
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    final popularityRank = <_RankedOffProduct, int>{};
    for (var i = 0; i < byPopularity.length; i++) {
      popularityRank[byPopularity[i]] = i;
    }

    double score(_RankedOffProduct p) {
      final fused = 1 / (_rankFusionK + p.relevanceRank) +
          1 / (_rankFusionK + popularityRank[p]!);
      return p.inUserCountry ? fused * _localCountryBoost : fused;
    }

    // Soft Atwater demotion: products whose declared energy is incoherent with
    // their macros sink below all coherent ones (then by fused score within
    // each group). It is a demotion, not a drop — sparse queries still surface
    // them — but on a full result page they fall off the visible slice.
    int consistencyBucket(_RankedOffProduct p) =>
        isAtwaterConsistent(p.meal.nutriments) ? 0 : 1;

    final ranked = [...candidates]
      ..sort((a, b) {
        final byConsistency =
            consistencyBucket(a).compareTo(consistencyBucket(b));
        if (byConsistency != 0) return byConsistency;
        return score(b).compareTo(score(a));
      });
    return ranked.take(_searchResultLimit).map((p) => p.meal).toList();
  }

  Future<List<MealEntity>> getFDCFoodsByString(String searchString) async {
    final fdcWordResponse = await _fdcDataSource.fetchSearchWordResults(
      searchString,
    );
    final products = fdcWordResponse.foods
        .map((food) => MealEntity.fromFDCFood(food))
        .where(_keepIfConsistent)
        .toList();
    return products;
  }

  Future<List<MealEntity>> getSupabaseFoodsByString(
    String searchString,
  ) async {
    final spWordResponse = await _spBackendDataSource.fetchSearchWordResults(
      searchString,
    );
    final products = spWordResponse
        .map((foodItem) => MealEntity.fromSpFood(foodItem))
        .where(_keepIfConsistent)
        .toList();
    return products;
  }

  Future<MealEntity> getOFFProductByBarcode(String barcode) async {
    final productResponse = await _offDataSource.fetchBarcodeResults(barcode);

    return MealEntity.fromOFFProduct(productResponse.product, detailed: true);
  }

  /// Drops items whose nutriments fail the physical-plausibility rules from
  /// issue #222 (sugar > carbs, saturated fat > total fat, macros summing to
  /// more than 100g per 100g basis). The failure is logged locally and a
  /// Sentry breadcrumb is attached so we can spot whether a particular FDC
  /// id is consistently bad upstream vs. a one-off parse glitch.
  ///
  /// Applied to both the FDC and OFF parse paths: the rules are physics, not
  /// source-specific, and we have seen both corpora carry the occasional
  /// nonsense entry.
  bool _keepIfConsistent(MealEntity meal) {
    final result = validateNutriments(meal.nutriments);
    if (result.isConsistent) return true;

    final reason = result.failureReason ?? 'unknown';
    _log.warning(
      'Dropping ${meal.source.name} item code=${meal.code} '
      'name="${meal.name}" — failed rule: $reason',
    );
    Sentry.addBreadcrumb(Breadcrumb(
      category: 'food_import.validation',
      level: SentryLevel.warning,
      message: 'Dropped corrupt food entry from search results',
      data: {
        'source': meal.source.name,
        'code': meal.code,
        'name': meal.name,
        'rule': reason,
      },
    ));
    return false;
  }
}

/// A search candidate paired with the ranking signals used to fuse a final
/// order: its [popularity] (OFF popularity_key, 0 when absent), its
/// [relevanceRank] (position in the API's relevance-ordered response), and
/// [inUserCountry] (whether it is sold in the user's country, for a soft boost).
class _RankedOffProduct {
  final MealEntity meal;
  final num popularity;
  final int relevanceRank;
  final bool inUserCountry;

  _RankedOffProduct(
    this.meal,
    this.popularity,
    this.relevanceRank,
    this.inUserCountry,
  );
}
