import 'package:collection/collection.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// The foods the recipe ingredient picker offers under Recent: the ones
/// this profile logged, plus the ones the saved recipes already use, so a
/// food added to one recipe is one tap away when building the next (#516).
///
/// Only the picker reads this. The add-meal Recently list stays what was
/// eaten, so an ingredient never shows there just because a recipe uses it.
///
/// Built from data already on disk: the intake log and the recipes' own
/// ingredient copies. A recipe counts as used when it was last saved, and
/// deleting it drops the foods only it used. Recipes are the library every
/// profile shares, while the logged foods are the active profile's own.
class GetRecentIngredientsUsecase {
  final GetIntakeUsecase _getIntakeUsecase;
  final RecipeRepository _recipeRepository;

  GetRecentIngredientsUsecase(this._getIntakeUsecase, this._recipeRepository);

  /// Most recently used first, each food once — keyed by barcode, or by
  /// name when it has none, the way the logged Recents are.
  Future<List<MealEntity>> getRecentIngredients() async {
    final intakes = await _getIntakeUsecase.getRecentIntake();
    final used = <({DateTime at, MealEntity meal})>[
      for (final intake in intakes) (at: intake.dateTime, meal: intake.meal),
      for (final recipe in _recipeRepository.getAllRecipes())
        for (final ingredient in recipe.ingredients)
          (at: recipe.updatedAt, meal: _asItIsNow(ingredient.snapshotMeal)),
    ];
    // Stable, so one recipe's ingredients keep the order it lists them in.
    mergeSort(used, compare: (a, b) => b.at.compareTo(a.at));
    final seen = <String>{};
    return [
      for (final entry in used)
        if (seen.add(entry.meal.code ?? entry.meal.name ?? '')) entry.meal,
    ];
  }

  /// A recipe used as an ingredient is offered as it is now, like a logged
  /// one (#1276); a deleted one keeps the copy the recipe stored. Any other
  /// food is offered as the recipe stored it, since that copy is what the
  /// recipe was built with even when its source is gone.
  MealEntity _asItIsNow(MealEntity meal) {
    if (meal.source != MealSourceEntity.recipe || meal.code == null) {
      return meal;
    }
    return _recipeRepository.getRecipeById(meal.code!)?.toMealEntity() ?? meal;
  }
}
