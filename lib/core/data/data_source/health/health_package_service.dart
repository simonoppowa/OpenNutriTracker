import 'dart:io' show Platform;
import 'dart:math' show max;

import 'package:health/health.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';
import 'package:opennutritracker/core/data/data_source/health/health_connect_workout_reader.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';

/// Which platform's health store rules apply.
///
/// Injected into [HealthPackageService] rather than read from [Platform] at
/// every branch, because the two platforms now diverge in what they read and
/// a host test is neither of them.
enum HealthTargetPlatform {
  android,
  ios,
  unsupported;

  static HealthTargetPlatform get current {
    if (Platform.isAndroid) return HealthTargetPlatform.android;
    if (Platform.isIOS) return HealthTargetPlatform.ios;
    return HealthTargetPlatform.unsupported;
  }
}

/// [HealthService] backed by the `health` plugin — Health Connect on
/// Android, HealthKit on iOS.
///
/// Deliberately free of business logic: it asks for the data types the
/// feature needs, hands back plain [ExternalWorkout] records, and leaves
/// every decision about what to do with them to the import use case.
///
/// The two platforms are not symmetric, and the asymmetry is a policy
/// consequence rather than a technical one. Play's Health Connect permissions
/// policy refused this app READ_BODY_FAT, READ_DISTANCE and READ_STEPS as
/// excessive (enforced 8 Sept 2026), so on Android:
///
///  * workouts are read outside the plugin, by
///    [HealthConnectWorkoutReader] — the plugin's own workout read pulls
///    distance and steps for every session and fails entirely without them;
///  * body fat is not read at all, and the calorie-credit suggestion falls
///    back to the BMI-derived percentile it already used for anyone whose
///    health store had no body fat on record.
///
/// HealthKit is not subject to that policy and keeps both.
class HealthPackageService implements HealthService {
  /// Workouts, on every platform that has a health store. On Android this is
  /// requested (it is what grants READ_EXERCISE) but read through
  /// [HealthConnectWorkoutReader] rather than the plugin.
  static const _workoutType = HealthDataType.WORKOUT;

  /// Health Connect sessions carry no energy of their own — apps write
  /// separate TOTAL_CALORIES_BURNED records — so the calorie read is what
  /// gives an imported workout its kcal. HealthKit puts the total on the
  /// workout itself, so asking for this on iOS would add a permission row the
  /// feature never uses.
  static const _androidEnergyType = HealthDataType.TOTAL_CALORIES_BURNED;

  /// Body fat personalises the calorie-credit suggestion. iOS only; see the
  /// class doc.
  static const _iosBodyCompositionType = HealthDataType.BODY_FAT_PERCENTAGE;

  List<HealthDataType> get _readTypes => [
    _workoutType,
    if (_platform == HealthTargetPlatform.android) _androidEnergyType,
    if (_platform == HealthTargetPlatform.ios) _iosBodyCompositionType,
  ];

  /// The types a workout read touches — [requestPermissions] asks for all of
  /// [_readTypes], but a revoked body-fat grant only costs the suggestion,
  /// so the workout guard must not fail on it.
  List<HealthDataType> get _workoutReadTypes => [
    _workoutType,
    if (_platform == HealthTargetPlatform.android) _androidEnergyType,
  ];

  /// How far back to look for the latest body fat reading. A year is long
  /// enough that a user who steps on a smart scale occasionally still gets a
  /// personalised suggestion, and short enough that a stale composition from
  /// several years ago doesn't drive it.
  static const _bodyFatLookback = Duration(days: 365);

  static final _log = Logger('HealthPackageService');
  final Health _health;
  final HealthConnectWorkoutReader _workoutReader;
  final HealthTargetPlatform _platform;

