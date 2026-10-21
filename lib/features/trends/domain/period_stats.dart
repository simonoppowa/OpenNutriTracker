import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';

/// Averages and goals met over a period of whole days (#56).
///
/// A day counts as tracked when something with energy was logged on it; a
/// day row with nothing eaten and a day without a row are untracked and
/// leave the averages alone. Water is averaged over the days with water
/// logged, food or not. Goals are those each tracked day stored for itself.
class PeriodStats {
  final int totalDays;
  final int trackedDays;
  final int waterDays;
  final double? avgKcal;
  final double? avgCarbs;
  final double? avgFat;
  final double? avgProtein;
  final double? avgWaterMl;

  /// Tracked days whose energy lay within the tolerance of their goal.
  final int kcalOnTargetDays;

  /// Tracked days with a goal for each of the three macros.
  final int macroGoalDays;

  /// Of [macroGoalDays], those with all three macros within the tolerance.
  final int macrosOnTargetDays;

  const PeriodStats({
    required this.totalDays,
    required this.trackedDays,
    required this.waterDays,
    required this.avgKcal,
    required this.avgCarbs,
    required this.avgFat,
    required this.avgProtein,
    required this.avgWaterMl,
    required this.kcalOnTargetDays,
    required this.macroGoalDays,
    required this.macrosOnTargetDays,
  });

  int get untrackedDays => totalDays - trackedDays;
}

/// The [PeriodStats] of the days from [start] to [end], both included and
/// taken as calendar days whatever their time. [tolerance] is the share a
/// value may lie above or below its goal and still count as met.
PeriodStats periodStats({
  required DateTime start,
  required DateTime end,
  required List<TrackedDayEntity> days,
  required Map<DateTime, int> waterByDay,
  double tolerance = 0.10,
}) {
  final first = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  bool inPeriod(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return !date.isBefore(first) && !date.isAfter(last);
  }

  final totalDays = last.isBefore(first)
      ? 0
      : DateTime.utc(last.year, last.month, last.day)
                .difference(DateTime.utc(first.year, first.month, first.day))
                .inDays +
            1;
  final tracked = [
    for (final day in days)
      if (inPeriod(day.day) && day.caloriesTracked > 0) day,
  ];
  final water = [
    for (final MapEntry(key: date, value: ml) in waterByDay.entries)
      if (inPeriod(date) && ml > 0) ml,
  ];

  double? average(Iterable<double?> values) {
    final known = values.nonNulls.toList();
    return known.isEmpty ? null : known.reduce((a, b) => a + b) / known.length;
  }

  bool within(double? value, double? goal) =>
      value != null &&
      goal != null &&
      goal > 0 &&
      (value - goal).abs() <= goal * tolerance;

  final macroGoalDays = tracked.where(
    (d) => d.carbsGoal != null && d.fatGoal != null && d.proteinGoal != null,
  );

  return PeriodStats(
    totalDays: totalDays,
    trackedDays: tracked.length,
    waterDays: water.length,
    avgKcal: average(tracked.map((d) => d.caloriesTracked)),
    avgCarbs: average(tracked.map((d) => d.carbsTracked)),
    avgFat: average(tracked.map((d) => d.fatTracked)),
    avgProtein: average(tracked.map((d) => d.proteinTracked)),
    avgWaterMl: average(water.map((ml) => ml.toDouble())),
    kcalOnTargetDays: tracked
        .where((d) => within(d.caloriesTracked, d.calorieGoal))
        .length,
    macroGoalDays: macroGoalDays.length,
    macrosOnTargetDays: macroGoalDays
        .where(
          (d) =>
              within(d.carbsTracked, d.carbsGoal) &&
              within(d.fatTracked, d.fatGoal) &&
              within(d.proteinTracked, d.proteinGoal),
        )
        .length,
  );
}
