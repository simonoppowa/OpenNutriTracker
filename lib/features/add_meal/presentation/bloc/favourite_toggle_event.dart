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

/// A write to the stored favourite. Toggles and hydrations share one
/// queue, so neither runs while the other is part way through.
sealed class FavouriteWriteEvent extends FavouriteToggleEvent {
  const FavouriteWriteEvent();
}

class ToggleFavouriteEvent extends FavouriteWriteEvent {
  final MealEntity meal;

  /// The profile active at the tap. The write may wait behind another one,
  /// and a profile switch in the meantime must not land it on the new
  /// profile.
  final ProfileStamp startedOn;

  ToggleFavouriteEvent(this.meal, {ProfileStamp? startedOn})
    : startedOn = startedOn ?? ProfileStamp.now();

  @override
  List<Object?> get props => [meal];
}

/// The star's food was hydrated to its full record (an Open Food Facts
/// search result whose detail page fetched the product), so a favourite on
/// it should keep the full record rather than the thin one.
class FavouriteMealHydratedEvent extends FavouriteWriteEvent {
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
