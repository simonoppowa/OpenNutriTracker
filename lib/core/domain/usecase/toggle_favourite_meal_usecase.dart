import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class ToggleFavouriteMealUsecase {
  final FavouriteMealRepository _favouriteMealRepository;

  ToggleFavouriteMealUsecase(this._favouriteMealRepository);

  /// Stars [meal] when it is not a favourite yet and unstars it when it is.
  /// Returns whether it is a favourite afterwards.
  Future<bool> toggle(MealEntity meal) async {
    if (await _favouriteMealRepository.isFavourite(meal)) {
      await _favouriteMealRepository.removeFavourite(meal);
      return false;
    }
    await _favouriteMealRepository.addFavourite(meal);
    return true;
  }
}
