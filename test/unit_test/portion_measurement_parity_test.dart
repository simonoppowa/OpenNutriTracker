// The #1160 harnesses under `tool/portion_measurement/` run with `dart run`,
// which cannot compile the Flutter imports `meal_entity.dart` and
// `ai_credential_storage.dart` drag in — so they carry copies of the three
// scorers, a replay of the AI path's ranking on both of the data source's
// search paths, and the default model ids. This test is the only thing
// that keeps a copy honest: change the original and the harness measures
// against the wrong ranking or the wrong model.
//
// Four things are pinned. The scalar scorers, on names with and without a
// brand, translated by a machine or not. The facts the replay assumes
// about a backend food — the shown name (the translation when there is
// one), the brand, `detailed` false, machine translation only when a
// machine translation is what is shown. The English replay, run beside the
// app's own pipeline over a pool wider than the truncation, with rows that
// share a shown name, rows that share it and a brand, brand-only matches,
// and exact score ties — so the top-20 cut, the collapse key, the
// strict-greater tie rule and the shown-name rule are each the app's, not
// a reading of them. And the translation replay: the ids it asks for and
// the page it builds against `rankAndTruncateTranslationRows` with the
// summary rows in every order, and where it lands against the app's
// rankers over the page `_searchByTranslation` would hand them.

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart'
    as app;
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart'
    as app;

import '../../tool/portion_measurement/providers.dart' as tool;
import '../../tool/portion_measurement/resolver.dart' as tool;

MealEntity _backendFood(
  String name, {
  String? brands,
  bool machineTranslated = false,
}) => MealEntity(
  code: name,
  name: name,
  brands: brands,
  url: null,
  mealQuantity: null,
  mealUnit: null,
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  source: MealSourceEntity.fdc,
  backendSource: 'fdc_survey',
  nutriments: MealNutrimentsEntity.empty(),
  machineTranslatedName: machineTranslated,
);

const _pairs = <(String?, String)>[
  ('Banana, raw', 'banana'),
  ('Banana split', 'banana'),
  ('Banana', 'banana'),
  ('Bread, white', 'white bread'),
  ('White bread/wheat bread', 'white bread'),
  ('Chicken breast, rotisserie, skin eaten', 'chicken breast'),
  ('Milk & hazelnut', 'milk'),
  ('Salmon salad', 'salad'),
  ('Lettuce, raw', 'salad'),
  ('意大利面', '意大利面'),
  ('Spaghetti', '意大利面'),
  ('', 'egg'),
  (null, 'egg'),
  ('Egg, creamed', ''),
  ('  Egg,   whole, raw  ', 'EGG'),
];

/// Name, brand, query — the brand paths of both scorers.
const _branded = <(String, String?, String)>[
  ('Whole milk', 'Horizon', 'milk'),
  ('Cereal bar', 'Milka', 'milk'),
  ('Cereal bar', 'milk', 'milk'),
  ('Chocolate', 'Milk Chocolate Co', 'milk chocolate'),
  ('', 'Nestle', 'nestle'),
  ('Yogurt', '', 'yogurt'),
  ('Yogurt', null, 'yogurt'),
];

/// A `search_food_summary` row as the RPC returns it, the fields the replay
/// and the DTO both read.
Map<String, dynamic> _row(
  int id,
  String name, {
  String? shortTitle,
  String? brands,
}) => {
  'food_id': id,
  'source': 'fdc_survey',
  'source_code': '$id',
  'name': name,
  'short_title': shortTitle,
  'brands': brands,
};

/// The app's own pipeline over the same rows: `_searchEnglish`'s ranking
/// and truncation, `fromSpFood`, `mergeAndRankMeals` with OFF empty, then
/// `rankForResolution` — index 0 is what the resolver logs.
int _appWinner(List<Map<String, dynamic>> rows, String query) {
  final dtos = [for (final r in rows) SpFoodDTO.fromJson(r)];
  final top = rankAndTruncateFoodsByName(dtos, query);
  final meals = [for (final f in top) MealEntity.fromSpFood(f)];
  final merged = app.mergeAndRankMeals(const [], meals, query);
  final ranked = app.rankForResolution(merged, query);
  return int.parse(ranked.first.code!);
}

