import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class GetFavouriteMealsUsecase {
  final FavouriteMealRepository _favouriteMealRepository;

  GetFavouriteMealsUsecase(this._favouriteMealRepository);

  Future<List<MealEntity>> getAllFavourites() async {
    return _favouriteMealRepository.getAllFavourites();
  }

  Future<bool> isFavourite(MealEntity meal) async {
    return _favouriteMealRepository.isFavourite(meal);
  }

  /// Fires whenever any favourite is added or removed.
  Stream<void> watchFavourites() => _favouriteMealRepository.watchFavourites();
}
