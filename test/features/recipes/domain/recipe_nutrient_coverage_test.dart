import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';

RecipeIngredientEntity _ingredient(
  String code,
  double grams, {
  double? iron,
  double? vitaminC,
}) => RecipeIngredientEntity(
  snapshotMeal: MealEntity(
    code: code,
    name: code,
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: null,
    servingSize: null,
    nutriments: MealNutrimentsEntity(
      energyKcal100: 100,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
      iron100: iron,
      vitaminC100: vitaminC,
    ),
    source: MealSourceEntity.off,
  ),
  amount: grams,
  unit: 'g',
  convertedAmountG: grams,
);

void main() {
  final compute = ComputeRecipeNutritionUseCase();
  final ingredients = [
    _ingredient('lentils', 300, iron: 8),
    _ingredient('spinach', 200, iron: 2.7, vitaminC: 28),
    _ingredient('stock', 500),
  ];

  test('counts per nutrient the ingredients without a value', () {
    final coverage = compute.coverage(ingredients);

    final iron = coverage[NutrientField.iron]!;
    expect(iron.sum, closeTo(24 + 5.4, 1e-9));
    expect(iron.knownEntries, 2);
    expect(iron.unknownEntries, 1);
    expect(iron.isPartial, isTrue);

    final vitaminC = coverage[NutrientField.vitaminC]!;
    expect(vitaminC.sum, closeTo(56, 1e-9));
    expect(vitaminC.unknownEntries, 2);

    expect(coverage[NutrientField.energyKcal]!.isPartial, isFalse);
    expect(coverage[NutrientField.zinc]!.isUnknown, isTrue);
  });

  test('covers every nutrient field', () {
    expect(
      compute.coverage(ingredients).keys.toSet(),
      NutrientField.values.toSet(),
    );
  });

  test('its sums match the stored values per 100 g', () {
    final result = compute.compute(ingredients);
    final coverage = compute.coverage(ingredients);

    for (final field in NutrientField.values) {
      final per100 = field.per100(result.perHundredG);
      final total = coverage[field]!;
      if (total.valueOrNull == null) {
        expect(per100, isNull, reason: field.name);
      } else {
        expect(
          per100,
          closeTo(total.sum * 100 / result.totalWeightG, 1e-9),
          reason: field.name,
        );
      }
    }
  });
}
