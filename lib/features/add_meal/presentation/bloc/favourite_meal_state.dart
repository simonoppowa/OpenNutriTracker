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

  const FavouriteMealLoadedState({
    required this.favourites,
    this.usesImperialUnits = false,
  });

  @override
  List<Object?> get props => [favourites, usesImperialUnits];
}

class FavouriteMealFailedState extends FavouriteMealState {
  @override
  List<Object?> get props => [];
}
