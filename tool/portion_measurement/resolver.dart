// Resolves a query to the food the app lands on, and carries that food's
// portions the way the app carries them — through the read-only RPCs the
// measurement is allowed to call, and through the app's own code wherever
// `dart run` can compile it.
//
// The path is `ResolveParsedMealsUseCase._resolveOne` for one item, with
// Open Food Facts empty and no custom meals, recipes, history or search
// cache (a fresh install, the assumption the 2026-09-12 run made too):
//
//  1. `SpFoodDataSource.fetchSearchWordResults(query, forResolution: true)`
//     — `_searchInLocale`: for a user whose app language has a
//     `food_translation` locale, `search_food_translation(term, loc, 100)`,
//     the rows cut by `rankAndTruncateTranslationRows(rows, term,
//     forResolution: true)`, `food_summary_by_ids` for the survivors, each
//     summary row given its translated description as its shown name and
//     re-sorted onto the cut's order (`_searchByTranslation`); and when the
//     translation search finds nothing, or the language has no locale,
//     `search_food_summary(term, null, 100)` cut by
//     `rankAndTruncateFoodsByName(dtos, term, forResolution: true)`
//     (`_searchEnglish`). Since #1209 the cut reads each row's `has_portion`
//     for the resolver's page: 0.15 off a row the backend says has no
//     portion, and among equal scores and lengths a row with one first.
//  2. `ProductsRepository.getSupabaseFoodsByString` — `MealEntity.fromSpFood`
//     on each row, the nutriment-consistency filter, then one
//     `portions_by_food_ids(ids, loc)` for the whole page, each row's
//     portions built as `MealPortionEntity(label, gramWeight, localized,
//     englishLabel: label_en)` (#1208) and attached with `withPortions`.
//  3. `mergeAndRankMeals(const [], page, query)` — the cross-source dedup
//     and the OFF-only near-duplicate collapse (a backend record is never
//     collapsed, #1170), then a stable sort by `scoreMealRelevance`.
//  4. `rankForResolution(merged, query)` — a stable sort by
//     `scoreMealForResolution`, then the shorter description, then the
//     more portions; index 0 is the food, and its score is the confidence.
//
// What is imported and what is restated. `dart run` compiles
// `soft_text_score.dart` (`scoreText`, `tokenize`, `namedQualifiers`),
// `backend_title.dart` (`deriveTitle`, `deriveQualifiers`),
// `sp_food_dto.dart` (`SpFoodDTO.fromJson`, `displayName`, `hasPortion`),
// `meal_portion_entity.dart` and `sp_const.dart`, and every one of those is
// imported and used as the app uses it. It cannot compile
// `meal_entity.dart` (`hive_ce_flutter` through `meal_dbo.dart`, `dart:ui`
// through `app_locale.dart`), and with it `resolver_relevance.dart`,
// `meal_relevance_ranker.dart`, `meal_nutriments_entity.dart`,
// `sp_food_data_source.dart` (which also reaches `locator`, Supabase and
// Sentry) and `bulk_add_bloc.dart` (`flutter_bloc`) — so the pieces of
// those that the path above runs are restated here, each with the lines it
// restates, and `test/unit_test/portion_measurement_parity_test.dart` pins
// every restatement to the original over the repo's real backend pools.
// The restated pieces are wrappers around the imported scorers: the sort
// comparators, the entity's title derivation, the penalty and the
// tie-breakers, the consistency rules, and the unit and miss decisions.

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/util/backend_title.dart';
import 'package:opennutritracker/features/add_meal/util/soft_text_score.dart';

import 'cli.dart';

/// `SpFoodDataSource._candidatePoolSize` (sp_food_data_source.dart:52), the
/// pool both searches ask the backend for, and `SPConst.maxNumberOfItems`,
/// what the cut keeps.
const candidatePoolSize = SPConst.maxNumberOfItems * 5;
const maxNumberOfItems = SPConst.maxNumberOfItems;

/// `noPortionsPenalty` (resolver_relevance.dart:95): off a backend record
/// with no labelled portion, at the cut (from `has_portion`) and at the
/// resolver (from the fetched list). Restated because the file that
/// declares it imports `meal_entity.dart`; pinned by the parity test.
const noPortionsPenalty = 0.15;

