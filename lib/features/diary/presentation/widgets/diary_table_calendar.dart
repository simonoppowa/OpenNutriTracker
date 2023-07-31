import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:table_calendar/table_calendar.dart';

class DiaryTableCalendar extends StatefulWidget {
  final Function(DateTime, Map<String, TrackedDayEntity>) onDateSelected;
  final Duration calendarDurationDays;
  final DateTime focusedDate;
  final DateTime currentDate;
  final DateTime selectedDate;

  final Map<String, TrackedDayEntity> trackedDaysMap;

  const DiaryTableCalendar(
      {Key? key,
      required this.onDateSelected,
      required this.calendarDurationDays,
      required this.focusedDate,
      required this.currentDate,
      required this.selectedDate,
      required this.trackedDaysMap})
      : super(key: key);

  @override
  State<DiaryTableCalendar> createState() => _DiaryTableCalendarState();
}

class _DiaryTableCalendarState extends State<DiaryTableCalendar> {
  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      headerStyle:
          const HeaderStyle(titleCentered: true, formatButtonVisible: false),
      focusedDay: widget.focusedDate,
      firstDay: widget.currentDate.subtract(widget.calendarDurationDays),
      lastDay: widget.currentDate.add(widget.calendarDurationDays),
      startingDayOfWeek: StartingDayOfWeek.monday,
      onDaySelected: (selectedDay, focusedDay) {
        widget.onDateSelected(selectedDay, widget.trackedDaysMap);
      },
      calendarStyle: CalendarStyle(
          markersMaxCount: 1,
          todayTextStyle:
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          todayDecoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.onBackground,
                  width: 2.0),
              shape: BoxShape.circle),
          selectedTextStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onPrimary) ??
              const TextStyle(),
          selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle)),
      selectedDayPredicate: (day) => isSameDay(widget.selectedDate, day),
      calendarBuilders:
          CalendarBuilders(markerBuilder: (context, date, events) {
        final trackedDay = widget.trackedDaysMap[date.toParsedDay()];
        if (trackedDay != null) {
          return Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: trackedDay.getCalendarDayRatingColor(context)),
            width: 5.0,
            height: 5.0,
          );
        } else {
          return const SizedBox();
        }
      }),
    );
  }
}
