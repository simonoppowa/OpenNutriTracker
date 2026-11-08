import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';

// Non-cascading: past IntakeDBO entries that referenced this recipe are
// retained because they hold a frozen snapshot of the meal at log time.
// Their kcal/macros stay accurate; deleting "I ate vanilla cake on Tuesday"
// would feel destructive for an artifact the user spent time creating.
class DeleteRecipeUseCase {
  final RecipeRepository _repository;
  final FavouriteMealRepository _favouriteMealRepository;

  DeleteRecipeUseCase(this._repository, this._favouriteMealRepository);

  /// A starred recipe stays on Favourites as its snapshot (#1307), so every
  /// profile's snapshot is brought up to the version being deleted first.
  /// The lock keeps a profile switch out between the two steps.
  Future<void> delete(String id) => withTrackedDayLock(() async {
    await _favouriteMealRepository.keepLatestRecipeSnapshot(id);
    await _repository.deleteRecipe(id);
  });
}
