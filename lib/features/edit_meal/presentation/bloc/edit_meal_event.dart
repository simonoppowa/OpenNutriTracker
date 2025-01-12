part of 'edit_meal_bloc.dart';

abstract class EditMealEvent extends Equatable {
  const EditMealEvent();
}

class InitializeEditMealEvent extends EditMealEvent {

  const InitializeEditMealEvent();

  @override
  List<Object?> get props => [];
}
