part of 'calendar_day_bloc.dart';

abstract class CalendarDayEvent extends Equatable {
  const CalendarDayEvent();
}

class LoadCalendarDayEvent extends CalendarDayEvent {
  final DateTime day;
  final TrackedDayEntity? trackedDayEntity;

  const LoadCalendarDayEvent(this.day, this.trackedDayEntity);

  @override
  List<Object?> get props => [];
}
