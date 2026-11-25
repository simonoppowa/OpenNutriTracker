import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:opennutritracker/core/data/data_source/health/calorie_record.dart';
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
}

/// The Health Connect session read, without a method channel.
class _FakeWorkoutReader extends Fake implements HealthConnectWorkoutReader {
  List<ExternalWorkout> sessions = const [];
  int calls = 0;
  bool permissionsHeld = true;
  Object? permissionsError;
  int permissionChecks = 0;

  @override
  Future<bool> hasWorkoutReadPermissions() async {
    permissionChecks++;
    final error = permissionsError;
    if (error != null) throw error;
    return permissionsHeld;
  }

  @override
  Future<List<ExternalWorkout>> readExerciseSessions({
    required DateTime from,
    required DateTime to,
  }) async {
    calls++;
    return sessions;
  }

  List<CalorieRecord> calorieRecords = const [];
  Object? calorieError;
  int calorieCalls = 0;
  DateTime? calorieFrom;
  DateTime? calorieTo;

  @override
  Future<List<CalorieRecord>> readTotalCaloriesBurned({
    required DateTime from,
    required DateTime to,
  }) async {
    calorieCalls++;
    calorieFrom = from;
    calorieTo = to;
    final error = calorieError;
    if (error != null) throw error;
    return calorieRecords;
  }
}

/// A TOTAL_CALORIES_BURNED record as the app's channel reports it.
CalorieRecord _calories({
  required String source,
  required DateTime start,
  Duration duration = const Duration(minutes: 15),
  required double kcal,
}) => CalorieRecord(
  start: start,
  end: start.add(duration),
  kcal: kcal,
  sourceName: source,
);