/// A pool wider than the truncation with every case the collapse has a
/// rule for: exact-tie siblings, shared shown names across different full
/// names, a branded and an unbranded copy, two copies of one brand, a
/// brand-only hit, and a short title that differs from the name.
List<Map<String, dynamic>> _pool() => [
  _row(1, 'Milk, whole', shortTitle: 'Milk'),
  _row(2, 'Milk, 2% fat', shortTitle: 'Milk'),
  _row(3, 'Milk, skim', shortTitle: 'Milk'),
  _row(4, 'Milk, whole', shortTitle: 'Milk', brands: 'Horizon'),
  _row(5, 'Milk, whole', shortTitle: 'Milk', brands: 'Horizon'),
  _row(6, 'Milk, whole', shortTitle: 'Milk', brands: 'Organic Valley'),
  _row(7, 'Milk & hazelnut spread'),
  _row(8, 'Milk chocolate', brands: 'Milka'),
  _row(9, 'Cereal bar', brands: 'Milk Co'),
  _row(10, 'Milk'),
  _row(11, 'Milk'),
  _row(12, 'Milk, goat'),
  _row(13, 'Milk, sheep'),
  _row(14, 'Milk, buffalo'),
  _row(15, 'Milk, human'),
  _row(16, 'Milk, evaporated'),
  _row(17, 'Milk, condensed', shortTitle: 'Condensed milk'),
  _row(18, 'Milk, dry'),
  _row(19, 'Milk, chocolate'),
  _row(20, 'Milk, strawberry'),
  _row(21, 'Milk, lactose free'),
  _row(22, 'Milk, almond'),
  _row(23, 'Milk, oat'),
  _row(24, 'Milk, soy'),
  _row(25, 'Milk shake'),
  _row(26, 'Milkfish'),
  _row(27, 'Buttermilk'),
  _row(28, 'Egg, whole, raw', shortTitle: 'Egg'),
  _row(29, 'Egg, whole, cooked', shortTitle: 'Egg'),
  _row(30, 'Eggs Benedict'),
  _row(31, 'Egg roll'),
  _row(32, 'Bread, white', shortTitle: 'White bread'),
  _row(33, 'Bread, white, toasted', shortTitle: 'White bread'),
  _row(34, 'Bread, wheat', shortTitle: 'Wheat bread'),
  _row(35, 'Bread, white', brands: 'Wonder'),
  _row(36, ''),
  _row(37, ''),
];

/// A `search_food_translation` row as the RPC returns it.
Map<String, dynamic> _translation(
  int foodId,
  String description, {
  String source = 'verified',
}) => {
  SPConst.translationFoodId: foodId,
  SPConst.translationLocale: 'de',
  SPConst.translationDescription: description,
  SPConst.translationSource: source,
};

/// The page `_searchByTranslation` would hand `fromSpFood` for these rows,
/// as DTOs. `rankAndTruncateTranslationRows` is the app's own; the
/// decoration and re-sort after it are restated here from
/// `sp_food_data_source.dart` (the map of ids to descriptions, the machine
/// set, the rank map, the stable sort onto it), because the method is
/// private and needs a `SupabaseClient`. Restated, not imported: change
/// that method and this fixture has to change with it.
List<SpFoodDTO> _appTranslationPage(
  List<Map<String, dynamic>> translationRows,
  List<Map<String, dynamic>> summaryRows,
  String query,
) {
  final ranked = rankAndTruncateTranslationRows([...translationRows], query);
  final nameByFoodId = {
    for (final row in ranked)
      row[SPConst.translationFoodId] as int:
          row[SPConst.translationDescription] as String?,
  };
  final machine = {
    for (final row in ranked)
      if (row[SPConst.translationSource] == SPConst.translationSourceMachine)
        row[SPConst.translationFoodId] as int,
  };
  final rankByFoodId = {
    for (final (rank, foodId) in nameByFoodId.keys.indexed) foodId: rank,
  };
  final foods = summaryRows.map((food) {
    final dto = SpFoodDTO.fromJson(food);
    dto.localizedName = nameByFoodId[dto.foodId];
    dto.localizedNameIsMachineTranslated = machine.contains(dto.foodId);
    return dto;
  }).toList();
  mergeSort(
    foods,
    compare: (a, b) => (rankByFoodId[a.foodId] ?? rankByFoodId.length)
        .compareTo(rankByFoodId[b.foodId] ?? rankByFoodId.length),
  );
  return foods;
}

