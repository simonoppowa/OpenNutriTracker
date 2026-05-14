part of 'calendar_day_bloc.dart';

abstract class CalendarDayState extends Equatable {
  const CalendarDayState();
}

class CalendarDayInitial extends CalendarDayState {
  @override
  List<Object> get props => [];
}

class CalendarDayLoading extends CalendarDayState {
  @override
  List<Object?> get props => [];
}

class CalendarDayLoaded extends CalendarDayState {
  final TrackedDayEntity? trackedDayEntity;
  final List<UserActivityEntity> userActivityList;
  final List<IntakeEntity> breakfastIntakeList;
  final List<IntakeEntity> lunchIntakeList;
  final List<IntakeEntity> dinnerIntakeList;
  final List<IntakeEntity> snackIntakeList;
  // Persisted per-meal sort preference, keyed by meal type string
  // (breakfast / lunch / dinner / snack) and valued by DiarySortType index.
  // Null when the user has never picked a sort, in which case the diary
  // falls back to DiarySortType.timeAdded.
  final Map<String, int>? diarySortPreferences;

  const CalendarDayLoaded(
    this.trackedDayEntity,
    this.userActivityList,
    this.breakfastIntakeList,
    this.lunchIntakeList,
    this.dinnerIntakeList,
    this.snackIntakeList, {
    this.diarySortPreferences,
  });

  @override
  List<Object?> get props => [trackedDayEntity, diarySortPreferences];
}
