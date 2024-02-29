part of 'recent_meal_bloc.dart';

abstract class RecentMealEvent extends Equatable {
  const RecentMealEvent();
}

class LoadRecentMealEvent extends RecentMealEvent {
  final String searchString;

  /// an empty `searchString` will load all RecentMeal
  const LoadRecentMealEvent({required this.searchString});

  @override
  List<Object?> get props => [];
}
