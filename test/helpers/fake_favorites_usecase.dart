import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/favorites/domain/favorite_entry.dart';
import 'package:opennutritracker/features/favorites/domain/favorites_usecase.dart';

/// In-memory [FavoritesUsecase] for widget tests of screens that show a
/// favourite star.
class FakeFavoritesUsecase extends Fake implements FavoritesUsecase {
  final ids = <String>{};
  Object? toggleError;

  /// What [favoriteMeals] lists, filtered by name like the real one.
  final meals = <MealEntity>[];

  @override
  Future<List<MealEntity>> favoriteMeals({String query = ''}) async => [
    for (final meal in meals)
      if ((meal.name ?? '').toLowerCase().contains(query.toLowerCase())) meal,
  ];

  @override
  final ValueNotifier<int> changes = ValueNotifier(0);

  @override
  bool isMealFavorite(MealEntity meal) =>
      ids.contains(FavoriteEntry.idForMeal(meal));

  @override
  bool isRecipeFavorite(String recipeId) =>
      ids.contains(FavoriteEntry.idForRecipe(recipeId));

  @override
  Future<bool> toggleMeal(MealEntity meal) async =>
      _toggle(FavoriteEntry.idForMeal(meal));

  @override
  Future<bool> toggleRecipe(RecipeEntity recipe) async =>
      _toggle(FavoriteEntry.idForRecipe(recipe.id));

  bool _toggle(String id) {
    if (toggleError != null) throw toggleError!;
    final added = ids.add(id);
    if (!added) ids.remove(id);
    changes.value++;
    return added;
  }
}
