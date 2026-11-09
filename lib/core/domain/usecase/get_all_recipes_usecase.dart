import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';

class GetAllRecipesUseCase {
  final RecipeRepository _repository;

  GetAllRecipesUseCase(this._repository);

  List<RecipeEntity> getAll() => _repository.getAllRecipes();

  /// Fires after every recipe saved, edited or deleted.
  Stream<void> watch() => _repository.watch();
}