/// `_detailedBonus` and `_machineTranslatedPenalty`
/// (resolver_relevance.dart:31-32; meal_relevance_ranker.dart:45-46 spells
/// the same two numbers inline). A backend record is never `detailed`
/// (`fromSpFood` leaves the default, meal_entity.dart:433-458), so only
/// the penalty can act here.
const machineTranslatedPenalty = 0.03;

/// `kResolutionConfidenceFloor` (resolve_parsed_meals_usecase.dart:25):
/// under it the review screen marks the pick as a guess.
const resolutionConfidenceFloor = 0.45;

/// Which search the record came out of: the English `search_food_summary`
/// (an English line, or a language with no translation locale), the
/// locale's `search_food_translation` (a non-English line the translation
/// search answered), or the English search reached by falling through when
/// the translation search found nothing.
enum ResolvePath { english, translation, englishFallback }

/// A backend row as the resolver scores it: what `MealEntity.fromSpFood`
/// reads off the DTO (meal_entity.dart:433-458) plus what
/// `ProductsRepository._decorate` attaches (products_repository.dart:156-171).
///
/// Only the members the two rankers and the review row read are here.
/// `name` is `SpFoodDTO.displayName` — the translation when there is one,
/// else the full English description (sp_food_dto.dart, `displayName`);
/// `brands` the row's; `machineTranslatedName` is
/// `displayNameIsMachineTranslated`; `source` is `fdc` for every backend
/// row, so `scoringName` and `scoringQualifiers` are `deriveTitle` and
/// `deriveQualifiers` of the name (meal_entity.dart:190-194, 213-217);
/// `servingQuantity` is `servingGramWeight` (meal_entity.dart:446).
class ResolverMeal {
  final SpFoodDTO dto;

  /// The food's portions in the reader's locale, `withPortions(found)` when
  /// the lookup delivered any and empty otherwise.
  final List<MealPortionEntity> portions;

  /// `withPortionsUnavailable()` — set only on a page whose portion lookup
  /// failed. This harness never builds one: a failed lookup is a
  /// [BackendException] and the item is recorded unchecked, because a
  /// page with no portions known cannot be measured for a match.
  final bool portionsUnavailable;

  const ResolverMeal(
    this.dto, {
    this.portions = const [],
    this.portionsUnavailable = false,
  });

  int? get foodId => dto.foodId;
  String? get name => dto.displayName;
  String? get brands => dto.brands;
  bool get machineTranslatedName => dto.displayNameIsMachineTranslated;
  double? get servingQuantity => dto.servingGramWeight;

  /// `MealEntity.scoringName` for a backend record (meal_entity.dart:190-194).
  String? get scoringName {
    final text = name;
    return text == null ? null : deriveTitle(text);
  }

  /// `MealEntity.scoringQualifiers` for a backend record
  /// (meal_entity.dart:213-217).
  String? get scoringQualifiers {
    final text = name;
    return text == null ? null : deriveQualifiers(text);
  }
}

/// The record the resolver put first, and everything the report needs to
/// name it and to say what decided it.
class ResolvedFood {
  final int foodId;
  final String name;
  final String? shortTitle;
  final String source;
  final ResolvePath path;

  /// The `food_translation` locale the search ran in, and the portions
  /// were fetched in; null for English.
  final String? locale;

  /// The translated description the app shows for this record, when it
  /// came through the translation search; the shown name is then this, not
  /// the English description.
  final String? localizedName;

  /// Whether that translation is an unreviewed machine one, which both
  /// rankers dock 0.03 for.
  final bool machineTranslated;

  /// The row's `has_portion` column as `search_food_summary` (English
  /// path) or `food_summary_by_ids` (translation path) sent it — the
  /// backend's own word on whether a portion exists, read by the cut for
  /// the resolver's page (#1209). Null when the backend did not send it.
  final bool? hasPortion;

  /// On the translation path, the `has_portion` of the
  /// `search_food_translation` row the cut actually read; null elsewhere.
  final bool? translationHasPortion;

  /// `scoreMealRelevance` of the record — the shared ranker's score,
  /// which orders the page before the resolver's own sort.
  final double relevance;

  /// `scoreMealForResolution` of the record — what `ResolvedMealItem
  /// .confidence` holds, and what the review screen compares against the
  /// floor.
  final double confidence;

