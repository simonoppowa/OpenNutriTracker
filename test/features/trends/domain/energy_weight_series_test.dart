import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/features/trends/domain/energy_weight_series.dart';

TrackedDayEntity _day(DateTime day, double kcal, {double goal = 2000}) =>
    TrackedDayEntity(day: day, calorieGoal: goal, caloriesTracked: kcal);

WeightLogEntity _weight(DateTime date, double kg) =>
    WeightLogEntity(date: date, weightKg: kg);

void main() {
  final start = DateTime(2026, 10, 19);
  final end = DateTime(2026, 10, 25);

  test('one entry per day of the period, energy only where tracked', () {
    final series = energyWeightSeries(
      start: start,
      end: end,
      days: [
        _day(DateTime(2026, 10, 19, 8), 1800),
        _day(DateTime(2026, 10, 21), 0),
        _day(DateTime(2026, 10, 30), 3000),
      ],
      weight: const [],
    );

    expect(series.days, hasLength(7));
    expect(series.days.first.kcal, 1800);
    expect(series.days.first.kcalGoal, 2000);
    expect(series.days[1].kcal, isNull);
    expect(series.days[2].kcal, isNull, reason: 'nothing eaten');
    expect(series.days.last.day, DateTime(2026, 10, 25));
  });

  test('the trend smooths over the week before the period too', () {
    final series = energyWeightSeries(
      start: start,
      end: end,
      days: const [],
      weight: [
        _weight(DateTime(2026, 10, 15), 80),
        _weight(DateTime(2026, 10, 20), 78),
      ],
    );

    final points = series.weightSegments.expand((s) => s).toList();
    expect(points, hasLength(1));
    expect(points.single.day, DateTime(2026, 10, 20));
    expect(points.single.kg, 79);
  });

  test('a gap of more than a week breaks the weight line', () {
    final series = energyWeightSeries(
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 31),
      days: const [],
      weight: [
        _weight(DateTime(2026, 10, 1), 80),
        _weight(DateTime(2026, 10, 3), 80),
        _weight(DateTime(2026, 10, 20), 79),
        _weight(DateTime(2026, 10, 22), 79),
      ],
    );

    expect(series.weightSegments.map((s) => s.length), [2, 2]);
  });

  test('no weight in the period gives no line', () {
    final series = energyWeightSeries(
      start: start,
      end: end,
      days: const [],
      weight: [_weight(DateTime(2026, 9, 1), 80)],
    );

    expect(series.weightSegments, isEmpty);
  });

  test('days are calendar days across the clock change', () {
    final series = energyWeightSeries(
      start: DateTime(2026, 3, 23),
      end: DateTime(2026, 3, 30),
      days: const [],
      weight: const [],
    );

    expect(series.days, hasLength(8));
    expect(series.days.last.day, DateTime(2026, 3, 30));
  });
}
