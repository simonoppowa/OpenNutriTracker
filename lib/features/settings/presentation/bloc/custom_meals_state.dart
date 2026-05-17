part of 'custom_meals_bloc.dart';

abstract class CustomMealsState {}

class CustomMealsInitial extends CustomMealsState {}

class CustomMealsLoadingState extends CustomMealsState {}

class CustomMealsLoadedState extends CustomMealsState {
  final List<MealEntity> meals;

  CustomMealsLoadedState({required this.meals});
}

class CustomMealsFailedState extends CustomMealsState {}

/// Emitted after a successful merge so the UI can surface a snackbar
/// referencing the survivor and the count of rewritten diary entries.
/// Extends [CustomMealsLoadedState] so existing list-rendering code keeps
/// working without a new branch in the BlocBuilder.
class CustomMealsMergedState extends CustomMealsLoadedState {
  final int rewrittenIntakeCount;
  final String winnerDisplayName;

  CustomMealsMergedState({
    required super.meals,
    required this.rewrittenIntakeCount,
    required this.winnerDisplayName,
  });
}