  /// Rows the search returned before the cut to 20: `search_food_summary`'s
  /// on the English path, `search_food_translation`'s on the other.
  final int poolSize;

  /// Rows the resolver ranked: the cut's twenty, less any the consistency
  /// filter dropped.
  final int pageSize;

  /// Rows of the cut the nutriment-consistency filter dropped.
  final int droppedInconsistent;

  /// Rows of the page whose `has_portion` the backend sent as true.
  final int pageFlagged;

  /// Rows of the page the portion lookup delivered at least one row for.
  final int pageWithPortions;

  /// The description of the row the cut put first, when it is not this one
  /// — the difference between "the best-ranked row of the search" and
  /// "what the resolver lands on".
  final String? poolTopName;

  /// How many other rows of the page tied this one on the resolution
  /// score, so that the description's length and then the portion count
  /// decided — the tie-break `_sorted` documents (#1170).
  final int scoreTies;

  /// The food's portions as the app holds them for a reader of [locale]:
  /// the label in that language where a human verified one, the English
  /// `label_en` beside it for a model's key to match against (#1208).
  final List<MealPortionEntity> portions;

  /// `MealEntity.servingQuantity` — the row's `serving_gram_weight`
  /// (meal_entity.dart:446) — which `_initialUnit`'s bare-count rule and
  /// `amountNeedsCheck` read.
  final double? servingQuantity;

  const ResolvedFood({
    required this.foodId,
    required this.name,
    required this.shortTitle,
    required this.source,
    required this.path,
    required this.locale,
    required this.localizedName,
    required this.machineTranslated,
    required this.hasPortion,
    required this.translationHasPortion,
    required this.relevance,
    required this.confidence,
    required this.poolSize,
    required this.pageSize,
    required this.droppedInconsistent,
    required this.pageFlagged,
    required this.pageWithPortions,
    required this.poolTopName,
    required this.scoreTies,
    required this.portions,
    required this.servingQuantity,
  });

  /// What the app's list shows for the record, `SpFoodDTO.displayName`.
  String get shownName => localizedName ?? name;

  /// `ResolvedMealItem.isLowConfidence`.
  bool get lowConfidence => confidence < resolutionConfidenceFloor;

  /// `portionsUnavailable` is never set on a record this harness reports;
  /// see [ResolverMeal.portionsUnavailable].
  bool get portionsUnavailable => false;

  Map<String, Object?> toJson() => {
    'foodId': foodId,
    'name': name,
    'shortTitle': shortTitle,
    'source': source,
    'path': path.name,
    'locale': locale,
    'localizedName': localizedName,
    'machineTranslated': machineTranslated,
    'hasPortion': hasPortion,
    'translationHasPortion': translationHasPortion,
    'relevance': relevance,
    'confidence': confidence,
    'lowConfidence': lowConfidence,
    'poolSize': poolSize,
    'pageSize': pageSize,
    'droppedInconsistent': droppedInconsistent,
    'pageFlagged': pageFlagged,
    'pageWithPortions': pageWithPortions,
    'poolTopName': poolTopName,
    'scoreTies': scoreTies,
    'portionsUnavailable': portionsUnavailable,
    'servingQuantity': servingQuantity,
    'portions': [
      for (final p in portions)
        {
          'label': p.label,
          'englishLabel': p.englishLabel,
          'gramWeight': p.gramWeight,
          'localized': p.localized,
        },
    ],
  };
}

/// The backend could not answer. Carries the function and the kind of
/// failure and nothing else: an `http.ClientException` prints its URI,
/// which here is the project URL, and that must not reach a log or a
/// report. A caller records the item as unchecked and carries on, so one
/// backend blip mid-run does not throw away every provider reply already
/// paid for.
class BackendException implements Exception {
  final String fn;
  final String kind;

  const BackendException(this.fn, this.kind);

  @override
  String toString() => 'backend $fn failed: $kind';
}

/// Caches per locale and query, so a corpus that names the same forty
/// foods a few hundred times makes a few dozen backend calls.
class FoodResolver {
  final http.Client _client;
  final SupabaseAccess _access;

  /// Futures rather than values, so two lanes asking for the same food at
  /// the same moment share one call.
  final _cache = <String, Future<ResolvedFood?>>{};
  var rpcCalls = 0;
  var backendFailures = 0;