/// The app's own pipeline from that page on: `fromSpFood`,
/// `mergeAndRankMeals` with OFF empty, then `rankForResolution`.
int _appWinnerLocalized(
  List<Map<String, dynamic>> translationRows,
  List<Map<String, dynamic>> summaryRows,
  String query,
) {
  final page = _appTranslationPage(translationRows, summaryRows, query);
  final meals = [for (final f in page) MealEntity.fromSpFood(f)];
  final merged = app.mergeAndRankMeals(const [], meals, query);
  final ranked = app.rankForResolution(merged, query);
  return int.parse(ranked.first.code!);
}

/// Translation rows wider than the cut, with every case the re-sort and
/// the rankers have a rule for: exact-tie siblings, a machine translation
/// that would win on text alone, two translations of one food (the map
/// keeps the first position and the last description), foods whose
/// translations collapse to one shown name, a translation that differs
/// from the English short title, and rows the cut drops.
List<Map<String, dynamic>> _translations() => [
  _translation(1, 'Milch, Vollmilch'),
  _translation(2, 'Milch, 2% Fett'),
  _translation(3, 'Milch, entrahmt'),
  _translation(4, 'Milch', source: 'machine'),
  _translation(5, 'Milch'),
  _translation(6, 'Milch', source: 'machine'),
  _translation(7, 'Milch & Haselnuss-Aufstrich'),
  _translation(8, 'Vollmilchschokolade'),
  _translation(9, 'Müsliriegel'),
  _translation(10, 'Milch'),
  _translation(10, 'Milch, pasteurisiert'),
  _translation(11, 'Ziegenmilch'),
  _translation(12, 'Schafmilch'),
  _translation(13, 'Büffelmilch'),
  _translation(14, 'Muttermilch'),
  _translation(15, 'Kondensmilch'),
  _translation(16, 'Milchpulver'),
  _translation(17, 'Milch, Schokolade'),
  _translation(18, 'Milch, Erdbeer'),
  _translation(19, 'Milch, laktosefrei'),
  _translation(20, 'Mandelmilch'),
  _translation(21, 'Hafermilch'),
  _translation(22, 'Sojamilch'),
  _translation(23, 'Milchshake'),
  _translation(24, 'Buttermilch'),
  _translation(25, 'Ei, ganz, roh'),
  _translation(26, 'Ei, ganz, gekocht'),
  _translation(27, 'Brot, Weizen'),
  _translation(28, 'Brot, Vollkorn'),
  _translation(29, 'Toast'),
];

