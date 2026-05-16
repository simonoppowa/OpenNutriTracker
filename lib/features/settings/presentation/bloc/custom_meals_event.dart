part of 'custom_meals_bloc.dart';

abstract class CustomMealsEvent {}

class LoadCustomMealsEvent extends CustomMealsEvent {}

class DeleteCustomMealEvent extends CustomMealsEvent {
  final String mealKey;

  DeleteCustomMealEvent(this.mealKey);
}

/// Folds [loserKey]'s diary entries into [winnerKey] and drops the loser
/// from the saved-meals list. Both keys are `meal.code ?? meal.name`.
class MergeCustomMealsEvent extends CustomMealsEvent {
  final String loserKey;
  final String winnerKey;

  MergeCustomMealsEvent({required this.loserKey, required this.winnerKey});
}
