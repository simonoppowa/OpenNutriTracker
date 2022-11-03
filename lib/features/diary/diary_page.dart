import 'dart:math';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  static const _calendarDurationDays = Duration(days: 356);
  final _currentDate = DateTime.now();
  var _selectedDate = DateTime.now();
  var _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return getLoadedContent(context);
  }

  Widget getLoadedContent(BuildContext context) {
    return ListView(
      children: [
        TableCalendar(
          headerStyle: const HeaderStyle(
              titleCentered: true, formatButtonVisible: false),
          focusedDay: _focusedDate,
          firstDay: _currentDate.subtract(_calendarDurationDays),
          lastDay: _currentDate.add(_calendarDurationDays),
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
              _focusedDate = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
              markersMaxCount: 1,
              todayTextStyle:
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              todayDecoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.onBackground,
                      width: 2.0),
                  //color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle),
              selectedTextStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary) ??
                  const TextStyle(),
              selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle)),
          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
          calendarBuilders:
              CalendarBuilders(markerBuilder: (context, date, events) {
            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors
                      .primaries[Random().nextInt(Colors.primaries.length)]),
              width: 5.0,
              height: 5.0,
            );
          }),
        )
      ],
    );
  }
}