  FoodResolver(this._client, this._access);

  int get distinctQueries => _cache.length;

  /// The food [query] lands on for a user whose app language is [locale],
  /// or null when the search returned nothing. The locale is what
  /// `AppLocale.localeName` holds for that user (#1215) — the line's, here
  /// — mapped through `SPConst.translationLocaleOf` as `_foodLocale` maps
  /// it (sp_food_data_source.dart:61-63). Throws [BackendException] when
  /// the backend did not answer; the failed lookup is not cached, so a
  /// later item asking for the same food tries again.
  Future<ResolvedFood?> resolve(String query, {String locale = 'en'}) {
    final term = query.trim();
    if (term.isEmpty) return Future.value(null);
    final loc = SPConst.translationLocaleOf(SupportedLanguage.fromCode(locale));
    final key = '${loc ?? 'en'}|${term.toLowerCase()}';
    final pending = _cache.putIfAbsent(key, () => _resolveUncached(term, loc));
    return pending.catchError((Object e) {
      _cache.remove(key);
      throw e;
    });
  }

  /// `_searchInLocale` (sp_food_data_source.dart:103-135): the translation
  /// search when the language has a locale, its page when it has anything
  /// in it, the English search otherwise.
  Future<ResolvedFood?> _resolveUncached(String query, String? loc) async {
    if (loc != null) {
      final page = await _translationPage(query, loc);
      if (page.dtos.isNotEmpty) {
        return _land(
          page.dtos,
          page.poolSize,
          query,
          ResolvePath.translation,
          loc,
          translationFlags: page.flags,
        );
      }
    }
    final rows = await _rpc(SPConst.searchFoodSummaryFn, {
      'term': query,
      'sources': null,
      'max_rows': candidatePoolSize,
    });
    // `_searchEnglish` (:277-309): the rows as DTOs, then the cut with the
    // flag read.
    final dtos = [for (final row in rows) SpFoodDTO.fromJson(row)];
    return _land(
      cutEnglishPage(dtos, query),
      rows.length,
      query,
      loc == null ? ResolvePath.english : ResolvePath.englishFallback,
      loc,
    );
  }

  /// `_searchByTranslation` (sp_food_data_source.dart:315-390): the two
  /// calls, with the cut and the decoration between them.
  Future<({List<SpFoodDTO> dtos, int poolSize, Map<int, bool?> flags})>
  _translationPage(String query, String loc) async {
    final unrankedRows = await _rpc(SPConst.searchFoodTranslationFn, {
      'term': query,
      'loc': loc,
      'max_rows': candidatePoolSize,
    });
    if (unrankedRows.isEmpty) {
      return (dtos: const <SpFoodDTO>[], poolSize: 0, flags: const <int, bool?>{});
    }
    final translationRows = cutTranslationRows([...unrankedRows], query);
    final ids = translationIds(translationRows);
    final summaryRows = await _rpc(SPConst.foodSummaryByIdsFn, {
      'ids': ids,
      'sources': null,
    });
    return (
      dtos: translationPage(translationRows, summaryRows),
      poolSize: unrankedRows.length,
      flags: <int, bool?>{
        for (final row in translationRows)
          row[SPConst.translationFoodId] as int: translationFlag(row),
      },
    );
  }

