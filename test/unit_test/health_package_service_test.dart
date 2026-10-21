import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';
import 'package:opennutritracker/core/data/data_source/health/health_connect_workout_reader.dart';
import 'package:opennutritracker/core/data/data_source/health/health_package_service.dart';

/// Stands in for the plugin's own entry point so the grant bookkeeping can be
/// exercised without a platform channel.
class _FakeHealth extends Fake implements Health {
  bool authorizationGranted = true;
  bool? workoutPermissions;

  List<HealthDataType>? requestedTypes;
  List<HealthDataType>? recheckedTypes;

  /// Records every read the service asks the plugin for, so a test can assert
  /// that the workout read no longer goes through it on Android.
  final queriedTypes = <List<HealthDataType>>[];
  List<HealthDataPoint> dataPoints = const [];

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    requestedTypes = types;
    return authorizationGranted;
  }

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    recheckedTypes = types;
    return workoutPermissions;
  }

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    queriedTypes.add(types);
    return dataPoints;
  }

  /// Every time-window delete, as (type, start, end).
  final windowDeletes = <(HealthDataType, DateTime, DateTime?)>[];

  /// Every delete by client record id, as (type, id).
  final idDeletes = <(HealthDataType, String)>[];

  @override
  Future<bool> delete({
    required HealthDataType type,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    windowDeletes.add((type, startTime, endTime));
    return true;
  }

  @override
  Future<bool> deleteByClientRecordId({
    required HealthDataType dataTypeKey,
    required String clientRecordId,
    String? recordId,
  }) async {
    idDeletes.add((dataTypeKey, clientRecordId));
    return true;
  }
}

