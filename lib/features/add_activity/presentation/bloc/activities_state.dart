part of 'activities_bloc.dart';

abstract class ActivitiesState extends Equatable {
  const ActivitiesState();
}

class ActivitiesInitial extends ActivitiesState {
  @override
  List<Object> get props => [];
}

class ActivitiesLoadingState extends ActivitiesState {
  @override
  List<Object?> get props => [];
}

class ActivitiesLoadedState extends ActivitiesState {
  final List<PhysicalActivityEntity> activities;

  const ActivitiesLoadedState({required this.activities});

  @override
  List<Object?> get props => [activities];
}

class ActivitiesFailedState extends ActivitiesState {
  @override
  List<Object?> get props => [];
}
