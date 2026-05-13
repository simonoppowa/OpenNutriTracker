part of 'edit_meal_bloc.dart';

abstract class EditMealState extends Equatable {
  const EditMealState();
}

class EditMealInitial extends EditMealState {
  @override
  List<Object> get props => [];
}

class EditMealLoadingState extends EditMealState {
  @override
  List<Object?> get props => [];
}

class EditMealLoadedState extends EditMealState {
  final bool usesImperialUnits;
  final CustomMealFormMode formMode;

  const EditMealLoadedState({
    this.usesImperialUnits = false,
    this.formMode = CustomMealFormMode.simple,
  });

  @override
  List<Object?> get props => [usesImperialUnits, formMode];
}
