import 'dart:async';

import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_favourite_meals_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/toggle_favourite_meal_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// An in-memory Favourites list behind both favourites use cases, so bloc
/// and widget tests can star and unstar without a Hive box. Keyed the same
/// way as the real repository; [watchFavourites] fires on every change like
/// the box does.
class FakeFavourites {
  final _meals = <String, MealEntity>{};
  final _changes = StreamController<void>.broadcast();

  late final GetFavouriteMealsUsecase get = _FakeGetFavouriteMealsUsecase(this);
  late final ToggleFavouriteMealUsecase toggle =
      _FakeToggleFavouriteMealUsecase(this);

  /// Set to make every read fail, for the error state.
  Object? readError;

  /// Set to let a toggle's write land a turn after its read, the way a Hive
  /// put does, so a second toggle can read the list in between.
  bool slowWrites = false;

  List<MealEntity> get all => _meals.values.toList().reversed.toList();

  bool contains(MealEntity meal) =>
      _meals.containsKey(FavouriteMealRepository.keyOf(meal));

  void add(MealEntity meal) {
    _meals[FavouriteMealRepository.keyOf(meal)] = meal;
    _changes.add(null);
  }

  void remove(MealEntity meal) {
    _meals.remove(FavouriteMealRepository.keyOf(meal));
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}

class _FakeGetFavouriteMealsUsecase implements GetFavouriteMealsUsecase {
  _FakeGetFavouriteMealsUsecase(this._store);

  final FakeFavourites _store;

  @override
  Future<List<MealEntity>> getAllFavourites() async {
    final error = _store.readError;
    if (error != null) throw error;
    return _store.all;
  }

  @override
  Future<bool> isFavourite(MealEntity meal) async => _store.contains(meal);

  @override
  Stream<void> watchFavourites() => _store._changes.stream;
}

class _FakeToggleFavouriteMealUsecase implements ToggleFavouriteMealUsecase {
  _FakeToggleFavouriteMealUsecase(this._store);

  final FakeFavourites _store;

  @override
  Future<bool> toggle(MealEntity meal) async {
    final wasFavourite = _store.contains(meal);
    if (_store.slowWrites) await Future<void>.delayed(Duration.zero);
    if (wasFavourite) {
      _store.remove(meal);
      return false;
    }
    _store.add(meal);
    return true;
  }
}
