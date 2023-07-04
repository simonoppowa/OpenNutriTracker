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

  const FoodLoadedState({required this.food});

  @override
  List<Object?> get props => [food];
}

class FoodFailedState extends FoodState {
  @override
  List<Object?> get props => [];
}
