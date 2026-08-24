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

/// What one line of [style] actually needs at the current text scale.
///
/// Measured rather than scaled from the package's 16.0: that constant only
/// equals a heading's height by coincidence — it is `labelSmall`'s line
/// height today — and scaling it lands fractionally short at some scales
/// (20.8 against the 21.0 wanted at 1.3x), which clips just as surely.
double _weekdayRowHeight(BuildContext context, TextStyle style) =>
    (TextPainter(
      // Any single line measures the same: the height comes from the font's
      // metrics, not from which glyphs are in it.
      text: TextSpan(text: 'Mon', style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout())
        .height;

class _DiaryTableCalendarState extends State<DiaryTableCalendar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    final weekdayStyle =
        textTheme.labelSmall?.copyWith(color: palette.textMuted) ??
            const TextStyle();

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
            weekdayStyle: weekdayStyle,
            weekendStyle: weekdayStyle,
          ),
          // The package default is a flat 16.0, and `labelSmall` is 11sp on a
          // 1.45 line height — exactly 16 logical pixels. So the row has no
          // slack at all at the default text size, and every step above it
          // cuts the headings: 21px of text in 16 at 1.3x, 32 in 16 at 2x.
          //
          // Nothing throws and no overflow stripes appear, because each
          // heading sits in a `SizedBox` of this height, and a tight
          // constraint squeezes its child rather than overflowing (#766).
          daysOfWeekHeight: _weekdayRowHeight(context, weekdayStyle),
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