  /// Steps 2 to 4 over a page already cut by its search.
  Future<ResolvedFood?> _land(
    List<SpFoodDTO> page,
    int poolSize,
    String query,
    ResolvePath path,
    String? loc, {
    Map<int, bool?> translationFlags = const {},
  }) async {
    // `getSupabaseFoodsByString` (products_repository.dart:115-118): the
    // entities, less the rows whose nutriments fail the plausibility rules.
    final products = page.where(nutrimentsConsistent).toList();
    final droppedInconsistent = page.length - products.length;
    if (products.isEmpty) return null;

    // (:126-136) one portion lookup for the whole page, in the reader's
    // locale — `fetchPortions` passes `'en'` where the language has none
    // (sp_food_data_source.dart:205-216).
    final ids = products.map((p) => p.foodId).nonNulls.toList();
    final byFood = await _portionsByFood(ids, loc ?? 'en');

    // (:138-141, :156-171) `withPortions(found)` where the lookup delivered
    // any; a food missing from the map stays bare.
    final meals = [
      for (final dto in products)
        ResolverMeal(dto, portions: byFood[dto.foodId] ?? const []),
    ];

    final landed = landOn(meals, query);
    if (landed == null) return null;
    final winner = landed.winner;
    final id = winner.foodId;
    if (id == null) return null;

    return ResolvedFood(
      foodId: id,
      name: winner.dto.name ?? '',
      shortTitle: winner.dto.shortTitle,
      source: winner.dto.source ?? '',
      path: path,
      locale: loc,
      localizedName: winner.dto.localizedName,
      machineTranslated: winner.machineTranslatedName,
      hasPortion: winner.dto.hasPortion,
      translationHasPortion: translationFlags[id],
      relevance: landed.relevance,
      confidence: landed.confidence,
      poolSize: poolSize,
      pageSize: meals.length,
      droppedInconsistent: droppedInconsistent,
      pageFlagged: meals.where((m) => m.dto.hasPortion == true).length,
      pageWithPortions: meals.where((m) => m.portions.isNotEmpty).length,
      poolTopName: landed.poolTopName,
      scoreTies: landed.scoreTies,
      portions: winner.portions,
      servingQuantity: winner.servingQuantity,
    );
  }

  /// `SpFoodDataSource.fetchPortions` (sp_food_data_source.dart:199-247):
  /// `portions_by_food_ids(ids, loc)`, each usable row a
  /// `MealPortionEntity` with the English `label_en` beside the coalesced
  /// label, grouped by food in the backend's order. Where the app answers
  /// null — the lookup failed — this throws, and the caller records the
  /// item as unchecked rather than ranking a page it cannot measure.
  Future<Map<int, List<MealPortionEntity>>> _portionsByFood(
    List<int> foodIds,
    String loc,
  ) async {
    if (foodIds.isEmpty) return const {};
    final rows = await _rpc(SPConst.portionsByFoodIdsFn, {
      'ids': foodIds,
      'loc': loc,
    });
    final byFood = <int, List<MealPortionEntity>>{};
    for (final row in rows) {
      final id = row['food_id'];
      final label = row['label'];
      final grams = row['gram_weight'];
      if (id is! int || label is! String || grams == null) continue;
      final weight = grams is num ? grams.toDouble() : null;
      if (weight == null || weight <= 0) continue;
      final englishLabel = row['label_en'];
      final portion = MealPortionEntity(
        label: label,
        gramWeight: weight,
        localized: row['localized'] == true,
        englishLabel: englishLabel is String && englishLabel.isNotEmpty
            ? englishLabel
            : null,
      );
      byFood.putIfAbsent(id, () => []).add(portion);
    }
    return byFood;
  }

