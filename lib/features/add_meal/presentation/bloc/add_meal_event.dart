part of 'add_meal_bloc.dart';

abstract class AddMealEvent extends Equatable {
  const AddMealEvent();
}

class InitializeAddMealEvent extends AddMealEvent {
  const InitializeAddMealEvent();

  @override
  List<Object?> get props => [];
}
