import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/favourite_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

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

  /// Every favourite, the most recently starred first.
  ///
  /// A custom meal or recipe is read from its library when it is still there,
  /// so an edit made after starring it — new ingredients, corrected macros —
  /// is what gets logged, not the numbers from the day it was starred. The
  /// snapshot stands in once the library entry is gone, the same way a logged
  /// custom meal outlives its template in the Recently list.
  Future<List<MealEntity>> getAllFavourites() async {
    final customMeals = {
      for (final meal in _customMealDataSource.getAllCustomMeals())
        FavouriteMealDBO.keyFor(meal.source, meal.code, meal.name): meal,
    };
    return _favouriteMealDataSource.getAllFavourites().map((favourite) {
      final snapshot = favourite.meal;
      if (snapshot.source == MealSourceDBO.recipe && snapshot.code != null) {
        final recipe = _recipeDataSource.getRecipeById(snapshot.code!);
        if (recipe != null) {
          return RecipeEntity.fromDBO(recipe).toMealEntity();
        }
      }
      final custom = customMeals[favourite.mealKey];
      return MealEntity.fromMealDBO(custom ?? snapshot);
    }).toList();
  }

  Future<List<FavouriteMealDBO>> getAllFavouritesDBO() async =>
      _favouriteMealDataSource.getAllFavourites();

  Future<void> addAllFavouriteDBOs(List<FavouriteMealDBO> favourites) async {
    await _favouriteMealDataSource.addAllFavourites(favourites);
  }

  Stream<void> watchFavourites() => _favouriteMealDataSource.watch();
}
