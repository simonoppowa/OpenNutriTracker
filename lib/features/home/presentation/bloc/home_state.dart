part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
}

class HomeInitial extends HomeState {
  @override
  List<Object> get props => [];
}

class HomeLoadingState extends HomeState {
  @override
  List<Object?> get props => [];
}

class HomeLoadedState extends HomeState {
  final List<IntakeEntity> breakfastIntakeList;

  const HomeLoadedState({required this.breakfastIntakeList});

  @override
  List<Object?> get props => [breakfastIntakeList];
}
