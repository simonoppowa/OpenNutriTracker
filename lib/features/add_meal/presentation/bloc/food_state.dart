part of 'food_bloc.dart';

abstract class FoodState extends Equatable {
  const FoodState();
}

class FoodInitial extends FoodState {
  @override
  List<Object> get props => [];
}

class FoodLoadingState extends FoodState {
  @override
  List<Object?> get props => [];
}

class FoodLoadedState extends FoodState {
  final List<MealEntity> food;
  final bool usesImperialUnits;

  /// True when the remote FDC source returned zero results (or failed
  /// silently — e.g. rate limit). The UI uses this to show a "no results"
  /// hint below any custom-meal matches.
  final bool remoteSourceEmpty;

  /// True when the remote FDC source threw (timeout, rate limit, network)
  /// rather than answering — the use case still returns local matches, so
  /// this is a loaded state, but the "All" view flags the gap.
  final bool remoteSourceFailed;

  /// The raw search input these results answer — see
  /// ProductsLoadedState.query for how the UI uses it.
  final String query;

  const FoodLoadedState({
    required this.food,
    this.usesImperialUnits = false,
    this.remoteSourceEmpty = false,
    this.remoteSourceFailed = false,
    this.query = '',
  });

  @override
  List<Object?> get props =>
      [food, usesImperialUnits, remoteSourceEmpty, remoteSourceFailed, query];
}

class FoodFailedState extends FoodState {
  @override
  List<Object?> get props => [];
}
