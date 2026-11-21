part of 'recipe_meal_bloc.dart';

abstract class RecipeMealEvent extends Equatable {
  const RecipeMealEvent();
}

class LoadRecipeMealEvent extends RecipeMealEvent {
  final String searchString;

  /// An empty `searchString` loads every recipe.
  const LoadRecipeMealEvent({required this.searchString});

  @override
  List<Object?> get props => [searchString];
}

class _RecipesChangedEvent extends RecipeMealEvent {
  const _RecipesChangedEvent();

  @override
  List<Object?> get props => [];
}
