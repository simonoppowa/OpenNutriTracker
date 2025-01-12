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

  const AddMealLoadedState({this.usesImperialUnits = false});

  @override
  List<Object?> get props => [usesImperialUnits];
}
