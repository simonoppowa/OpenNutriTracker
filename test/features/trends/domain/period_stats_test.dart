import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/features/trends/domain/period_stats.dart';

TrackedDayEntity _day(
  DateTime day, {
  double kcal = 2000,
  double kcalGoal = 2000,
  double? carbs = 250,
  double? fat = 70,
  double? protein = 100,
  double? carbsGoal = 250,
  double? fatGoal = 70,
  double? proteinGoal = 100,
}) => TrackedDayEntity(
  day: day,
  calorieGoal: kcalGoal,
  caloriesTracked: kcal,
  carbsGoal: carbsGoal,
  carbsTracked: carbs,
  fatGoal: fatGoal,
  fatTracked: fat,
  proteinGoal: proteinGoal,
  proteinTracked: protein,
);

void main() {
  final start = DateTime(2026, 10, 12);
  final end = DateTime(2026, 10, 18);

  test('an empty period has no averages and only untracked days', () {
    final stats = periodStats(
      start: start,
      end: end,
      days: const [],
      waterByDay: const {},
    );

    expect(stats.totalDays, 7);
    expect(stats.trackedDays, 0);
    expect(stats.untrackedDays, 7);
    expect(stats.avgKcal, isNull);
    expect(stats.avgWaterMl, isNull);
    expect(stats.kcalOnTargetDays, 0);
  });

  test('untracked days do not pull the averages down', () {
    final stats = periodStats(
      start: start,
      end: end,
      days: [
        _day(DateTime(2026, 10, 12), kcal: 1800, protein: 90),
        _day(DateTime(2026, 10, 15), kcal: 2200, protein: 110),
      ],
      waterByDay: const {},
    );

    expect(stats.trackedDays, 2);
    expect(stats.untrackedDays, 5);
    expect(stats.avgKcal, 2000);
    expect(stats.avgProtein, 100);
    expect(stats.avgCarbs, 250);
  });

  test('a day row with nothing eaten counts as untracked', () {
    final stats = periodStats(
      start: start,
      end: end,
      days: [
        _day(DateTime(2026, 10, 12), kcal: 0, carbs: 0, fat: 0, protein: 0),
      ],
      waterByDay: const {},
    );

    expect(stats.trackedDays, 0);
    expect(stats.avgKcal, isNull);
  });

  test('days outside the period are left out, whatever their time of day', () {
    final stats = periodStats(
      start: start,
      end: end,
      days: [
        _day(DateTime(2026, 10, 11, 23, 59), kcal: 9999),
        _day(DateTime(2026, 10, 12, 0, 0, 1), kcal: 1500),
        _day(DateTime(2026, 10, 18, 21, 30), kcal: 2500),
        _day(DateTime(2026, 10, 19, 0, 1), kcal: 9999),
      ],
      waterByDay: const {},
    );

    expect(stats.trackedDays, 2);
    expect(stats.avgKcal, 2000);
  });

  test('water counts on days without food, but not as a tracked day', () {
    final stats = periodStats(
      start: start,
      end: end,
      days: [_day(DateTime(2026, 10, 12))],
      waterByDay: {
        DateTime(2026, 10, 12): 2000,
        DateTime(2026, 10, 13): 1000,
        DateTime(2026, 10, 20): 5000,
      },
    );

    expect(stats.trackedDays, 1);
    expect(stats.waterDays, 2);
    expect(stats.avgWaterMl, 1500);
  });

  group('goals met', () {
    test('kcal within the tolerance band of the day\'s own goal', () {
      final stats = periodStats(
        start: start,
        end: end,
        days: [
          _day(DateTime(2026, 10, 12), kcal: 2200, kcalGoal: 2000),
          _day(DateTime(2026, 10, 13), kcal: 2201, kcalGoal: 2000),
          _day(DateTime(2026, 10, 14), kcal: 1800, kcalGoal: 2000),
          _day(DateTime(2026, 10, 15), kcal: 1500, kcalGoal: 1500),
        ],
        waterByDay: const {},
      );

      expect(stats.kcalOnTargetDays, 3);
    });

    test('macros count when all three are within the band', () {
      final stats = periodStats(
        start: start,
        end: end,
        days: [
          _day(DateTime(2026, 10, 12)),
          _day(DateTime(2026, 10, 13), protein: 80),
          _day(DateTime(2026, 10, 14), carbsGoal: null),
        ],
        waterByDay: const {},
      );

      expect(stats.macrosOnTargetDays, 1);
      expect(stats.macroGoalDays, 2);
    });

    test('the tolerance can be set', () {
      final days = [_day(DateTime(2026, 10, 12), kcal: 2150, kcalGoal: 2000)];

      expect(
        periodStats(
          start: start,
          end: end,
          days: days,
          waterByDay: const {},
          tolerance: 0.05,
        ).kcalOnTargetDays,
        0,
      );
      expect(
        periodStats(
          start: start,
          end: end,
          days: days,
          waterByDay: const {},
        ).kcalOnTargetDays,
        1,
      );
    });
  });

  test('a period ending before it starts is empty', () {
    final stats = periodStats(
      start: end,
      end: start,
      days: [_day(DateTime(2026, 10, 15))],
      waterByDay: const {},
    );

    expect(stats.totalDays, 0);
    expect(stats.trackedDays, 0);
  });

  test('a period across the daylight saving change counts every day', () {
    final stats = periodStats(
      start: DateTime(2026, 3, 23),
      end: DateTime(2026, 3, 30),
      days: const [],
      waterByDay: const {},
    );

    expect(stats.totalDays, 8);
  });
}
