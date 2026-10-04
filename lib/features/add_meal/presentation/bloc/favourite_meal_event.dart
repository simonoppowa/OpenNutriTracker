part of 'favourite_meal_bloc.dart';

abstract class FavouriteMealEvent extends Equatable {
  const FavouriteMealEvent();
}

class LoadFavouriteMealEvent extends FavouriteMealEvent {
  final String searchString;

  /// An empty `searchString` loads every favourite.
  const LoadFavouriteMealEvent({required this.searchString});

  @override
  List<Object?> get props => [searchString];
}

class _FavouritesChangedEvent extends FavouriteMealEvent {
  const _FavouritesChangedEvent();

  @override
  List<Object?> get props => [];
}
