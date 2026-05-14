import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ProductsRepository {
  static final _log = Logger('ProductsRepository');

  final OFFDataSource _offDataSource;
  final FDCDataSource _fdcDataSource;
  final SpFdcDataSource _spBackendDataSource;

  ProductsRepository(
    this._offDataSource,
    this._fdcDataSource,
    this._spBackendDataSource,
  );

  Future<List<MealEntity>> getOFFProductsByString(String searchString) async {
    final offWordResponse = await _offDataSource.fetchSearchWordResults(
      searchString,
    );

    final products = offWordResponse.products
        .where((offProduct) => offProduct.nutriments != null)
        .map((offProduct) => MealEntity.fromOFFProduct(offProduct))
        .where(_keepIfConsistent)
        .toList();

    return products;
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

  Future<List<MealEntity>> getSupabaseFDCFoodsByString(
    String searchString,
  ) async {
    final spFdcWordResponse = await _spBackendDataSource.fetchSearchWordResults(
      searchString,
    );
    final products = spFdcWordResponse
        .map((foodItem) => MealEntity.fromSpFDCFood(foodItem))
        .where(_keepIfConsistent)
        .toList();
    return products;
  }

  Future<MealEntity> getOFFProductByBarcode(String barcode) async {
    final productResponse = await _offDataSource.fetchBarcodeResults(barcode);

    return MealEntity.fromOFFProduct(productResponse.product);
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
