part of 'favourite_toggle_bloc.dart';

abstract class FavouriteToggleEvent extends Equatable {
  const FavouriteToggleEvent();
}

class LoadFavouriteStatusEvent extends FavouriteToggleEvent {
  final MealEntity meal;

  const LoadFavouriteStatusEvent(this.meal);

  @override
  List<Object?> get props => [meal];
}

class ToggleFavouriteEvent extends FavouriteToggleEvent {
  final MealEntity meal;

  const ToggleFavouriteEvent(this.meal);

  @override
  List<Object?> get props => [meal];
}

class _FavouritesChangedEvent extends FavouriteToggleEvent {
  const _FavouritesChangedEvent();

  @override
  List<Object?> get props => [];
}