/// The `food_summary_by_ids` rows for those ids, in an order that is not
/// the translation order — a WHERE-IN fetch promises none.
List<Map<String, dynamic>> _summaries() => [
  _row(29, 'Bread, white, toasted', shortTitle: 'Toast'),
  _row(4, 'Milk, whole, 3.25% milkfat', shortTitle: 'Milk'),
  _row(10, 'Milk, pasteurized', shortTitle: 'Milk'),
  _row(1, 'Milk, whole', shortTitle: 'Milk'),
  _row(6, 'Milk, whole', shortTitle: 'Milk', brands: 'Horizon'),
  _row(5, 'Milk, reduced fat', shortTitle: 'Milk'),
  _row(2, 'Milk, 2% fat', shortTitle: 'Milk'),
  _row(3, 'Milk, skim', shortTitle: 'Milk'),
  _row(7, 'Milk & hazelnut spread'),
  _row(8, 'Milk chocolate', brands: 'Milka'),
  _row(9, 'Cereal bar', brands: 'Milk Co'),
  _row(11, 'Milk, goat'),
  _row(12, 'Milk, sheep'),
  _row(13, 'Milk, buffalo'),
  _row(14, 'Milk, human'),
  _row(15, 'Milk, condensed', shortTitle: 'Condensed milk'),
  _row(16, 'Milk, dry'),
  _row(17, 'Milk, chocolate'),
  _row(18, 'Milk, strawberry'),
  _row(19, 'Milk, lactose free'),
  _row(20, 'Milk, almond'),
  _row(21, 'Milk, oat'),
  _row(22, 'Milk, soy'),
  _row(23, 'Milk shake'),
  _row(24, 'Buttermilk'),
  _row(25, 'Egg, whole, raw', shortTitle: 'Egg'),
  _row(26, 'Egg, whole, cooked', shortTitle: 'Egg'),
  _row(27, 'Bread, wheat', shortTitle: 'Wheat bread'),
  _row(28, 'Bread, whole wheat', shortTitle: 'Whole wheat bread'),
];

