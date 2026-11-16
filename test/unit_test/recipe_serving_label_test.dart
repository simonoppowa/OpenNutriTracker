import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/utils/serving_label_localizer.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

RecipeEntity _recipe({required double totalWeightG, int? servingsCount}) =>
    RecipeEntity(
      id: 'recipe-serving-label-test',
      name: 'Chili',
      description: null,
      ingredients: const [],
      totalWeightG: totalWeightG,
      aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      servingsCount: servingsCount,
    );

void main() {
  group('a recipe as a food', () {
    test('labels its serving as one serving and its weight', () {
      // "4 servings" beside a quantity of 1 read as the whole pot.
      final meal = _recipe(totalWeightG: 1550, servingsCount: 4).toMealEntity();

      expect(meal.servingSize, '1 serving (387.5 g)');
      expect(meal.servingQuantity, 387.5);
    });

    test('a whole number of grams has no decimals', () {
      final meal = _recipe(totalWeightG: 930, servingsCount: 3).toMealEntity();

      expect(meal.servingSize, '1 serving (310 g)');
    });

    test('a share that does not divide evenly shows one decimal', () {
      final meal = _recipe(totalWeightG: 1000, servingsCount: 3).toMealEntity();

      expect(meal.servingSize, '1 serving (333.3 g)');
    });

    test('the label is translated at display time like a food\'s', () {
      final meal = _recipe(totalWeightG: 1550, servingsCount: 4).toMealEntity();

      expect(
        localizeServingLabel(lookupS(const Locale('de')), meal.servingSize!),
        '1 Portion (387.5 g)',
      );
    });

    test('a recipe without servings has no serving label', () {
      final meal = _recipe(totalWeightG: 1000).toMealEntity();

      expect(meal.servingSize, isNull);
      expect(meal.servingQuantity, isNull);
    });
  });
}