void main() {
  // The session window all tests attribute against.
  final start = DateTime(2026, 8, 13, 18, 0);
  final end = DateTime(2026, 8, 13, 19, 0);

  double? energy({
    String sourceName = 'com.hevy.app',
    required List<CalorieRecord> calorieRecords,
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

    // #948: a record that does not START inside the session used to count
    // for nothing. Writers that keep one calorie record per day, or a
    // 15-minute bucket that began before a short session, left a real
    // workout with no energy, and the import skipped it without a word.
    test('a record spanning the whole session counts for the share that '
        'falls inside it', () {
      final records = [
        _calories(
          source: 'com.hevy.app',
          start: DateTime(2026, 8, 13),
          duration: const Duration(days: 1),
          kcal: 2400,
        ),
      ];

      // One hour of a 24-hour record: 2400 / 24.
      expect(energy(calorieRecords: records), closeTo(100, 0.001));
    });

    test('a record that started before the session counts for the part '
        'inside it', () {
      final records = [
        _calories(
          source: 'com.hevy.app',
          start: start.subtract(const Duration(minutes: 5)),
          kcal: 60,
        ),
      ];

      // Ten of its fifteen minutes fall inside the session.
      expect(energy(calorieRecords: records), closeTo(40, 0.001));
    });

    test('a record running past the session end counts only up to the end', () {
      final records = [
        _calories(
          source: 'com.hevy.app',
          start: end.subtract(const Duration(minutes: 5)),
          kcal: 30,
        ),
      ];

      expect(energy(calorieRecords: records), closeTo(10, 0.001));
    });

    test('a record that only touches the session boundary counts for '
        'nothing', () {
      final records = [
        _calories(
          source: 'com.hevy.app',
          start: start.subtract(const Duration(minutes: 15)),
          kcal: 98,
        ),
        // The window is half-open: a record starting at the end is outside.
        _calories(source: 'com.hevy.app', start: end, kcal: 48),
        _calories(source: 'com.hevy.app', start: start, kcal: 197.6),
      ];

      expect(energy(calorieRecords: records), closeTo(197.6, 0.001));
    });

    test('a zero-length record counts in full when it lies in the session', () {
      final records = [
        _calories(
          source: 'com.hevy.app',
          start: start.add(const Duration(minutes: 10)),
          duration: Duration.zero,
          kcal: 25,
        ),
        _calories(
          source: 'com.hevy.app',
          start: end,
          duration: Duration.zero,
          kcal: 99,
        ),
      ];

      expect(energy(calorieRecords: records), closeTo(25, 0.001));
    });

    test('a record with no energy does not stand in for the writer\'s own', () {
      // The session writer logged a zero; the other source's real figure is
      // the better estimate, same as when the writer logged nothing.
      final records = [
        _calories(source: 'com.hevy.app', start: start, kcal: 0),
        _calories(source: 'com.fitbit.FitbitMobile', start: start, kcal: 80),
      ];

      expect(energy(calorieRecords: records), closeTo(80, 0.001));
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
      // The calorie read left the plugin too (#1459): nothing on Android
      // reads through it any more.
      expect(reader.calorieCalls, 1);
      expect(health.queriedTypes, isEmpty);
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
      reader.calorieRecords = [
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
      expect(reader.calorieCalls, 0);
      expect(health.queriedTypes, isEmpty);
    });

    // #948, the shape the first reporter described: Health Connect holds the
    // day's total calories as one record, which starts at midnight, before
    // the session and before the import window.
    test('a workout whose energy sits in one all-day record is imported '
        'with its share of it', () async {
      reader.sessions = [
        ExternalWorkout(
          id: 'session-1',
          start: sessionStart,
          end: sessionEnd,
          activityTypeName: 'FLEXIBILITY',
          sourceAppName: 'com.fitbit.FitbitMobile',
        ),
      ];
      reader.calorieRecords = [
        _calories(
          source: 'com.fitbit.FitbitMobile',
          start: DateTime(2026, 8, 13),
          duration: const Duration(days: 1),
          kcal: 2400,
        ),
      ];

      final workouts = await service.readWorkouts(
        // The window a run four hours after a midnight import would read.
        from: DateTime(2026, 8, 12, 4),
        to: DateTime(2026, 8, 14, 4),
      );

      expect(workouts.single.energyBurnedKcal, closeTo(100, 0.001));
    });

    test(
      'the calorie read reaches a day either side of the sessions',
      () async {
        // Whatever Health Connect's filter does with a record that only
        // overlaps the window, a record that started on the session's day or
        // ends on the next one is inside this one.
        reader.sessions = [
          ExternalWorkout(
            id: 'late',
            start: DateTime(2026, 8, 13, 22),
            end: DateTime(2026, 8, 13, 23),
            activityTypeName: 'RUNNING',
          ),
          ExternalWorkout(
            id: 'early',
            start: DateTime(2026, 8, 12, 6),
            end: DateTime(2026, 8, 12, 7),
            activityTypeName: 'RUNNING',
          ),
        ];

        await service.readWorkouts(from: from, to: to);

        expect(reader.calorieFrom, DateTime(2026, 8, 11, 6));
        expect(reader.calorieTo, DateTime(2026, 8, 14, 23));
      },
    );

    // #1459: a calorie read that Health Connect refuses must fail the whole
    // read. Answering with the sessions and no energy would have the import
    // skip every one of them and move its watermark past them for good.
    test('a rate-limited calorie read fails the read instead of returning '
        'workouts without energy', () async {
      reader.sessions = [
        ExternalWorkout(
          id: 'session-1',
          start: sessionStart,
          end: sessionEnd,
          activityTypeName: 'RUNNING',
        ),
      ];
      reader.calorieError = PlatformException(
        code: HealthConnectWorkoutReader.rateLimitedCode,
      );

      await expectLater(
        service.readWorkouts(from: from, to: to),
        throwsA(
          isA<PlatformException>().having(
            HealthConnectWorkoutReader.isRateLimited,
            'isRateLimited',
            isTrue,
          ),
        ),
      );
    });

    test('a calorie read that finds nothing leaves the workout without '
        'energy', () async {
      reader.sessions = [
        ExternalWorkout(
          id: 'session-1',
          start: sessionStart,
          end: sessionEnd,
          activityTypeName: 'RUNNING',
        ),
      ];

      final workouts = await service.readWorkouts(from: from, to: to);

      expect(workouts.single.energyBurnedKcal, isNull);
    });

    test('a definite refusal still aborts before any read', () async {
      reader.permissionsHeld = false;

      expect(
        () => service.readWorkouts(from: from, to: to),
        throwsStateError,
      );
      expect(reader.calls, 0);
    });

    // The plugin's hasPermissions runs getGrantedPermissions() in a coroutine
    // with no handler, so a rate-limited Health Connect there ended the
    // process (Sentry OPENNUTRITRACKER-6T). The grant check must not touch it.
    test('the grant check never goes through the plugin', () async {
      health.workoutPermissions = false;

      await service.readWorkouts(from: from, to: to);

      expect(reader.permissionChecks, 1);
      expect(health.recheckedTypes, isNull);
    });

    test('a failing grant check surfaces as an error, not a read', () async {
      reader.permissionsError = PlatformException(
        code: HealthConnectWorkoutReader.rateLimitedCode,
      );

      await expectLater(
        service.readWorkouts(from: from, to: to),
        throwsA(isA<PlatformException>()),
      );
      expect(reader.calls, 0);
    });

    test('requestPermissions re-checks the grants through the same path',
        () async {
      reader.permissionsHeld = false;

      expect(await service.requestPermissions(), isFalse);
      expect(reader.permissionChecks, 1);
      expect(health.recheckedTypes, isNull);
    });
  });
}