  HealthPackageService(
    this._health, {
    HealthConnectWorkoutReader? workoutReader,
    HealthTargetPlatform? platform,
  }) : _workoutReader = workoutReader ?? HealthConnectWorkoutReader(),
       _platform = platform ?? HealthTargetPlatform.current;

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
    if (_platform == HealthTargetPlatform.unsupported) return false;
    return await _health.isHealthConnectAvailable();
  }

  @override
  Future<bool> requestPermissions() async {
    final granted = await _health.requestAuthorization(
      _readTypes,
      permissions: List.filled(_readTypes.length, HealthDataAccess.READ),
    );
    if (!granted) return false;
    // Android answers the request with "was anything at all granted", so a
    // user who ticked calories and left exercise unticked would switch the
    // feature on with nothing importable behind it. Re-check the types a
    // workout read actually needs; on iOS body fat only costs the suggestion,
    // so a refusal there is not a failure. hasPermissions answers null where
    // the platform will not say (iOS never reports read grants) — same rule
    // as [readWorkouts], only a definite refusal counts.
    final hasWorkoutPermissions = await _health.hasPermissions(
      _workoutReadTypes,
      permissions: List.filled(_workoutReadTypes.length, HealthDataAccess.READ),
    );
    return hasWorkoutPermissions != false;
  }

  @override
  Future<List<ExternalWorkout>> readWorkouts({
    required DateTime from,
    required DateTime to,
  }) async {
    // The plugin swallows a SecurityException from a partially-revoked grant
    // and answers with an empty list, which upstream would file as "nothing
    // new" and advance the watermark. Check first and fail loudly instead.
    // hasPermissions answers null where the platform will not say (iOS never
    // reports read grants); only a definite refusal aborts.
    final hasPermissions = await _health.hasPermissions(
      _workoutReadTypes,
      permissions: List.filled(_workoutReadTypes.length, HealthDataAccess.READ),
    );
    if (hasPermissions == false) {
      throw StateError(
        'Missing health read permissions for a workout import; '
        'needed: $_workoutReadTypes',
      );
    }
    if (_platform == HealthTargetPlatform.android) {
      return await _readAndroidWorkouts(from: from, to: to);
    }
    final points = await _health.getHealthDataFromTypes(
      types: const [_workoutType],
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
          // A HealthKit workout carries its own total.
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

  /// Workouts from Health Connect, read outside the plugin.
  ///
  /// A session record carries no energy, so the calorie records for the whole
  /// window are read once and attributed per workout by
  /// [androidWorkoutEnergyKcal] — which is also why the plugin's own totals
  /// were never used here even when they were available.
  Future<List<ExternalWorkout>> _readAndroidWorkouts({
    required DateTime from,
    required DateTime to,
  }) async {
    final sessions = await _workoutReader.readExerciseSessions(
      from: from,
      to: to,
    );
    if (sessions.isEmpty) return const <ExternalWorkout>[];
    final calorieRecords = await _health.getHealthDataFromTypes(
      types: const [_androidEnergyType],
      startTime: from,
      endTime: to,
    );
    return [
      for (final session in sessions)
        ExternalWorkout(
          id: session.id,
          start: session.start,
          end: session.end,
          activityTypeName: session.activityTypeName,
          energyBurnedKcal: androidWorkoutEnergyKcal(
            start: session.start,
            end: session.end,
            sourceName: session.sourceAppName ?? '',
            calorieRecords: calorieRecords,
          ),
          sourceAppName: session.sourceAppName,
        ),
    ];
  }

  /// Energy attributable to one Android workout session.
  ///
  /// A Health Connect session record carries no calories of its own; apps
  /// write separate TOTAL_CALORIES_BURNED records, and the plugin fills a
  /// workout's total by summing every such record overlapping the session
  /// window regardless of who wrote it. Alongside an all-day calorie stream
  /// (Fitbit and Google Fit write basal+activity in 15-minute buckets —
  /// energy the calorie goal already models) that inflates a real workout by
  /// whatever the background stream put into the same window. Only the
  /// records the session's own writer produced are the workout's energy, so
  /// the sum is per-source: [sourceName]'s own records when it wrote any,
  /// otherwise the largest single-source sum in the window (some setups
  /// track sessions in one app and calories in another) — never the
  /// cross-source total.
  ///
  /// A record belongs to the window when it STARTS inside it ([start]
  /// inclusive, [end] exclusive) — the same startTime-based semantics Health
  /// Connect's own between() filter applies.
  @visibleForTesting
  static double? androidWorkoutEnergyKcal({
    required DateTime start,
    required DateTime end,
    required String sourceName,
    required List<HealthDataPoint> calorieRecords,
  }) {
    final kcalBySource = <String, double>{};
    for (final record in calorieRecords) {
      if (record.dateFrom.isBefore(start) || !record.dateFrom.isBefore(end)) {
        continue;
      }
      final value = record.value;
      if (value is! NumericHealthValue) continue;
      final kcal = _energyInKcal(value.numericValue, record.unit);
      if (kcal == null) continue;
      kcalBySource.update(
        record.sourceName,
        (sum) => sum + kcal,
        ifAbsent: () => kcal,
      );
    }
    final ownKcal = kcalBySource[sourceName] ?? 0;
    if (ownKcal > 0) return ownKcal;
    final largestKcal = kcalBySource.values.fold(0.0, max);
    return largestKcal > 0 ? largestKcal : null;
  }

  @override
  Future<double?> readLatestBodyFatPercent() async {
    // Android holds no body-fat permission — Play refused it as excessive for
    // what this app does. Null is the same answer the calculator already got
    // for the many users whose health store has no body fat on record, and it
    // falls back to the BMI-derived percentile.
    if (_platform == HealthTargetPlatform.android) return null;
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
  static double? _energyInKcal(num? energy, HealthDataUnit? unit) {
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