  /// One PostgREST RPC: a POST with the parameters as the JSON body, so the
  /// search term never enters a URL (#882). Every way the call can fail is
  /// turned into a [BackendException] naming the function and the kind of
  /// failure, because the `http` exceptions carry the URI in their message.
  Future<List<Map<String, dynamic>>> _rpc(
    String fn,
    Map<String, Object?> params,
  ) async {
    rpcCalls++;
    final anon = _access.anonKey();
    final http.Response response;
    try {
      response = await _client.post(
        _access.projectUrl.replace(path: '/rest/v1/rpc/$fn'),
        headers: {
          'apikey': anon,
          'Authorization': 'Bearer $anon',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(params),
      );
    } on http.ClientException {
      backendFailures++;
      throw BackendException(fn, 'unreachable (ClientException)');
    } on IOException {
      backendFailures++;
      throw BackendException(fn, 'unreachable (IOException)');
    }
    if (response.statusCode != 200) {
      backendFailures++;
      throw BackendException(fn, 'HTTP ${response.statusCode}');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      backendFailures++;
      throw BackendException(fn, 'body is not JSON');
    }
    if (decoded is! List) {
      backendFailures++;
      throw BackendException(fn, 'body is not a list of rows');
    }
    return decoded.cast<Map<String, dynamic>>();
  }
}

// --- the cut: sp_food_data_source.dart:497-617 -----------------------------

/// `rankAndTruncateFoodsByName(foods, searchString, forResolution: true)`
/// (sp_food_data_source.dart:497-507): the full `name` described, the
/// DTO's `hasPortion` read.
List<SpFoodDTO> cutEnglishPage(List<SpFoodDTO> foods, String searchString) =>
    rankAndTruncate(
      foods,
      searchString,
      describe: (food) => food.name,
      hasPortion: (food) => food.hasPortion,
    );

/// `rankAndTruncateTranslationRows(rows, searchString, forResolution: true)`
/// (sp_food_data_source.dart:523-538): the translated description
/// described, the row's `has_portion` read where it is a boolean and null
/// otherwise.
List<Map<String, dynamic>> cutTranslationRows(
  List<Map<String, dynamic>> rows,
  String searchString,
) => rankAndTruncate(
  rows,
  searchString,
  describe: (row) => row[SPConst.translationDescription] as String?,
  hasPortion: translationFlag,
);

/// The flag reader of the translation cut (sp_food_data_source.dart:533-536).
bool? translationFlag(Map<String, dynamic> row) {
  final flag = row[SPConst.translationHasPortion];
  return flag is bool ? flag : null;
}

/// `_rankAndTruncate` (sp_food_data_source.dart:571-597), verbatim apart
/// from the name: score descending, then the shorter description, then
/// the row with a portion, `mergeSort` for the stability, the first twenty.
List<T> rankAndTruncate<T>(
  List<T> items,
  String searchString, {
  required String? Function(T item) describe,
  required bool? Function(T item) hasPortion,
}) {
  final queryTokens = tokenize(searchString);
  final decorated = [
    for (final item in items)
      (
        item: item,
        score: backendScore(describe(item), queryTokens, hasPortion(item)),
        length: describe(item)?.length ?? 0,
        portioned: hasPortion(item) == true ? 1 : 0,
      ),
  ];
  mergeSort(decorated, compare: (a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byLength = a.length.compareTo(b.length);
    if (byLength != 0) return byLength;
    return b.portioned.compareTo(a.portioned);
  });
  return [for (final entry in decorated.take(maxNumberOfItems)) entry.item];
}

/// `_backendScore` (sp_food_data_source.dart:604-617): `scoreText` of the
/// derived title with the derived qualifiers, less the penalty when the
/// backend said there is no portion, clamped.
double backendScore(
  String? description,
  Set<String> queryTokens,
  bool? hasPortion,
) {
  if (description == null) return 0.0;
  final score = scoreText(
    deriveTitle(description),
    queryTokens,
    qualifiers: deriveQualifiers(description),
  );
  if (hasPortion == false) return (score - noPortionsPenalty).clamp(0.0, 1.0);
  return score;
}

// --- the translation page: sp_food_data_source.dart:342-389 ----------------

/// The food ids `_searchByTranslation` asks `food_summary_by_ids` for, in
/// the order it asks: the distinct ids of the cut rows, first position
/// kept (:342-346, :368-371).
List<int> translationIds(List<Map<String, dynamic>> translationRows) =>
    _decorate(translationRows).nameByFoodId.keys.toList();

/// The page `_searchByTranslation` returns for [summaryRows] fetched by
/// [translationIds]: each summary row as a DTO with the translated
/// description as its `localizedName` and the machine flag of its
/// translation, re-sorted onto the cut's order — a row whose id the cut
/// did not name sorts last (:376-389). Empty when the summary fetch
/// returned nothing, which is when the app falls through to English.
List<SpFoodDTO> translationPage(
  List<Map<String, dynamic>> translationRows,
  List<Map<String, dynamic>> summaryRows,
) {
  final d = _decorate(translationRows);
  final rankByFoodId = {
    for (final (rank, foodId) in d.nameByFoodId.keys.indexed) foodId: rank,
  };
  final foods = summaryRows.map((food) {
    final dto = SpFoodDTO.fromJson(food);
    dto.localizedName = d.nameByFoodId[dto.foodId];
    dto.localizedNameIsMachineTranslated = d.machineIds.contains(dto.foodId);
    return dto;
  }).toList();
  mergeSort(
    foods,
    compare: (a, b) => (rankByFoodId[a.foodId] ?? rankByFoodId.length)
        .compareTo(rankByFoodId[b.foodId] ?? rankByFoodId.length),
  );
  return foods;
}

/// The two maps `_searchByTranslation` builds from the cut rows (:342-351),
/// with the map literal's semantics kept: a food id named twice keeps its
/// first position and its last description, and is machine-translated if
/// any of its rows is.
({Map<int, String?> nameByFoodId, Set<int> machineIds}) _decorate(
  List<Map<String, dynamic>> translationRows,
) {
  final nameByFoodId = <int, String?>{};
  final machineIds = <int>{};
  for (final row in translationRows) {
    final id = row[SPConst.translationFoodId] as int;
    nameByFoodId[id] = row[SPConst.translationDescription] as String?;
    if (row[SPConst.translationSource] == SPConst.translationSourceMachine) {
      machineIds.add(id);
    }
  }
  return (nameByFoodId: nameByFoodId, machineIds: machineIds);
}

// --- the consistency filter: meal_nutriments_entity.dart:342-388 -----------

/// `_nutrimentsValidationToleranceG` (meal_nutriments_entity.dart:342).
const _nutrimentsValidationToleranceG = 1.0;

/// `validateNutriments(...).isConsistent` over the entity
/// `MealNutrimentsEntity.fromSpFoodSummary` builds from the row
/// (meal_nutriments_entity.dart:227-254, 364-388), as
/// `ProductsRepository._keepIfConsistent` applies it (products_repository
/// .dart:188-209): sugars within carbs, saturated within total fat, the
/// three macros within 100 g, each with a gram of slack; a null on either
/// side skips the rule.
bool nutrimentsConsistent(SpFoodDTO food) {
  final sugars = food.sugars100;
  final carbs = food.carbohydrates100;
  if (sugars != null &&
      carbs != null &&
      sugars > carbs + _nutrimentsValidationToleranceG) {
    return false;
  }
  final satFat = food.saturatedFat100;
  final fat = food.fat100;
  if (satFat != null &&
      fat != null &&
      satFat > fat + _nutrimentsValidationToleranceG) {
    return false;
  }
  final protein = food.proteins100;
  final macroSum = (carbs ?? 0) + (fat ?? 0) + (protein ?? 0);
  return macroSum <= 100 + _nutrimentsValidationToleranceG;
}

// --- the rankers -------------------------------------------------------------

/// What [landOn] lands on.
typedef Landing = ({
  ResolverMeal winner,
  double relevance,
  double confidence,
  String? poolTopName,
  int scoreTies,
});

/// Steps 3 and 4 over a page in the order its search left it: what
/// `mergeAndRankMeals` and `rankForResolution` do to it, as
/// `ResolveParsedMealsUseCase._resolveOne` calls them
/// (resolve_parsed_meals_usecase.dart:133-155) — or null for an empty page.
Landing? landOn(List<ResolverMeal> page, String query) {
  if (page.isEmpty) return null;
  final poolTop = page.first;
  final ranked = rankForResolution(mergeAndRank(page, query), query);
  final winner = ranked.first;
  final winnerScore = resolutionScore(winner, query);
  return (
    winner: winner,
    relevance: relevanceScore(winner, query),
    confidence: winnerScore,
    poolTopName: identical(winner, poolTop) ? null : poolTop.name,
    scoreTies: ranked
        .skip(1)
        .where((m) => resolutionScore(m, query) == winnerScore)
        .length,
  );
}

/// `mergeAndRankMeals(const [], page, query)` for a page of backend
/// records (meal_relevance_ranker.dart:89-98): `_deduplicateAcrossSources`
/// keys a backend record on `fdc:<code>` (:114-124), so a food id listed
/// twice keeps its first entry; `_collapseNearDuplicates` keys anything
/// that is not an OFF product on its own identity (:165-175), so no
/// backend record is ever collapsed; nothing is the user's own; and what
/// is left is `rankMealsByRelevance` — a stable sort by
/// [relevanceScore], highest first (:61-65).
List<ResolverMeal> mergeAndRank(List<ResolverMeal> page, String query) {
  final seen = <String>{};
  final unique = <ResolverMeal>[];
  for (final meal in page) {
    final key = 'fdc:${meal.foodId?.toString() ?? identityHashCode(meal)}';
    if (seen.add(key)) unique.add(meal);
  }
  final decorated = [
    for (final meal in unique) (meal: meal, score: relevanceScore(meal, query)),
  ];
  mergeSort(decorated, compare: (a, b) => b.score.compareTo(a.score));
  return [for (final entry in decorated) entry.meal];
}

/// `rankForResolution` (resolver_relevance.dart:161-171) over a page with
/// no own-content tier, which is `_sorted` (:265-287): highest
/// [resolutionScore] first; among equal scores the shorter `name` — the
/// description, not the title that was scored; then the more portions;
/// stable after that, so what is left of a tie keeps the shared ranker's
/// order.
List<ResolverMeal> rankForResolution(List<ResolverMeal> meals, String query) {
  final decorated = [
    for (final meal in meals) (meal: meal, score: resolutionScore(meal, query)),
  ];
  mergeSort(decorated, compare: (a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byLength = (a.meal.name ?? '').length.compareTo(
      (b.meal.name ?? '').length,
    );
    if (byLength != 0) return byLength;
    return b.meal.portions.length.compareTo(a.meal.portions.length);
  });
  return [for (final entry in decorated) entry.meal];
}

/// `scoreMealForResolution` (resolver_relevance.dart:119-150) for a
/// backend record: `scoreText` — the app's own, imported — of the title
/// with the qualifiers the query names, or the brand's at 60% where that
/// is higher; no `detailed` bonus, which a backend record never has; the
/// machine-translation penalty; and [noPortionsPenalty] when the record is
/// a backend one (every record here is) with no portions and the lookup
/// did not fail; clamped.
double resolutionScore(ResolverMeal meal, String query) {
  final queryTokens = tokenize(query);
  if (queryTokens.isEmpty) return 0.0;

  final nameScore = scoreText(
    meal.scoringName,
    queryTokens,
    qualifiers: meal.scoringQualifiers,
  );
  final brandScore = scoreText(meal.brands, queryTokens);
  var score = nameScore >= brandScore ? nameScore : brandScore * 0.6;

  if (meal.machineTranslatedName) score -= machineTranslatedPenalty;
  if (meal.portions.isEmpty && !meal.portionsUnavailable) {
    score -= noPortionsPenalty;
  }
  return score.clamp(0.0, 1.0);
}

/// `scoreMealRelevance` (meal_relevance_ranker.dart:29-49) for a backend
/// record: the exact-token score of the title plus the qualifiers the
/// query names by exact token, or the brand's at 60%; no `detailed`
/// bonus; the machine-translation penalty; clamped. The scorer it calls
/// is private to that file and restated below.
double relevanceScore(ResolverMeal meal, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return 0.0;

  final nameScore = _textScore(
    meal.scoringName,
    normalizedQuery,
    qualifiers: meal.scoringQualifiers,
  );
  final brandScore = _textScore(meal.brands, normalizedQuery);
  var score = nameScore >= brandScore ? nameScore : brandScore * 0.6;

  if (meal.machineTranslatedName) score -= machineTranslatedPenalty;

  return score.clamp(0.0, 1.0);
}

/// `_textScore` (meal_relevance_ranker.dart:204-233): the Dice of the
/// tokens, the qualifier tokens the query contains joined to the text's,
/// the contains and prefix bonuses on the text alone, capped at 0.9 for
/// anything but an exact match.
double _textScore(String? text, String normalizedQuery, {String? qualifiers}) {
  final normalizedText = _normalize(text);
  if (normalizedText.isEmpty) return 0.0;
  if (normalizedText == normalizedQuery) return 1.0;

  final queryTokens = _tokenize(normalizedQuery);
  final textTokens = {
    ..._tokenize(normalizedText),
    ..._tokenize(_normalize(qualifiers)).intersection(queryTokens),
  };
  final overlap = _diceCoefficient(textTokens, queryTokens);

  final containsBonus = normalizedText.contains(normalizedQuery) ? 0.2 : 0.0;
  final prefixBonus = normalizedText.startsWith(normalizedQuery) ? 0.15 : 0.0;

  return (overlap + containsBonus + prefixBonus).clamp(0.0, 0.9);
}

/// (meal_relevance_ranker.dart:235-247)
String _normalize(String? text) =>
    text?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ?? '';

Set<String> _tokenize(String normalizedText) => normalizedText
    .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
    .where((token) => token.isNotEmpty)
    .toSet();

double _diceCoefficient(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  final intersectionSize = a.intersection(b).length;
  return 2 * intersectionSize / (a.length + b.length);
}
