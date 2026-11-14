part of 'recipe_meal_bloc.dart';

abstract class RecipeMealState extends Equatable {
  const RecipeMealState();
}

class RecipeMealInitial extends RecipeMealState {
  @override
  List<Object?> get props => [];
}

class RecipeMealLoadingState extends RecipeMealState {
  @override
  List<Object?> get props => [];
}

class RecipeMealLoadedState extends RecipeMealState {
  /// Each recipe as search shows it ([RecipeEntity.toMealEntity]), A to Z.
  final List<MealEntity> recipes;
  final bool usesImperialUnits;

  /// Makes every load a new state. MealEntity == compares code and name
  /// only, so a reload after a recipe's nutrition was edited would equal
  /// the last state, the bloc would drop it, and a tap would open the
  /// detail page with the old numbers.
  final Object _load = Object();

  RecipeMealLoadedState({
    required this.recipes,
    this.usesImperialUnits = false,
  });

  @override
  List<Object?> get props => [_load];
}

class RecipeMealFailedState extends RecipeMealState {
  @override
  List<Object?> get props => [];
}
