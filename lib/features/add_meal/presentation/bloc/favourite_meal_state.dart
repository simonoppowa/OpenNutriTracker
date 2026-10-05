part of 'favourite_meal_bloc.dart';

abstract class FavouriteMealState extends Equatable {
  const FavouriteMealState();
}

class FavouriteMealInitial extends FavouriteMealState {
  @override
  List<Object?> get props => [];
}

class FavouriteMealLoadingState extends FavouriteMealState {
  @override
  List<Object?> get props => [];
}

class FavouriteMealLoadedState extends FavouriteMealState {
  final List<MealEntity> favourites;
  final bool usesImperialUnits;

  /// Makes every load a new state. MealEntity == compares code and name
  /// only, so a reload after a starred custom meal's macros were edited
  /// would equal the last state, the bloc would drop it, and a tap would
  /// open the detail page with the old numbers.
  final Object _load = Object();

  FavouriteMealLoadedState({
    required this.favourites,
    this.usesImperialUnits = false,
  });

  @override
  List<Object?> get props => [_load];
}

class FavouriteMealFailedState extends FavouriteMealState {
  @override
  List<Object?> get props => [];
}
