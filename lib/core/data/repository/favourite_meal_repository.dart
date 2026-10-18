import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/favourite_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:stream_transform/stream_transform.dart';

class FavouriteMealRepository {
  final FavouriteMealDataSource _favouriteMealDataSource;
  final CustomMealDataSource _customMealDataSource;
  final RecipeDataSource _recipeDataSource;

  FavouriteMealRepository(
    this._favouriteMealDataSource,
    this._customMealDataSource,
    this._recipeDataSource,
  );

  static String keyOf(MealEntity meal) => FavouriteMealDBO.keyFor(
    MealSourceDBO.fromMealSourceEntity(meal.source),
    meal.code,
    meal.name,
  );

  Future<bool> isFavourite(MealEntity meal) async =>
      _favouriteMealDataSource.isFavourite(keyOf(meal));

  Future<void> addFavourite(MealEntity meal) async {
    await _favouriteMealDataSource.addFavourite(
      FavouriteMealDBO(
        meal: MealDBO.fromMealEntity(meal),
        addedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeFavourite(MealEntity meal) async {
    await _favouriteMealDataSource.deleteFavourite(keyOf(meal));
  }

  /// Refreshes the saved snapshot after an edit and moves the favourite to a
  /// new key when needed. Keeping the latest snapshot means it remains current
  /// if the custom meal is later deleted from its library.
  Future<void> moveFavourite(MealEntity previous, MealEntity updated) async {
    final oldKey = keyOf(previous);
    final newKey = keyOf(updated);
    final existing = _favouriteMealDataSource.getFavourite(oldKey);
    if (existing == null) return;
    await _favouriteMealDataSource.addFavourite(
      FavouriteMealDBO(
        meal: MealDBO.fromMealEntity(updated),
        addedAt: existing.addedAt,
      ),
    );
    if (oldKey != newKey) {
      await _favouriteMealDataSource.deleteFavourite(oldKey);
    }
  }

  /// Writes the library's current version of the custom meal stored under
  /// [libraryKey] (its `code ?? name`, the key the library deletes by) into
  /// the favourite on it, keeping `addedAt`. Called before the meal is
  /// deleted from the library, so the favourite that outlives it shows and
  /// logs the meal as it last was, whichever path last changed it — the
  /// edit form, a meal import, the scanner.
  Future<void> keepLatestCustomMealSnapshot(String libraryKey) async {
    for (final meal in _customMealDataSource.getAllCustomMeals()) {
      if ((meal.code ?? meal.name) != libraryKey) continue;
      final key = FavouriteMealDBO.keyFor(meal.source, meal.code, meal.name);
      final existing = _favouriteMealDataSource.getFavourite(key);
      if (existing == null) continue;
      await _favouriteMealDataSource.addFavourite(
        FavouriteMealDBO(
          meal: MealDBO.fromMealEntity(MealEntity.fromMealDBO(meal)),
          addedAt: existing.addedAt,
        ),
      );
    }
  }

  /// Every favourite, the most recently starred first.
  ///
  /// A custom meal or recipe is read from its library when it is still there,
  /// so an edit made after starring it — new ingredients, corrected macros —
  /// is what gets logged, not the numbers from the day it was starred. The
  /// snapshot stands in once the library entry is gone, the same way a logged
  /// custom meal outlives its template in the Recently list.
  Future<List<MealEntity>> getAllFavourites() async {
    final library = _Library.read(_customMealDataSource, _recipeDataSource);
    return _favouriteMealDataSource
        .getAllFavourites()
        .map(library.resolve)
        .toList();
  }

  /// Exports the current custom-meal or recipe version while preserving the
  /// favourite's original timestamp and identity.
  Future<List<FavouriteMealDBO>> getAllFavouritesDBO() async {
    final library = _Library.read(_customMealDataSource, _recipeDataSource);
    return _favouriteMealDataSource.getAllFavourites().map((favourite) {
      final currentMeal = library.resolve(favourite);
      return FavouriteMealDBO(
        meal: MealDBO.fromMealEntity(currentMeal),
        addedAt: favourite.addedAt,
      );
    }).toList();
  }

  Future<void> addAllFavouriteDBOs(List<FavouriteMealDBO> favourites) async {
    await _favouriteMealDataSource.addAllFavourites(favourites);
  }

  /// Fires on anything that can change [getAllFavourites]: a star toggled,
  /// or a custom meal or recipe edited in its library, which the list reads
  /// in place of its snapshot.
  Stream<void> watchFavourites() => _favouriteMealDataSource.watch().mergeAll([
    _customMealDataSource.watch(),
    _recipeDataSource.watch(),
  ]);
}

/// The custom meals and recipes a load resolves favourites against, each
/// read once and indexed, so a load is linear in the library rather than a
/// scan of the recipe box per starred recipe. Recipes are read on the first
/// starred recipe only.
class _Library {
  _Library.read(this._customMeals, this._recipes);

  final CustomMealDataSource _customMeals;
  final RecipeDataSource _recipes;

  late final Map<String, MealDBO> _customMealsByKey = {
    for (final meal in _customMeals.getAllCustomMeals())
      FavouriteMealDBO.keyFor(meal.source, meal.code, meal.name): meal,
  };

  late final Map<String, RecipeDBO> _recipesById = () {
    // The first recipe with an id wins, as `getRecipeById` picks it.
    final byId = <String, RecipeDBO>{};
    for (final recipe in _recipes.getAllRecipes()) {
      byId.putIfAbsent(recipe.id, () => recipe);
    }
    return byId;
  }();

  MealEntity resolve(FavouriteMealDBO favourite) {
    final snapshot = favourite.meal;
    if (snapshot.source == MealSourceDBO.recipe && snapshot.code != null) {
      final recipe = _recipesById[snapshot.code!];
      if (recipe != null) return RecipeEntity.fromDBO(recipe).toMealEntity();
    }
    final custom = _customMealsByKey[favourite.mealKey];
    return MealEntity.fromMealDBO(custom ?? snapshot);
  }
}
