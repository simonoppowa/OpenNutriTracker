import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

class _FakeRecipeRepository implements RecipeRepository {
  final Map<String, RecipeEntity> store = {};

  @override
  Future<void> saveRecipe(RecipeEntity recipe) async {
    store[recipe.id] = recipe;
  }

  @override
  RecipeEntity? getRecipeById(String id) => store[id];

  @override
  List<RecipeEntity> getAllRecipes() => store.values.toList();

  @override
  Future<void> deleteRecipe(String id) async {
    store.remove(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _NoFavourites implements FavouriteMealRepository {
  @override
  Future<void> keepLatestRecipeSnapshot(String recipeId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

void main() {
  test(
    'DeleteRecipeUseCase removes the recipe but does NOT touch existing intakes',
    () async {
      final repo = _FakeRecipeRepository();

      // Save a recipe.
      final recipe = RecipeEntity(
        id: 'recipe-1',
        name: 'Vanilla Cake',
        description: null,
        ingredients: const [],
        totalWeightG: 1500,
        aggregatedNutrimentsPer100: MealNutrimentsEntity(
          energyKcal100: 350,
          carbohydrates100: 50,
          fat100: 15,
          proteins100: 6,
          sugars100: 30,
          saturatedFat100: 8,
          fiber100: 1,
        ),
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
        servingsCount: 8,
      );
      await repo.saveRecipe(recipe);

      // Build an intake "logged from this recipe" — IntakeDBO snapshots
      // the meal at log time, so the intake holds its own copy of the
      // recipe's nutritional data and ID.
      final loggedIntake = IntakeEntity(
        id: 'intake-1',
        unit: 'g',
        amount: 200, // 200 g of cake
        type: IntakeTypeEntity.snack,
        meal: recipe.toMealEntity(),
        dateTime: DateTime.utc(2024, 5, 1),
      );
      // Sanity check: the snapshot meal references the recipe by id.
      expect(loggedIntake.meal.code, 'recipe-1');
      expect(loggedIntake.meal.source, MealSourceEntity.recipe);
      // 200 g × 350 kcal / 100 g = 700 kcal logged.
      expect(loggedIntake.totalKcal, closeTo(700, 0.01));

      // Capture the snapshot fields BEFORE delete to compare against AFTER.
      final beforeKcal = loggedIntake.totalKcal;
      final beforeMealName = loggedIntake.meal.name;
      final beforeMealCode = loggedIntake.meal.code;

      // Delete the recipe.
      final useCase = DeleteRecipeUseCase(repo, _NoFavourites());
      await useCase.delete(recipe.id);

      // Recipe is gone from the repository.
      expect(repo.getRecipeById('recipe-1'), isNull);
      expect(repo.getAllRecipes(), isEmpty);

      // The intake's meal snapshot is independent of the recipe entity —
      // it remains intact and continues to compute the same kcal.
      // (DeleteRecipeUseCase has no IntakeRepository dependency at all,
      // so it cannot cascade even by accident.)
      expect(loggedIntake.totalKcal, beforeKcal);
      expect(loggedIntake.meal.name, beforeMealName);
      expect(loggedIntake.meal.code, beforeMealCode);
      expect(loggedIntake.meal.nutriments.energyKcal100, 350);
    },
  );
}
