import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_total.dart';

class ComputeRecipeNutritionResult {
  final MealNutrimentsEntity perHundredG;
  final double totalWeightG;

  const ComputeRecipeNutritionResult({
    required this.perHundredG,
    required this.totalWeightG,
  });
}

class ComputeRecipeNutritionUseCase {
  // Treat a serving as the snapshot meal's serving weight in grams.
  // Treat 1 ml ≈ 1 g per the v1 simplification (see plan §3, decision 3).
  // Returns null when the unit can't be converted (e.g. a "serving" unit
  // on an ingredient that has no servingQuantity).
  double? convertAmountToGrams({
    required double amount,
    required String unit,
    double? servingQuantityG,
  }) {
    switch (unit) {
      case 'g':
      case 'gml':
      case 'g/ml':
        return amount;
      case 'ml':
      case 'l':
      case 'cl':
      case 'dl':
        if (unit == 'l') return amount * 1000;
        if (unit == 'cl') return amount * 10;
        if (unit == 'dl') return amount * 100;
        return amount;
      case 'kg':
        return amount * 1000;
      case 'mg':
        return amount / 1000;
      case 'oz':
        return UnitCalc.ozToG(amount);
      case 'fl oz':
      case 'fl.oz':
        return UnitCalc.flOzToMl(amount);
      case 'serving':
        if (servingQuantityG == null || servingQuantityG <= 0) return null;
        return amount * servingQuantityG;
      default:
        return null;
    }
  }

  /// Per nutrient, the ingredients' amounts summed together with how many
  /// ingredients gave no value (#54), for showing a recipe's values as "at
  /// least" where some are missing. Logged recipes do not keep this: their
  /// snapshot holds only the values per 100 g (a lower bound where an
  /// ingredient was missing one), and the recipe itself can always count
  /// it again from its stored ingredient snapshots.
  Map<NutrientField, NutrientTotal> coverage(
    List<RecipeIngredientEntity> ingredients,
  ) => {
    for (final field in NutrientField.values)
      field: NutrientTotal.over(
        ingredients,
        per100: (i) => field.per100(i.snapshotMeal.nutriments),
        amountG: (i) => i.convertedAmountG,
      ),
  };

  ComputeRecipeNutritionResult compute(
    List<RecipeIngredientEntity> ingredients, {
    double? totalWeightOverride,
  }) {
    if (ingredients.isEmpty) {
      return ComputeRecipeNutritionResult(
        perHundredG: MealNutrimentsEntity.empty(),
        totalWeightG: 0,
      );
    }

    final totalWeightG = totalWeightOverride ??
        ingredients.fold<double>(
          0,
          (sum, i) => sum + i.convertedAmountG,
        );

    if (totalWeightG <= 0) {
      return ComputeRecipeNutritionResult(
        perHundredG: MealNutrimentsEntity.empty(),
        totalWeightG: 0,
      );
    }

    // Per nutrient: the ingredients' amounts summed; a nutrient no
    // ingredient knows stays null instead of a misleading 0 (#46).
    final totals = coverage(ingredients);
    final per = NutrientField.entityFrom({
      for (final field in NutrientField.values)
        field: switch (totals[field]!.valueOrNull) {
          final sum? => sum * 100 / totalWeightG,
          null => null,
        },
    });

    return ComputeRecipeNutritionResult(
      perHundredG: per,
      totalWeightG: totalWeightG,
    );
  }
}