/// Records the client record version and trans fat of each meal write.
/// Caught in [noSuchMethod] rather than overridden, so the plugin's long
/// parameter list is not restated here.
class _VersionRecordingHealth extends _FakeHealth {
  final versions = <double?>[];
  final transFats = <double?>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #writeMeal) {
      versions.add(invocation.namedArguments[#clientRecordVersion] as double?);
      transFats.add(invocation.namedArguments[#fatTransMonoenoic] as double?);
      return Future.value(true);
    }
    return super.noSuchMethod(invocation);
  }
}

/// The Health Connect session read, without a method channel.
class _FakeWorkoutReader extends Fake implements HealthConnectWorkoutReader {
  List<ExternalWorkout> sessions = const [];
  int calls = 0;

  @override
  Future<List<ExternalWorkout>> readExerciseSessions({
    required DateTime from,
    required DateTime to,
  }) async {
    calls++;
    return sessions;
  }
}

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

  group('HealthPackageService.requestPermissions', () {
    late _FakeHealth health;
    late HealthPackageService service;

    setUp(() {
      health = _FakeHealth();
      service = HealthPackageService(health);
    });

    test('a refused request is a refusal, without a second question', () async {
      health.authorizationGranted = false;

      expect(await service.requestPermissions(), isFalse);
      expect(health.recheckedTypes, isNull);
    });

    test('a grant that left the workout rows out is not success', () async {
      // Android's requestAuthorization answers true as soon as *anything* was
      // granted — body fat alone would otherwise switch the feature on with
      // nothing importable behind it.
      health.workoutPermissions = false;

      expect(await service.requestPermissions(), isFalse);
    });

    test('a grant covering the workout rows is success', () async {
      health.workoutPermissions = true;

      expect(await service.requestPermissions(), isTrue);
    });

    test(
      'a platform that will not report read grants is not a refusal',
      () async {
        // iOS never answers hasPermissions for reads.
        health.workoutPermissions = null;

        expect(await service.requestPermissions(), isTrue);
      },
    );

    test('on iOS body fat is asked for, but never re-checked', () async {
      final iosHealth = _FakeHealth()..workoutPermissions = true;
      final iosService = HealthPackageService(
        iosHealth,
        platform: HealthTargetPlatform.ios,
      );

      await iosService.requestPermissions();

      expect(
        iosHealth.requestedTypes,
        contains(HealthDataType.BODY_FAT_PERCENTAGE),
      );
      expect(iosHealth.recheckedTypes, contains(HealthDataType.WORKOUT));
      expect(
        iosHealth.recheckedTypes,
        isNot(contains(HealthDataType.BODY_FAT_PERCENTAGE)),
      );
    });
  });

  // Play's Health Connect permissions policy refused this app READ_BODY_FAT,
  // READ_DISTANCE and READ_STEPS as excessive for the features it offers
  // (enforced 8 Sept 2026). The app may ask for nothing beyond exercise and
  // total calories on Android, and these are the tests that say so.
  group('Android asks for no more than the policy allows', () {
    late _FakeHealth health;
    late HealthPackageService service;

    setUp(() {
      health = _FakeHealth()..workoutPermissions = true;
      service = HealthPackageService(
        health,
        workoutReader: _FakeWorkoutReader(),
        platform: HealthTargetPlatform.android,
      );
    });

    test('the permission request covers exercise and calories, and '
        'nothing else', () async {
      await service.requestPermissions();

      expect(health.requestedTypes, [
        HealthDataType.WORKOUT,
        HealthDataType.TOTAL_CALORIES_BURNED,
      ]);
    });

    test('the three refused types are never requested', () async {
      await service.requestPermissions();

      expect(
        health.requestedTypes,
        isNot(
          anyElement(
            isIn([
              HealthDataType.BODY_FAT_PERCENTAGE,
              HealthDataType.DISTANCE_DELTA,
              HealthDataType.STEPS,
            ]),
          ),
        ),
      );
    });

    test('body fat is not read, and answers null rather than throwing',
        () async {
      expect(await service.readLatestBodyFatPercent(), isNull);
      expect(health.queriedTypes, isEmpty);
    });
  });

  group('HealthPackageService.readWorkouts on Android', () {
    late _FakeHealth health;
    late _FakeWorkoutReader reader;
    late HealthPackageService service;

    final from = DateTime(2026, 8, 13);
    final to = DateTime(2026, 8, 14);
    final sessionStart = DateTime(2026, 8, 13, 18, 0);
    final sessionEnd = DateTime(2026, 8, 13, 19, 0);

    setUp(() {
      health = _FakeHealth()..workoutPermissions = true;
      reader = _FakeWorkoutReader();
      service = HealthPackageService(
        health,
        workoutReader: reader,
        platform: HealthTargetPlatform.android,
      );
    });

    test('sessions come from Health Connect directly, never from the '
        'plugin\'s workout read', () async {
      reader.sessions = [
        ExternalWorkout(
          id: 'session-1',
          start: sessionStart,
          end: sessionEnd,
          activityTypeName: 'RUNNING',
          sourceAppName: 'com.hevy.app',
        ),
      ];

      await service.readWorkouts(from: from, to: to);

      expect(reader.calls, 1);
      // The only plugin read left is the calorie one.
      expect(health.queriedTypes, [
        [HealthDataType.TOTAL_CALORIES_BURNED],
      ]);
    });

    test('energy is attributed to the session from the calorie records',
        () async {
      reader.sessions = [
        ExternalWorkout(
          id: 'session-1',
          start: sessionStart,
          end: sessionEnd,
          activityTypeName: 'RUNNING',
          sourceAppName: 'com.hevy.app',
        ),
      ];
      health.dataPoints = [
        _calories(source: 'com.hevy.app', start: sessionStart, kcal: 430.3),
        _calories(
          source: 'com.fitbit.FitbitMobile',
          start: sessionStart,
          kcal: 170,
        ),
      ];

      final workouts = await service.readWorkouts(from: from, to: to);

      expect(workouts, hasLength(1));
      expect(workouts.single.id, 'session-1');
      expect(workouts.single.activityTypeName, 'RUNNING');
      expect(workouts.single.energyBurnedKcal, closeTo(430.3, 0.001));
      expect(workouts.single.sourceAppName, 'com.hevy.app');
    });

    test('no sessions means the calorie records are never read', () async {
      reader.sessions = const [];

      expect(await service.readWorkouts(from: from, to: to), isEmpty);
      expect(health.queriedTypes, isEmpty);
    });

    test('a definite refusal still aborts before any read', () async {
      health.workoutPermissions = false;

      expect(
        () => service.readWorkouts(from: from, to: to),
        throwsStateError,
      );
      expect(reader.calls, 0);
    });
  });

  // #1393 review: the plugin's iOS side has no delete by record id, only by
  // time window, and one window can hold several exported meals.
  group('meal deletes', () {
    const id = 'ont_intake_a';
    final at = DateTime(2026, 6, 15, 12, 30);

    test('on Android delete by client record id, never by window', () async {
      final health = _FakeHealth();
      final service = HealthPackageService(
        health,
        workoutReader: _FakeWorkoutReader(),
        platform: HealthTargetPlatform.android,
      );

      expect(service.hasRecordIdentity, isTrue);
      expect(await service.deleteMeal(id), isTrue);
      expect(await service.deleteMealWindow(at), isFalse);

      expect(health.idDeletes, [(HealthDataType.NUTRITION, id)]);
      expect(health.windowDeletes, isEmpty);
    });

    test('on iOS delete the minute at the meal, never by id', () async {
      final health = _FakeHealth();
      final service = HealthPackageService(
        health,
        platform: HealthTargetPlatform.ios,
      );

      expect(service.hasRecordIdentity, isFalse);
      expect(await service.deleteMealWindow(at), isTrue);
      expect(await service.deleteMeal(id), isFalse);

      // A millisecond short, so the window is half-open whichever way
      // HealthKit reads its end bound.
      expect(health.windowDeletes, [
        (
          HealthDataType.NUTRITION,
          at,
          at.add(const Duration(seconds: 59, milliseconds: 999)),
        ),
      ]);
      expect(health.idDeletes, isEmpty);
    });
  });

  // #1393 review: Health Connect keeps the record with the highest version,
  // so an edit written after the clock was set back must still outrank it.
  test('record versions keep rising when the clock goes back', () async {
    final health = _VersionRecordingHealth();
    var now = DateTime(2026, 6, 15, 12);
    final service = HealthPackageService(
      health,
      workoutReader: _FakeWorkoutReader(),
      platform: HealthTargetPlatform.android,
      now: () => now,
    );
    final meal = ExternalMealIntake(
      id: 'ont_intake_a',
      mealTypeName: 'LUNCH',
      dateTime: DateTime(2026, 6, 15, 12, 30),
    );

    expect(await service.writeMeal(meal), isTrue);
    now = now.subtract(const Duration(hours: 1));
    expect(await service.writeMeal(meal), isTrue);

    expect(health.versions, hasLength(2));
    expect(health.versions[1]!, greaterThan(health.versions[0]!));
  });

  // #1393 review: the disclosure promises the types of fat, and Health
  // Connect has a trans fat field.
  test('trans fat is written with the meal', () async {
    final health = _VersionRecordingHealth();
    final service = HealthPackageService(
      health,
      workoutReader: _FakeWorkoutReader(),
      platform: HealthTargetPlatform.android,
    );

    await service.writeMeal(
      ExternalMealIntake(
        id: 'ont_intake_a',
        mealTypeName: 'LUNCH',
        dateTime: DateTime(2026, 6, 15, 12, 30),
        fatTrans: 0.6,
      ),
    );

    expect(health.transFats, [0.6]);
  });
}
