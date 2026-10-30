import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Whether a bare [count] of [meal] asks for more servings than its recipe
/// makes in a batch.
///
/// Bulk add reads a bare count as servings (#622), and a recipe's serving is
/// a share of the batch, not a piece: "14 pelmeni" against a 6-serving batch
/// of pelmeni would log 14 servings, more than twice the batch. A photo
/// counts dumplings, pancakes and tarts, so such a row is flagged for the
/// user to settle.
bool countExceedsRecipe(MealEntity? meal, double count) {
  if (meal == null || meal.source != MealSourceEntity.recipe) return false;
  final serving = meal.servingQuantity;
  final batch = double.tryParse(meal.mealQuantity ?? '');
  if (serving == null || serving <= 0 || batch == null) return false;
  return count > (batch / serving).round();
}
