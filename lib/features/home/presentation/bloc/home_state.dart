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
  final double totalKcalSupplied;
  final List<IntakeEntity> breakfastIntakeList;
  final List<IntakeEntity> lunchIntakeList;
  final List<IntakeEntity> dinnerIntakeList;
  final List<IntakeEntity> snackIntakeList;

  const HomeLoadedState({
    required this.totalKcalSupplied,
    required this.breakfastIntakeList,
    required this.lunchIntakeList,
    required this.dinnerIntakeList,
    required this.snackIntakeList,
  });

  @override
  List<Object?> get props => [
        breakfastIntakeList,
        lunchIntakeList,
        dinnerIntakeList,
        snackIntakeList
      ];
}
