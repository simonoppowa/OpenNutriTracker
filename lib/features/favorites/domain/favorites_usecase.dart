import 'package:flutter/foundation.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/favorites/data/favorite_data_source.dart';
import 'package:opennutritracker/features/favorites/domain/favorite_entry.dart';

/// Marking foods and recipes as favourites and listing them (#37). New
/// favourites go to the end of the list; a recipe that no longer exists
/// drops out of it.
class FavoritesUsecase {
  final FavoriteDataSource _dataSource;
  final RecipeRepository _recipeRepository;
  final DateTime Function() _clock;

  /// Goes up whenever the favourites changed, so open screens update.
  final ValueNotifier<int> changes = ValueNotifier(0);

  FavoritesUsecase(
    this._dataSource,
    this._recipeRepository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  bool isMealFavorite(MealEntity meal) =>
      _dataSource.contains(FavoriteEntry.idForMeal(meal));

  bool isRecipeFavorite(String recipeId) =>
      _dataSource.contains(FavoriteEntry.idForRecipe(recipeId));

  /// Marks or unmarks [meal]; returns whether it is a favourite now.
  Future<bool> toggleMeal(MealEntity meal) => _toggle(
    FavoriteEntry.idForMeal(meal),
    (id, index) => FavoriteEntry(
      id: id,
      kind: FavoriteKind.food,
      name: meal.name ?? '',
      meal: meal,
      createdAt: _clock(),
      sortIndex: index,
    ),
  );

  /// Marks or unmarks [recipe]; returns whether it is a favourite now.
  Future<bool> toggleRecipe(RecipeEntity recipe) => _toggle(
    FavoriteEntry.idForRecipe(recipe.id),
    (id, index) => FavoriteEntry(
      id: id,
      kind: FavoriteKind.recipe,
      name: recipe.name,
      recipeId: recipe.id,
      createdAt: _clock(),
      sortIndex: index,
    ),
  );

  /// The favourites in list order, without recipes that were deleted
  /// (which are removed for good).
  Future<List<FavoriteEntry>> list() async {
    final entries = _dataSource.all();
    final gone = [
      for (final entry in entries)
        if (entry.kind == FavoriteKind.recipe &&
            _recipeRepository.getRecipeById(entry.recipeId!) == null)
          entry.id,
    ];
    if (gone.isNotEmpty) {
      await _dataSource.deleteAll(gone);
      changes.value++;
    }
    return [
      for (final entry in entries)
        if (!gone.contains(entry.id)) entry,
    ];
  }

  /// Puts the favourites in the order of [ids]; ids not given keep their
  /// relative order after them.
  Future<void> reorder(List<String> ids) async {
    final entries = _dataSource.all();
    final byId = {for (final e in entries) e.id: e};
    final ordered = [
      for (final id in ids)
        if (byId.containsKey(id)) byId[id]!,
      for (final e in entries)
        if (!ids.contains(e.id)) e,
    ];
    await _dataSource.putAll([
      for (final (index, entry) in ordered.indexed) entry.withSortIndex(index),
    ]);
    changes.value++;
  }

  Future<bool> _toggle(
    String id,
    FavoriteEntry Function(String id, int sortIndex) create,
  ) async {
    if (_dataSource.contains(id)) {
      await _dataSource.delete(id);
      changes.value++;
      return false;
    }
    final entries = _dataSource.all();
    final next = entries.isEmpty ? 0 : entries.last.sortIndex + 1;
    await _dataSource.put(create(id, next));
    changes.value++;
    return true;
  }
}
