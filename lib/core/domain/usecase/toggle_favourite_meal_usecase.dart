import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class ToggleFavouriteMealUsecase {
  final FavouriteMealRepository _favouriteMealRepository;

  ToggleFavouriteMealUsecase(this._favouriteMealRepository);

  /// Stars [meal] when it is not a favourite yet and unstars it when it is.
  /// Returns whether it is a favourite afterwards, or null when a profile
  /// switch overtook the tap and nothing was written.
  ///
  /// The read and the write run as one step under the tracked-day lock, on
  /// the profile that was active at [startedOn] (the tap): the repository
  /// resolves the active box on each call, so a switch landing between them
  /// would read one person's favourites and write the other's. The lock
  /// also keeps a [refreshDetailedSnapshot] from running in between.
  Future<bool?> toggle(MealEntity meal, {ProfileStamp? startedOn}) =>
      withTrackedDayLockOnProfile(() async {
        if (await _favouriteMealRepository.isFavourite(meal)) {
          await _favouriteMealRepository.removeFavourite(meal);
          return false;
        }
        await _favouriteMealRepository.addFavourite(meal);
        return true;
      }, startedOn: startedOn);

  /// Stores [meal], the full record its detail page fetched, over a starred
  /// food's thin search snapshot. Stars nothing that was not starred.
  Future<void> refreshDetailedSnapshot(MealEntity meal) => withTrackedDayLock(
    () => _favouriteMealRepository.refreshDetailedSnapshot(meal),
  );
}
