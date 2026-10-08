import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';

/// Today's calorie figures for the iOS home-screen widget.
///
/// The widget extension cannot open the encrypted Hive database, so the
/// app writes this snapshot into the shared App Group whenever Home
/// finishes loading. Kilocalories are the stored unit. The in-app
/// kilojoule display preference is not applied here.
class CalorieWidgetSnapshot {
  static const appGroupId = 'group.com.opennutritracker.ont.opennutritracker';
  static const iosWidgetKind = 'CalorieProgressWidget';

  static const hasDataKey = 'ont_calorie_has_data';
  static const dayKey = 'ont_calorie_day';
  static const offsetKey = 'ont_calorie_offset_minutes';
  static const consumedKey = 'ont_calorie_consumed';
  static const goalKey = 'ont_calorie_goal';

  final bool hasData;
  final String dayId;
  final int offsetMinutes;
  final int consumedKcal;
  final int goalKcal;

  const CalorieWidgetSnapshot({
    required this.hasData,
    required this.dayId,
    required this.offsetMinutes,
    required this.consumedKcal,
    required this.goalKcal,
  });

  /// Builds the snapshot Home should publish.
  ///
  /// [consumedKcal] is today's supplied intake and [goalKcal] is the
  /// daily goal, both already computed by Home. A goal of zero, or a
  /// negative goal, means there is no profile figure to show.
  factory CalorieWidgetSnapshot.fromHome({
    required double consumedKcal,
    required double goalKcal,
    required int offsetMinutes,
    DateTime? now,
  }) {
    final offset = sanitiseOffsetMinutes(offsetMinutes);
    final moment = now ?? DateTime.now();
    final logicalDay = DayBoundaryCalc.logicalDayOfMinutes(moment, offset);
    final goal = goalKcal.round();
    final hasData = goal > 0;
    return CalorieWidgetSnapshot(
      hasData: hasData,
      dayId: formatDayId(logicalDay),
      offsetMinutes: offset,
      consumedKcal: hasData ? consumedKcal.round() : 0,
      goalKcal: hasData ? goal : 0,
    );
  }

  /// True when this snapshot still belongs to the logical day of [moment].
  bool isCurrentAt(DateTime moment) {
    if (!hasData || dayId.isEmpty) return false;
    final logicalDay = DayBoundaryCalc.logicalDayOfMinutes(
      moment,
      offsetMinutes,
    );
    return dayId == formatDayId(logicalDay);
  }

  /// Wall-clock instant when this logical day ends and the widget should
  /// drop yesterday's numbers.
  DateTime nextBoundary() {
    final parts = dayId.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final start = DateTime(year, month, day);
    return start.add(Duration(days: 1, minutes: offsetMinutes));
  }

  Map<String, String> toPayload() => {
    hasDataKey: hasData ? '1' : '0',
    dayKey: dayId,
    offsetKey: '$offsetMinutes',
    consumedKey: '$consumedKcal',
    goalKey: '$goalKcal',
  };

  static int sanitiseOffsetMinutes(int offsetMinutes) {
    if (offsetMinutes < 0 || offsetMinutes >= 24 * 60) return 0;
    return offsetMinutes;
  }

  static String formatDayId(DateTime day) {
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '$year-$month-$dayOfMonth';
  }
}
