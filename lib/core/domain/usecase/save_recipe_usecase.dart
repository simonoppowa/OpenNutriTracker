import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';

class SaveRecipeUseCase {
  final RecipeRepository _repository;
  final ComputeRecipeNutritionUseCase _computeUseCase;
  final IntakeRepository _intakeRepository;
  final AddTrackedDayUsecase _addTrackedDayUsecase;

  SaveRecipeUseCase(
    this._repository,
    this._computeUseCase,
    this._intakeRepository,
    this._addTrackedDayUsecase,
  );

  Future<RecipeEntity> save(
    RecipeEntity recipe, {
    bool totalWeightOverridden = false,
  }) async {
    final result = _computeUseCase.compute(
      recipe.ingredients,
      totalWeightOverride: totalWeightOverridden ? recipe.totalWeightG : null,
    );

    final updated = recipe.copyWith(
      totalWeightG: result.totalWeightG,
      aggregatedNutrimentsPer100: result.perHundredG,
      updatedAt: DateTime.now(),
    );

    await _repository.saveRecipe(updated);

    final newMealDBO = MealDBO.fromMealEntity(updated.toMealEntity());
    final rewrites = await _intakeRepository.remapRecipeOnIntakes(
      recipeId: updated.id,
      toMeal: newMealDBO,
    );

    for (final pair in rewrites) {
      final before = pair.$1;
      final after = pair.$2;
      final kcalDelta = after.totalKcal - before.totalKcal;
      final carbsDelta = after.totalCarbsGram - before.totalCarbsGram;
      final fatDelta = after.totalFatsGram - before.totalFatsGram;
      final proteinDelta = after.totalProteinsGram - before.totalProteinsGram;
      if (kcalDelta != 0) {
        if (kcalDelta > 0) {
          await _addTrackedDayUsecase.addDayCaloriesTracked(
            after.dateTime,
            kcalDelta,
          );
        } else {
          await _addTrackedDayUsecase.removeDayCaloriesTracked(
            after.dateTime,
            -kcalDelta,
          );
        }
      }
      if (carbsDelta != 0 || fatDelta != 0 || proteinDelta != 0) {
        await _addTrackedDayUsecase.addDayMacrosTracked(
          after.dateTime,
          carbsTracked: carbsDelta,
          fatTracked: fatDelta,
          proteinTracked: proteinDelta,
        );
      }
    }

    return updated;
  }
}
