part of 'recent_meal_bloc.dart';

abstract class RecentMealState extends Equatable {
  const RecentMealState();
}

class RecentMealInitial extends RecentMealState {
  @override
  List<Object> get props => [];
}

class RecentMealLoadingState extends RecentMealState {
  @override
  List<Object?> get props => [];
}

class RecentMealLoadedState extends RecentMealState {
  final List<MealEntity> recentMeals;

  const RecentMealLoadedState({required this.recentMeals});

  @override
  List<Object?> get props => [recentMeals];
}

class RecentMealFailedState extends RecentMealState {
  @override
  List<Object?> get props => [];
}
