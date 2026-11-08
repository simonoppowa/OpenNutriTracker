part of 'add_meal_bloc.dart';

abstract class AddMealState extends Equatable {
  const AddMealState();
}

class AddMealInitialState extends AddMealState {
  const AddMealInitialState();

  @override
  List<Object?> get props => [];
}

class AddMealLoadingState extends AddMealState {
  const AddMealLoadingState();

  @override
  List<Object?> get props => [];
}

class AddMealLoadedState extends AddMealState {
  final bool usesImperialUnits;

  /// #1126: whether the user prefers grams/oz over a food's serving. The
  /// + on a search result picks its amount by the same rule as the detail
  /// screen, so it needs the same setting.
  final bool defaultToRawFoodUnits;

  const AddMealLoadedState({
    this.usesImperialUnits = false,
    this.defaultToRawFoodUnits = false,
  });

  @override
  List<Object?> get props => [usesImperialUnits, defaultToRawFoodUnits];
}
