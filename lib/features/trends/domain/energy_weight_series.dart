import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/utils/calc/weight_moving_average.dart';

/// One day of the energy and weight comparison (#58).
class EnergyWeightDay {
  final DateTime day;

  /// The energy logged, null on a day without entries.
  final double? kcal;

  /// The energy goal the day stored, null without a tracked day.
  final double? kcalGoal;

  const EnergyWeightDay({required this.day, this.kcal, this.kcalGoal});
}

/// A point of the smoothed weight trend.
typedef WeightTrendPoint = ({DateTime day, double kg});

/// The data of the energy and weight chart: every day of the period and the
/// weight trend split into the segments the line is drawn in.
class EnergyWeightSeries {
  final List<EnergyWeightDay> days;
  final List<List<WeightTrendPoint>> weightSegments;

  const EnergyWeightSeries({required this.days, required this.weightSegments});
}

/// Readings further apart than this break the weight line instead of
/// bridging the gap.
const maxWeightGapDays = 7;

/// The [EnergyWeightSeries] of the days from [start] to [end] (#58).
///
/// Energy counts only on days with something eaten. The weight trend is
/// the 7-day moving average of the whole log ([WeightMovingAverage], see
/// `docs/weight-trend.md`), so the first days of the period are smoothed
/// with the readings before it; it is kept on the reading days inside the
/// period.
EnergyWeightSeries energyWeightSeries({
  required DateTime start,
  required DateTime end,
  required List<TrackedDayEntity> days,
  required List<WeightLogEntity> weight,
}) {
  DateTime date(DateTime d) => DateTime(d.year, d.month, d.day);
  final first = date(start);
  final last = date(end);
  final byDay = {for (final d in days) date(d.day): d};

  final series = <EnergyWeightDay>[];
  for (
    var day = first;
    !day.isAfter(last);
    day = DateTime(day.year, day.month, day.day + 1)
  ) {
    final tracked = byDay[day];
    series.add(
      EnergyWeightDay(
        day: day,
        kcal: tracked != null && tracked.caloriesTracked > 0
            ? tracked.caloriesTracked
            : null,
        kcalGoal: tracked?.calorieGoal,
      ),
    );
  }

  final segments = <List<WeightTrendPoint>>[];
  WeightTrendPoint? previous;
  for (final point in const WeightMovingAverage().compute(
    weight,
    minSamples: 1,
  )) {
    final day = date(point.date);
    if (day.isBefore(first) || day.isAfter(last)) continue;
    final gap = previous == null
        ? 0
        : DateTime.utc(day.year, day.month, day.day)
              .difference(
                DateTime.utc(
                  previous.day.year,
                  previous.day.month,
                  previous.day.day,
                ),
              )
              .inDays;
    if (previous == null || gap > maxWeightGapDays) segments.add([]);
    final current = (day: day, kg: point.weightKg);
    segments.last.add(current);
    previous = current;
  }

  return EnergyWeightSeries(days: series, weightSegments: segments);
}
