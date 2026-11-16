import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';

class RecipeRepository {
  final RecipeDataSource _dataSource;

  RecipeRepository(this._dataSource);

  Future<void> saveRecipe(RecipeEntity recipe) =>
      _dataSource.saveRecipe(recipe.toDBO());

  List<RecipeEntity> getAllRecipes() =>
      _dataSource.getAllRecipes().map(RecipeEntity.fromDBO).toList();

  /// Every recipe's name, the latest changed first.
  List<String> getRecipeNamesLatestFirst() {
    final recipes = _dataSource.getAllRecipes()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return [for (final r in recipes) r.name];
  }

  RecipeEntity? getRecipeById(String id) {
    final dbo = _dataSource.getRecipeById(id);
    return dbo != null ? RecipeEntity.fromDBO(dbo) : null;
  }

  Future<void> deleteRecipe(String id) => _dataSource.deleteRecipe(id);

  // Used by ExportDataUsecase / ImportDataUsecase.
  List<RecipeDBO> getAllRecipesDBO() => _dataSource.getAllRecipes();

  Future<void> addAllRecipeDBOs(List<RecipeDBO> recipes) async {
    for (final r in recipes) {
      await _dataSource.saveRecipe(r);
    }
  }
}
