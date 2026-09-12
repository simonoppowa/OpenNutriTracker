import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/json_recipe_importer.dart';

// #1139: a JSON recipe carrying an explicit `totalWeight` lost that override
// on save, because the JSON import use case called SaveRecipeUseCase without
// passing `totalWeightOverridden`. The importer now hands each recipe back
// wrapped in `ImportedRecipe`, so the use case can tell save whether the
// original JSON supplied a total weight or not.

void main() {
  group('JsonRecipeImporter.parse totalWeight override flag', () {
    test('sets totalWeightOverridden when the JSON supplies totalWeight', () {
      const json = '''{
  "name": "Vanilla Cake",
  "totalWeight": 1500,
  "ingredients": [
    {"name": "Flour", "amount": 200, "unit": "g", "kcalPer100": 340}
  ]
}''';

      final result = JsonRecipeImporter.parse(json);

      expect(result.errors, isEmpty);
      expect(result.recipes, hasLength(1));
      expect(result.recipes.single.totalWeightOverridden, isTrue);
      expect(result.recipes.single.recipe.name, 'Vanilla Cake');
    });

    test('leaves totalWeightOverridden false when totalWeight is absent', () {
      const json = '''{
  "name": "Smoothie",
  "ingredients": [
    {"name": "Banana", "amount": 300, "unit": "g", "kcalPer100": 89}
  ]
}''';

      final result = JsonRecipeImporter.parse(json);

      expect(result.errors, isEmpty);
      expect(result.recipes.single.totalWeightOverridden, isFalse);
    });

    test('sets the flag per recipe when a batch mixes both shapes', () {
      const json = '''[
  {
    "name": "Cake",
    "totalWeight": 1500,
    "ingredients": [
      {"name": "Flour", "amount": 200, "unit": "g", "kcalPer100": 340}
    ]
  },
  {
    "name": "Smoothie",
    "ingredients": [
      {"name": "Banana", "amount": 300, "unit": "g", "kcalPer100": 89}
    ]
  }
]''';

      final result = JsonRecipeImporter.parse(json);

      expect(result.recipes, hasLength(2));
      final byName = {for (final r in result.recipes) r.recipe.name: r};
      expect(byName['Cake']!.totalWeightOverridden, isTrue);
      expect(byName['Smoothie']!.totalWeightOverridden, isFalse);
    });
  });
}
