part of 'recent_activities_bloc.dart';

abstract class RecentActivitiesEvent extends Equatable {
  const RecentActivitiesEvent();
}
class LoadRecentActivitiesEvent extends RecentActivitiesEvent {
  final BuildContext context;

  const LoadRecentActivitiesEvent({required this.context});

  @override
  List<Object?> get props => [];
}
