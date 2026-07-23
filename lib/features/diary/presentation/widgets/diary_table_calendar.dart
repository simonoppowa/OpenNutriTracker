import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:table_calendar/table_calendar.dart';

class DiaryTableCalendar extends StatefulWidget {
  final Function(DateTime, Map<String, TrackedDayEntity>) onDateSelected;
  final Duration calendarDurationDays;
  final DateTime focusedDate;
  final DateTime currentDate;
  final DateTime selectedDate;

  final Map<String, TrackedDayEntity> trackedDaysMap;

  const DiaryTableCalendar({
    super.key,
    required this.onDateSelected,
    required this.calendarDurationDays,
    required this.focusedDate,
    required this.currentDate,
    required this.selectedDate,
    required this.trackedDaysMap,
  });

  @override
  State<DiaryTableCalendar> createState() => _DiaryTableCalendarState();
}

class _DiaryTableCalendarState extends State<DiaryTableCalendar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing8,
        Dimens.spacing16,
        Dimens.spacing4,
      ),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          Dimens.spacing8,
          Dimens.spacing12,
          Dimens.spacing8,
          Dimens.spacing12,
        ),
        child: TableCalendar(
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textStrong,
                ) ??
                const TextStyle(),
            leftChevronIcon: Icon(Icons.chevron_left_rounded, color: palette.textMuted, size: 26),
            rightChevronIcon: Icon(Icons.chevron_right_rounded, color: palette.textMuted, size: 26),
            headerPadding: const EdgeInsets.symmetric(vertical: Dimens.spacing8),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: textTheme.labelSmall?.copyWith(color: palette.textMuted) ?? const TextStyle(),
            weekendStyle: textTheme.labelSmall?.copyWith(color: palette.textMuted) ?? const TextStyle(),
          ),
          focusedDay: widget.focusedDate,
          firstDay: widget.currentDate.subtract(widget.calendarDurationDays),
          lastDay: widget.currentDate.add(widget.calendarDurationDays),
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: (selectedDay, focusedDay) {
            widget.onDateSelected(selectedDay, widget.trackedDaysMap);
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 1,
            defaultTextStyle: textTheme.bodyMedium?.copyWith(color: palette.textStrong) ?? const TextStyle(),
            weekendTextStyle: textTheme.bodyMedium?.copyWith(color: palette.textStrong) ?? const TextStyle(),
            outsideTextStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted) ?? const TextStyle(),
            todayTextStyle: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ) ??
                const TextStyle(),
            todayDecoration: BoxDecoration(
              border: Border.all(color: accent, width: 2.0),
              shape: BoxShape.circle,
            ),
            selectedTextStyle: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimary,
                ) ??
                const TextStyle(),
            selectedDecoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          selectedDayPredicate: (day) => isSameDay(widget.selectedDate, day),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final trackedDay = widget.trackedDaysMap[date.toParsedDay()];
              if (trackedDay != null) {
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: trackedDay.getCalendarDayRatingColor(context),
                  ),
                  width: 5.0,
                  height: 5.0,
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ),
      ),
    );
  }
}
