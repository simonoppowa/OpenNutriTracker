part of 'recent_meal_bloc.dart';

abstract class RecentMealEvent extends Equatable {
  const RecentMealEvent();
}

/// Reads recent history from storage, then filters it by [searchString].
/// Fired on open, submit, chip taps and Retry.
class LoadRecentMealEvent extends RecentMealEvent {
  final String searchString;

  /// an empty `searchString` will load all RecentMeal
  const LoadRecentMealEvent({required this.searchString});

  @override
  List<Object?> get props => [];
}

/// Search-as-you-type over recent history, fired on every keystroke.
/// Filters the history already in memory and only reads storage when
/// nothing has been loaded yet.
class RecentMealSearchChangedEvent extends RecentMealEvent {
  final String searchString;

  const RecentMealSearchChangedEvent({required this.searchString});

  @override
  List<Object?> get props => [searchString];
}
