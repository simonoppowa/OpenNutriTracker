import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// A value per 100 g the meal-detail sheet needs before it can log a food.
enum RequiredNutrient { energy, carbohydrate, fat, protein }

/// The required values [nutriments] lacks, in the order the sheet names
/// them. Empty when the food can be logged. A real 0 is a value; only a
/// missing one (null) counts (#1474).
List<RequiredNutrient> missingRequiredNutrients(
  MealNutrimentsEntity nutriments,
) => [
  if (nutriments.energyKcal100 == null) RequiredNutrient.energy,
  if (nutriments.carbohydrates100 == null) RequiredNutrient.carbohydrate,
  if (nutriments.fat100 == null) RequiredNutrient.fat,
  if (nutriments.proteins100 == null) RequiredNutrient.protein,
];
