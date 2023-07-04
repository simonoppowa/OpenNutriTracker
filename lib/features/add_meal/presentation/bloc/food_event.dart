part of 'food_bloc.dart';

abstract class FoodEvent extends Equatable {
  const FoodEvent();

  @override
  List<Object?> get props => [];
}

class LoadFoodEvent extends FoodEvent {
  final String searchString;

  const LoadFoodEvent({required this.searchString});

  @override
  List<Object?> get props => [searchString];
}

class RefreshFoodEvent extends FoodEvent {
  const RefreshFoodEvent();

  @override
  List<Object?> get props => [];
}
