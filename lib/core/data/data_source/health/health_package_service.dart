import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';

/// [HealthService] backed by the `health` plugin — Health Connect on
/// Android, HealthKit on iOS.
///
/// Deliberately free of business logic: it asks for the two data types the
/// feature needs, hands back plain [ExternalWorkout] records, and leaves
/// every decision about what to do with them to the import use case.
class HealthPackageService implements HealthService {
  /// Read-only, and only these two: workouts to import, body fat to
  /// personalise the calorie-credit suggestion. Nothing is ever written back.
  static const _readTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.BODY_FAT_PERCENTAGE,
  ];

  /// How far back to look for the latest body fat reading. A year is long
  /// enough that a user who steps on a smart scale occasionally still gets a
  /// personalised suggestion, and short enough that a stale composition from
  /// several years ago doesn't drive it.
  static const _bodyFatLookback = Duration(days: 365);

  final _log = Logger('HealthPackageService');
  final Health _health;

  HealthPackageService(this._health);

  /// Builds a configured service. [Health.configure] resolves the device id
  /// and has to run before any query, so it happens here rather than lazily
  /// on the first import.
  static Future<HealthPackageService> create() async {
    final health = Health();
    await health.configure();
    return HealthPackageService(health);
  }

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    return await _health.isHealthConnectAvailable();
  }

  @override
  Future<bool> requestPermissions() async {
    return await _health.requestAuthorization(
      _readTypes,
      permissions: List.filled(_readTypes.length, HealthDataAccess.READ),
    );
  }

  @override
  Future<List<ExternalWorkout>> readWorkouts({
    required DateTime from,
    required DateTime to,
  }) async {
    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WORKOUT],
      startTime: from,
      endTime: to,
    );
    final workouts = <ExternalWorkout>[];
    for (final point in points) {
      final value = point.value;
      if (value is! WorkoutHealthValue) {
        // The platform answered a WORKOUT query with something that isn't a
        // workout — worth knowing about, not worth failing the import over.
        _log.warning(
          'Skipping health point ${point.uuid}: expected a workout value, '
          'got ${value.runtimeType}',
        );
        continue;
      }
      workouts.add(
        ExternalWorkout(
          id: point.uuid,
          start: point.dateFrom,
          end: point.dateTo,
          activityTypeName: value.workoutActivityType.name,
          energyBurnedKcal: _energyInKcal(
            value.totalEnergyBurned,
            value.totalEnergyBurnedUnit,
          ),
          sourceAppName: point.sourceName,
        ),
      );
    }
    return workouts;
  }

  @override
  Future<double?> readLatestBodyFatPercent() async {
    final now = DateTime.now();
    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.BODY_FAT_PERCENTAGE],
      startTime: now.subtract(_bodyFatLookback),
      endTime: now,
    );
    HealthDataPoint? latest;
    for (final point in points) {
      if (latest == null || point.dateTo.isAfter(latest.dateTo)) {
        latest = point;
      }
    }
    final value = latest?.value;
    if (value is! NumericHealthValue) return null;
    return _bodyFatAsPercent(value.numericValue.toDouble());
  }

  /// Both platform bridges report workout energy in kilocalories, but the
  /// unit travels with the value, so honour it rather than assuming. An
  /// energy unit we can't convert is dropped: a workout with no usable
  /// figure is skipped upstream, which is safer than importing a number that
  /// is off by a factor of four thousand.
  double? _energyInKcal(int? energy, HealthDataUnit? unit) {
    if (energy == null) return null;
    switch (unit) {
      case null:
      case HealthDataUnit.KILOCALORIE:
      case HealthDataUnit.LARGE_CALORIE:
        return energy.toDouble();
      case HealthDataUnit.SMALL_CALORIE:
        return energy / 1000;
      case HealthDataUnit.JOULE:
        return energy / 4184;
      default:
        _log.warning('Dropping workout energy in unsupported unit $unit');
        return null;
    }
  }

  /// Health Connect stores body fat as a 0..100 percentage while HealthKit's
  /// percent unit is a 0..1 fraction, and the plugin passes each through
  /// as-is. No living adult is under 1% body fat, so a value at or below 1 is
  /// unambiguously the fractional spelling.
  double _bodyFatAsPercent(double raw) => raw <= 1 ? raw * 100 : raw;
}
