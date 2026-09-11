// The #1160 harnesses under `tool/portion_measurement/` run with `dart run`,
// which cannot compile the Flutter imports `meal_entity.dart` and
// `ai_credential_storage.dart` drag in — so they carry copies of the three
// scorers, a replay of the AI path's ranking, and the default model ids.
// This test is the only thing that keeps a copy honest: change the original
// and the harness measures against the wrong ranking or the wrong model.
//
// Three things are pinned. The scalar scorers, on names with and without a
// brand. The facts the replay assumes about a backend food — the shown
// name, the brand, `detailed` false, no machine translation on the English
// search. And the replay itself, run beside the app's own pipeline over a
// pool wider than the truncation, with rows that share a shown name, rows
// that share it and a brand, brand-only matches, and exact score ties — so
// the top-20 cut, the collapse key, the strict-greater tie rule and the
// shown-name rule are each the app's, not a reading of them.

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart'
    as app;
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart'
    as app;

import '../../tool/portion_measurement/providers.dart' as tool;
import '../../tool/portion_measurement/resolver.dart' as tool;

MealEntity _backendFood(String name, {String? brands}) => MealEntity(
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
          replay!.row['food_id'],
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
            tool.aiPathWinner(rows, query)!.row['food_id'],
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