void main() {
  group('the copied scorers agree with the app', () {
    test('textRelevanceScore', () {
      for (final (text, query) in _pairs) {
        expect(
          tool.textRelevanceScore(text, query),
          app.textRelevanceScore(text, query),
          reason: '"$text" against "$query"',
        );
      }
    });

    test('scoreMealRelevance on a backend food', () {
      for (final (text, query) in _pairs) {
        if (text == null) continue;
        expect(
          tool.scoreMealRelevance(text, query),
          app.scoreMealRelevance(_backendFood(text), query),
          reason: '"$text" against "$query"',
        );
      }
      for (final (name, brand, query) in _branded) {
        expect(
          tool.scoreMealRelevance(name, query, brand: brand),
          app.scoreMealRelevance(_backendFood(name, brands: brand), query),
          reason: '"$name" / "$brand" against "$query"',
        );
      }
    });

    test('both scorers on a machine-translated backend food', () {
      for (final (text, query) in _pairs) {
        if (text == null) continue;
        expect(
          tool.scoreMealRelevance(text, query, machineTranslated: true),
          app.scoreMealRelevance(
            _backendFood(text, machineTranslated: true),
            query,
          ),
          reason: 'relevance of "$text" against "$query"',
        );
        expect(
          tool.resolutionScore(text, query, machineTranslated: true),
          app.scoreMealForResolution(
            _backendFood(text, machineTranslated: true),
            query,
          ),
          reason: 'resolution of "$text" against "$query"',
        );
      }
      for (final (name, brand, query) in _branded) {
        expect(
          tool.scoreMealRelevance(name, query, brand: brand, machineTranslated: true),
          app.scoreMealRelevance(
            _backendFood(name, brands: brand, machineTranslated: true),
            query,
          ),
          reason: 'relevance of "$name" / "$brand" against "$query"',
        );
        expect(
          tool.resolutionScore(name, query, brand: brand, machineTranslated: true),
          app.scoreMealForResolution(
            _backendFood(name, brands: brand, machineTranslated: true),
            query,
          ),
          reason: 'resolution of "$name" / "$brand" against "$query"',
        );
      }
    });

    test('scoreMealForResolution on a backend food', () {
      for (final (text, query) in _pairs) {
        if (text == null) continue;
        expect(
          tool.resolutionScore(text, query),
          app.scoreMealForResolution(_backendFood(text), query),
          reason: '"$text" against "$query"',
        );
      }
      for (final (name, brand, query) in _branded) {
        expect(
          tool.resolutionScore(name, query, brand: brand),
          app.scoreMealForResolution(_backendFood(name, brands: brand), query),
          reason: '"$name" / "$brand" against "$query"',
        );
      }
    });
  });

  group('what the replay assumes about a backend food', () {
    test('fromSpFood: shown name, brand, no detailed bonus, not translated', () {
      final withTitle = MealEntity.fromSpFood(
        SpFoodDTO.fromJson(_row(1, 'Milk, whole', shortTitle: 'Milk', brands: 'Horizon')),
      );
      expect(withTitle.name, 'Milk');
      expect(withTitle.brands, 'Horizon');
      expect(withTitle.detailed, isFalse);
      expect(withTitle.machineTranslatedName, isFalse);
      expect(withTitle.code, '1');

      final withoutTitle = MealEntity.fromSpFood(
        SpFoodDTO.fromJson(_row(2, 'Milk, 2% fat')),
      );
      expect(withoutTitle.name, 'Milk, 2% fat');
      expect(withoutTitle.brands, isNull);
    });

    test('fromSpFood with a translation: it is the shown name, and the '
        'machine flag counts only when it is shown', () {
      final dto = SpFoodDTO.fromJson(
        _row(1, 'Milk, whole', shortTitle: 'Milk', brands: 'Horizon'),
      );
      dto.localizedName = 'Vollmilch';
      dto.localizedNameIsMachineTranslated = true;
      final translated = MealEntity.fromSpFood(dto);
      expect(translated.name, 'Vollmilch');
      expect(translated.brands, 'Horizon');
      expect(translated.machineTranslatedName, isTrue);
      expect(translated.detailed, isFalse);
      expect(
        tool.shownName((row: _row(1, 'Milk, whole', shortTitle: 'Milk'), localizedName: 'Vollmilch', machineTranslated: true)),
        translated.name,
      );

      // A machine flag with no translation shown is nothing.
      final flagOnly = SpFoodDTO.fromJson(_row(2, 'Milk, 2% fat'));
      flagOnly.localizedNameIsMachineTranslated = true;
      expect(MealEntity.fromSpFood(flagOnly).machineTranslatedName, isFalse);
      expect(MealEntity.fromSpFood(flagOnly).name, 'Milk, 2% fat');
    });

    test('the candidate pool and the cut are the data source\'s', () {
      expect(tool.candidatePoolSize, 100);
      expect(tool.maxNumberOfItems, 20);
    });
  });

  group('the replay lands where the app lands', () {
    const queries = [
      'milk',
      'whole milk',
      'milk whole',
      'Milk',
      'horizon',
      // The brand in the collapse key decides these: the exact-token
      // ranker scores `horizons` against *Horizon* at 0, so a branded copy
      // merged into the unbranded group is dropped there, while the
      // resolver's soft Dice would have put it first.
      'horizons',
      'wonders',
      'milka',
      'milk co',
      'egg',
      'eggs',
      'white bread',
      'bread',
      'toast',
      'condensed',
      'buttermilk',
      'goat milk',
      'milkfish',
      'hazelnut',
      'zzz',
    ];

    test('on the same pool, query by query', () {
      final rows = _pool();
      for (final query in queries) {
        final replay = tool.aiPathWinner(rows, query);
        expect(replay, isNotNull, reason: query);
        expect(
          replay!.candidate.row['food_id'],
          _appWinner(rows, query),
          reason: 'query "$query"',
        );
      }
    });

    test('and in every rotation of the pool, so row order is the app\'s', () {
      final base = _pool();
      for (var shift = 0; shift < base.length; shift += 5) {
        final rows = [...base.skip(shift), ...base.take(shift)];
        for (final query in queries) {
          expect(
            tool.aiPathWinner(rows, query)!.candidate.row['food_id'],
            _appWinner(rows, query),
            reason: 'query "$query", pool rotated by $shift',
          );
        }
      }
    });

    test('an empty pool is nothing', () {
      expect(tool.aiPathWinner(const [], 'milk'), isNull);
    });
  });

  group('the translation replay builds the page the app builds', () {
    const queries = [
      'Milch',
      'milch',
      'Vollmilch',
      'Milch Vollmilch',
      'Ziegenmilch',
      'Buttermilch',
      'Haselnuss',
      'Ei',
      'Eier',
      'Brot',
      'Vollkornbrot',
      'Toast',
      'Schokolade',
      'zzz',
    ];

    test('the ids it asks for are rankAndTruncateTranslationRows\'s, distinct, in order', () {
      final rows = _translations();
      for (final query in queries) {
        final ranked = rankAndTruncateTranslationRows([...rows], query);
        final expected = <int>[];
        for (final row in ranked) {
          final id = row[SPConst.translationFoodId] as int;
          if (!expected.contains(id)) expected.add(id);
        }
        expect(tool.translationIds(rows, query), expected, reason: query);
        expect(expected.length, lessThanOrEqualTo(20), reason: query);
      }
    });

    test('the page: order, shown names and machine flags, whatever order the summary rows came in', () {
      final rows = _translations();
      final base = _summaries();
      for (var shift = 0; shift < base.length; shift += 4) {
        final summaries = [...base.skip(shift), ...base.take(shift)];
        for (final query in queries) {
          final appPage = _appTranslationPage(rows, summaries, query);
          final page = tool.translationPage(rows, summaries, query);
          expect(
            [for (final c in page) c.row['food_id']],
            [for (final f in appPage) f.foodId],
            reason: 'ids for "$query", summaries rotated by $shift',
          );
          expect(
            [for (final c in page) tool.shownName(c)],
            [for (final f in appPage) f.displayName],
            reason: 'shown names for "$query", summaries rotated by $shift',
          );
          expect(
            [for (final c in page) c.machineTranslated],
            [for (final f in appPage) f.displayNameIsMachineTranslated],
            reason: 'machine flags for "$query", summaries rotated by $shift',
          );
        }
      }
    });

    test('and lands where the app lands from that page', () {
      final rows = _translations();
      final base = _summaries();
      for (var shift = 0; shift < base.length; shift += 4) {
        final summaries = [...base.skip(shift), ...base.take(shift)];
        for (final query in queries) {
          final replay = tool.translationPathWinner(rows, summaries, query);
          expect(replay, isNotNull, reason: query);
          expect(
            replay!.candidate.row['food_id'],
            _appWinnerLocalized(rows, summaries, query),
            reason: 'query "$query", summaries rotated by $shift',
          );
        }
      }
    });

    test('a summary row the translation rows did not name sorts behind every ranked one, untranslated', () {
      final rows = _translations();
      final summaries = [_row(999, 'Stray'), ..._summaries()];
      final ids = tool.translationIds(rows, 'Milch');
      final page = tool.translationPage(rows, summaries, 'Milch');
      final at = page.indexWhere((c) => c.row['food_id'] == 999);
      expect(at, greaterThanOrEqualTo(ids.length));
      expect(page[at].localizedName, isNull);
      expect(tool.shownName(page[at]), 'Stray');
      // The app puts it in the same place: the unranked tail keeps the
      // fetch order, and the stray was fetched first.
      final appPage = _appTranslationPage(rows, summaries, 'Milch');
      expect(appPage.indexWhere((f) => f.foodId == 999), at);
      expect(appPage[at].displayName, 'Stray');
    });

    test('an empty page lands nowhere; empty summaries make an empty page', () {
      expect(tool.translationPathWinner(const [], const [], 'Milch'), isNull);
      expect(tool.translationPage(_translations(), const [], 'Milch'), isEmpty);
      expect(tool.landOn(const [], 'Milch'), isNull);
    });
  });

  group('the copied model ids agree with the catalogue', () {
    test('each provider default', () {
      expect(
        tool.defaultModelIds[tool.Provider.anthropic],
        AiModelCatalogue.defaultFor(AiProvider.anthropic)!.id,
      );
      expect(
        tool.defaultModelIds[tool.Provider.openrouter],
        AiModelCatalogue.defaultFor(AiProvider.openrouter)!.id,
      );
      expect(
        tool.defaultModelIds[tool.Provider.openai],
        AiModelCatalogue.defaultFor(AiProvider.openai)!.id,
      );
    });

    test('the OpenRouter pin', () {
      final model = AiModelCatalogue.defaultFor(AiProvider.openrouter)!;
      expect(tool.openRouterPins[model.id], model.providers);
    });
  });
}
