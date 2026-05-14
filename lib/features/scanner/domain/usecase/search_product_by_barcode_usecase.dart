import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Outcome of a barcode lookup that may need to ask the user to disambiguate.
///
/// Most scans resolve to a single meal so [BarcodeLookupResult.single] is the
/// common case. When the user has saved more than one custom recipe against
/// the same barcode (eg "apple, large" and "apple, small") the scanner needs
/// to show a chooser sheet before continuing — that's the
/// [BarcodeLookupResult.multipleRecipes] case.
sealed class BarcodeLookupResult {
  const BarcodeLookupResult();

  const factory BarcodeLookupResult.single(MealEntity meal) =
      BarcodeLookupSingle;

  const factory BarcodeLookupResult.multipleRecipes(
    List<RecipeEntity> recipes,
  ) = BarcodeLookupMultipleRecipes;
}

class BarcodeLookupSingle extends BarcodeLookupResult {
  final MealEntity meal;
  const BarcodeLookupSingle(this.meal);
}

class BarcodeLookupMultipleRecipes extends BarcodeLookupResult {
  final List<RecipeEntity> recipes;
  const BarcodeLookupMultipleRecipes(this.recipes);
}

class SearchProductByBarcodeUseCase {
  final ProductsRepository _productsRepository;
  final CustomMealDataSource _customMealDataSource;
  final RecipeDataSource _recipeDataSource;
  final RemoteSearchCacheDataSource _cachedOffMealDataSource;

  SearchProductByBarcodeUseCase(
    this._productsRepository,
    this._customMealDataSource,
    this._recipeDataSource,
    this._cachedOffMealDataSource,
  );

  /// Resolution order:
  ///   1. User's own custom recipes — a barcode the user has explicitly
  ///      attached to a recipe (#167) wins over everything else, including
  ///      flat custom meals, because attaching a barcode is the user
  ///      saying "this is the canonical version for this scan"
  ///   2. User's own custom meals — they take priority over remote data
  ///      because the user explicitly created/imported them
  ///   3. Cached OFF lookup from a previous successful network hit —
  ///      makes repeat scans instant and works offline
  ///   4. Live OFF API call — only when nothing local matches; the
  ///      successful result is then written to the cache for next time
  ///
  /// First-match-wins on recipes — callers that need to disambiguate
  /// between multiple recipes sharing a barcode should use [lookupBarcode]
  /// instead, which surfaces the full list.
  Future<MealEntity> searchProductByBarcode(String barcode) async {
    final recipeMatch = _recipeDataSource
        .getAllRecipes()
        .where((dbo) => dbo.barcode != null && dbo.barcode == barcode)
        .firstOrNull;
    if (recipeMatch != null) {
      return RecipeEntity.fromDBO(recipeMatch).toMealEntity();
    }

    final customMatch = _customMealDataSource
        .getAllCustomMeals()
        .where((dbo) => dbo.code != null && dbo.code == barcode)
        .firstOrNull;
    if (customMatch != null) {
      return MealEntity.fromMealDBO(customMatch);
    }

    final cachedMatch = _cachedOffMealDataSource.getByBarcode(barcode);
    if (cachedMatch != null) {
      return MealEntity.fromMealDBO(cachedMatch);
    }

    final remote = await _productsRepository.getOFFProductByBarcode(barcode);
    await _cachedOffMealDataSource.cache(MealDBO.fromMealEntity(remote));
    return remote;
  }

  /// Same resolution chain as [searchProductByBarcode] but returns a
  /// [BarcodeLookupResult] so the scanner UI can prompt the user to choose
  /// when more than one recipe claims the same barcode. The flat custom
  /// meal, cache, and OFF paths always collapse to a single result —
  /// disambiguation only matters for recipes, because flat custom meals
  /// are keyed on `code` with an implicit one-to-one assumption and the
  /// OFF / cache lookups are inherently single-record.
  Future<BarcodeLookupResult> lookupBarcode(String barcode) async {
    final recipeMatches = _recipeDataSource
        .getAllRecipes()
        .where((dbo) => dbo.barcode != null && dbo.barcode == barcode)
        .toList();
    if (recipeMatches.length > 1) {
      return BarcodeLookupResult.multipleRecipes(
        recipeMatches.map(RecipeEntity.fromDBO).toList(),
      );
    }
    if (recipeMatches.length == 1) {
      return BarcodeLookupResult.single(
        RecipeEntity.fromDBO(recipeMatches.single).toMealEntity(),
      );
    }

    final customMatch = _customMealDataSource
        .getAllCustomMeals()
        .where((dbo) => dbo.code != null && dbo.code == barcode)
        .firstOrNull;
    if (customMatch != null) {
      return BarcodeLookupResult.single(MealEntity.fromMealDBO(customMatch));
    }

    final cachedMatch = _cachedOffMealDataSource.getByBarcode(barcode);
    if (cachedMatch != null) {
      return BarcodeLookupResult.single(MealEntity.fromMealDBO(cachedMatch));
    }

    final remote = await _productsRepository.getOFFProductByBarcode(barcode);
    await _cachedOffMealDataSource.cache(MealDBO.fromMealEntity(remote));
    return BarcodeLookupResult.single(remote);
  }
}
