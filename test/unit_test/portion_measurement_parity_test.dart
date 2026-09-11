// The #1160 harnesses under `tool/portion_measurement/` run with `dart run`,
// which cannot compile the Flutter imports `meal_entity.dart` and
// `ai_credential_storage.dart` drag in — so they carry copies of the three
// scorers and of the default model ids. This test is the only thing that
// keeps a copy honest: change the original and the harness measures against
// the wrong ranking or the wrong model.

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart'
    as app;
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart'
    as app;

import '../../tool/portion_measurement/providers.dart' as tool;
import '../../tool/portion_measurement/resolver.dart' as tool;

MealEntity _backendFood(String name) => MealEntity(
  code: name,
  name: name,
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
