import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:opennutritracker/core/data/data_source/health/health_package_service.dart';

/// A raw TOTAL_CALORIES_BURNED record as Health Connect reports it. The
/// plugin's data classes are plain Dart, so building them here exercises the
/// real attribution code without touching a platform channel.
HealthDataPoint _calories({
  required String source,
  required DateTime start,
  Duration duration = const Duration(minutes: 15),
  required num kcal,
  HealthDataUnit unit = HealthDataUnit.KILOCALORIE,
}) => HealthDataPoint(
  uuid: '$source-${start.toIso8601String()}',
  value: NumericHealthValue(numericValue: kcal),
  type: HealthDataType.TOTAL_CALORIES_BURNED,
  unit: unit,
  dateFrom: start,
  dateTo: start.add(duration),
  sourcePlatform: HealthPlatformType.googleHealthConnect,
  sourceDeviceId: 'device',
  sourceId: 'source',
  sourceName: source,
);

void main() {
  // The session window all tests attribute against.
  final start = DateTime(2026, 8, 13, 18, 0);
  final end = DateTime(2026, 8, 13, 19, 0);

  double? energy({
    String sourceName = 'com.hevy.app',
    required List<HealthDataPoint> calorieRecords,
  }) => HealthPackageService.androidWorkoutEnergyKcal(
    start: start,
    end: end,
    sourceName: sourceName,
    calorieRecords: calorieRecords,
  );

  group('HealthPackageService.androidWorkoutEnergyKcal', () {
    test('sums only the session writer\'s records, not other sources\' '
        'overlapping ones', () {
      // The observed double-count: a gym session whose own app wrote its
      // calories, with a background 15-minute basal+activity stream running
      // through the same window. The workout is worth exactly what its own
      // app said.
      final records = [
        _calories(source: 'com.hevy.app', start: start, kcal: 430.3),
        _calories(source: 'com.fitbit.FitbitMobile', start: start, kcal: 170),
        _calories(
          source: 'com.fitbit.FitbitMobile',
          start: start.add(const Duration(minutes: 15)),
          kcal: 150,
        ),
      ];

      expect(energy(calorieRecords: records), closeTo(430.3, 0.001));
    });

    test('multiple records from the session writer are summed', () {
      final records = [
        _calories(source: 'com.hevy.app', start: start, kcal: 200),
        _calories(
          source: 'com.hevy.app',
          start: start.add(const Duration(minutes: 30)),
          kcal: 100.5,
        ),
      ];

      expect(energy(calorieRecords: records), closeTo(300.5, 0.001));
    });

    test('a record is in the window only when it starts there', () {
      final records = [
        // Starts a second early: overlaps the session but Health Connect's
        // startTime-based between() would not have counted it either.
        _calories(
          source: 'com.hevy.app',
          start: start.subtract(const Duration(seconds: 1)),
          kcal: 98,
        ),
        // Starts exactly at the session start: counted.
        _calories(source: 'com.hevy.app', start: start, kcal: 197.6),
        // Starts exactly at the session end: the window is half-open.
        _calories(source: 'com.hevy.app', start: end, kcal: 48),
      ];

      expect(energy(calorieRecords: records), closeTo(197.6, 0.001));
    });

    test('falls back to the largest single-source sum when the session '
        'writer logged no calories, never the cross-source total', () {
      // Session tracked in one app, calories written by two others: the
      // biggest per-source sum is the best single estimate, and adding the
      // sources together would double-count again.
      final records = [
        _calories(source: 'com.fitbit.FitbitMobile', start: start, kcal: 197.6),
        _calories(
          source: 'com.fitbit.FitbitMobile',
          start: start.add(const Duration(minutes: 15)),
          kcal: 48,
        ),
        _calories(
          source: 'com.google.android.apps.fitness',
          start: start,
          kcal: 120,
        ),
      ];

      expect(energy(calorieRecords: records), closeTo(245.6, 0.001));
    });

    test('no calorie records in the window means no energy', () {
      expect(energy(calorieRecords: const []), isNull);
      expect(
        energy(
          calorieRecords: [
            _calories(
              source: 'com.hevy.app',
              start: end.add(const Duration(hours: 1)),
              kcal: 300,
            ),
          ],
        ),
        isNull,
      );
    });

    test('each record\'s own unit is honoured', () {
      final records = [
        _calories(
          source: 'com.hevy.app',
          start: start,
          kcal: 418400, // joules
          unit: HealthDataUnit.JOULE,
        ),
      ];

      expect(energy(calorieRecords: records), closeTo(100, 0.001));
    });
  });
}
