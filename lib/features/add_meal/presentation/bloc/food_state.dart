part of 'food_bloc.dart';

abstract class FoodState extends Equatable {
  const FoodState();
}

class FoodInitial extends FoodState {
  @override
  List<Object> get props => [];
}

class FoodLoadingState extends FoodState {
  @override
  List<Object?> get props => [];
}

class FoodLoadedState extends FoodState {
  final List<MealEntity> food;
  final bool usesImperialUnits;

  const FoodLoadedState({required this.food, this.usesImperialUnits = false});

  @override
  List<Object?> get props => [food, usesImperialUnits];
}

class FoodFailedState extends FoodState {
  @override
  List<Object?> get props => [];
}
