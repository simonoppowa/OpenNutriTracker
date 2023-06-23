part of 'recent_activities_bloc.dart';

abstract class RecentActivitiesState extends Equatable {
  const RecentActivitiesState();
}

class RecentActivitiesInitial extends RecentActivitiesState {
  @override
  List<Object> get props => [];
}

class RecentActivitiesLoadingState extends RecentActivitiesState {
  @override
  List<Object?> get props => [];
}

class RecentActivitiesLoadedState extends RecentActivitiesState {
  final List<PhysicalActivityEntity> recentActivities;

  const RecentActivitiesLoadedState({required this.recentActivities});

  @override
  List<Object?> get props => [recentActivities];
}

class RecentActivitiesFailedState extends RecentActivitiesState {
  @override
  List<Object?> get props => [];
}
