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

/// The star's food was hydrated to its full record (an Open Food Facts
/// search result whose detail page fetched the product), so a favourite on
/// it should keep the full record rather than the thin one.
class FavouriteMealHydratedEvent extends FavouriteToggleEvent {
  final MealEntity meal;

  const FavouriteMealHydratedEvent(this.meal);

  @override
  List<Object?> get props => [meal];
}

class _FavouritesChangedEvent extends FavouriteToggleEvent {
  const _FavouritesChangedEvent();

  @override
  List<Object?> get props => [];
}
