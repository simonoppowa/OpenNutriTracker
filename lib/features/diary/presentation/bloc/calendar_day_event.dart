part of 'calendar_day_bloc.dart';

abstract class CalendarDayEvent extends Equatable {
  const CalendarDayEvent();
}

class LoadCalendarDayEvent extends CalendarDayEvent {
  final BuildContext context;
  final DateTime day;

  const LoadCalendarDayEvent(this.context, this.day);

  @override
  List<Object?> get props => [];
}
