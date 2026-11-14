import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/health/health_connect_workout_reader.dart';

/// The decoding half of the Health Connect session read. The Kotlin half is
/// exercised on a device; what is worth pinning here is that a malformed
/// record costs that one workout and not the whole import, and that the
/// window is passed across as the platform expects it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.opennutritracker/health_connect_test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late HealthConnectWorkoutReader reader;
  MethodCall? lastCall;
  Object? response;

  final from = DateTime(2026, 8, 13);
  final to = DateTime(2026, 8, 14);

  Map<String, Object?> session({
    Object? uuid = 'session-1',
    Object? activityTypeName = 'RUNNING',
    Object? startMillis,
    Object? endMillis,
    Object? sourceName = 'com.hevy.app',
  }) => {
    'uuid': uuid,
    'activityTypeName': activityTypeName,
    'startMillis': startMillis ?? DateTime(2026, 8, 13, 18).millisecondsSinceEpoch,
    'endMillis': endMillis ?? DateTime(2026, 8, 13, 19).millisecondsSinceEpoch,
    'sourceName': sourceName,
  };

  setUp(() {
    lastCall = null;
    response = <Object?>[];
    reader = HealthConnectWorkoutReader(channel: channel);
    messenger.setMockMethodCallHandler(channel, (call) async {
      lastCall = call;
      if (response is Exception) throw response as Exception;
      return response;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('the window crosses the channel as epoch milliseconds', () async {
    await reader.readExerciseSessions(from: from, to: to);

    expect(lastCall?.method, 'readExerciseSessions');
    expect(lastCall?.arguments, {
      'fromMillis': from.millisecondsSinceEpoch,
      'toMillis': to.millisecondsSinceEpoch,
    });
  });

  test('a session becomes a workout with no energy of its own', () async {
    response = [session()];

    final workouts = await reader.readExerciseSessions(from: from, to: to);

    expect(workouts, hasLength(1));
    expect(workouts.single.id, 'session-1');
    expect(workouts.single.activityTypeName, 'RUNNING');
    expect(workouts.single.start, DateTime(2026, 8, 13, 18));
    expect(workouts.single.end, DateTime(2026, 8, 13, 19));
    expect(workouts.single.sourceAppName, 'com.hevy.app');
    // A Health Connect session carries no energy; the service attributes it.
    expect(workouts.single.energyBurnedKcal, isNull);
  });

  test('one malformed record costs that record, not the import', () async {
    response = [
      session(uuid: null),
      session(uuid: 'good', activityTypeName: 'ROWING_MACHINE'),
      session(startMillis: 'not a number'),
      'not a map',
    ];

    final workouts = await reader.readExerciseSessions(from: from, to: to);

    expect(workouts.map((workout) => workout.id), ['good']);
  });

  test('a missing source name is tolerated', () async {
    response = [session(sourceName: null)];

    final workouts = await reader.readExerciseSessions(from: from, to: to);

    expect(workouts.single.sourceAppName, isNull);
  });

  test('nothing back means no workouts', () async {
    response = null;

    expect(await reader.readExerciseSessions(from: from, to: to), isEmpty);
  });

  test('a refused read throws rather than reporting an empty window', () async {
    // The import would otherwise file "nothing new" and advance its
    // watermark, silently skipping every workout in the window.
    response = PlatformException(code: 'permission_denied');

    expect(
      () => reader.readExerciseSessions(from: from, to: to),
      throwsA(isA<PlatformException>()),
    );
  });

  group('readTotalCaloriesBurned', () {
    Map<String, Object?> calories({
      Object? startMillis,
      Object? endMillis,
      Object? kcal = 120.5,
      Object? sourceName = 'com.fitbit.FitbitMobile',
    }) => {
      'startMillis':
          startMillis ?? DateTime(2026, 8, 13, 18).millisecondsSinceEpoch,
      'endMillis':
          endMillis ?? DateTime(2026, 8, 13, 18, 15).millisecondsSinceEpoch,
      'kcal': kcal,
      'sourceName': sourceName,
    };

    test('the window crosses the channel as epoch milliseconds', () async {
      await reader.readTotalCaloriesBurned(from: from, to: to);

      expect(lastCall?.method, 'readTotalCaloriesBurned');
      expect(lastCall?.arguments, {
        'fromMillis': from.millisecondsSinceEpoch,
        'toMillis': to.millisecondsSinceEpoch,
      });
    });

    test('a record keeps its interval, energy and writer', () async {
      response = [calories()];

      final records = await reader.readTotalCaloriesBurned(from: from, to: to);

      expect(records, hasLength(1));
      expect(records.single.start, DateTime(2026, 8, 13, 18));
      expect(records.single.end, DateTime(2026, 8, 13, 18, 15));
      expect(records.single.kcal, 120.5);
      expect(records.single.sourceName, 'com.fitbit.FitbitMobile');
    });

    test('a whole-number energy is accepted', () async {
      // The platform sends a Double, but a codec is free to hand an integral
      // value over as an int.
      response = [calories(kcal: 2400)];

      final records = await reader.readTotalCaloriesBurned(from: from, to: to);

      expect(records.single.kcal, 2400.0);
    });

    test('one malformed record costs that record, not the read', () async {
      response = [
        calories(kcal: null),
        calories(startMillis: 'not a number'),
        calories(sourceName: null),
        calories(kcal: 75),
        'not a map',
      ];

      final records = await reader.readTotalCaloriesBurned(from: from, to: to);

      expect(records.map((record) => record.kcal), [75.0]);
    });

    test('nothing back means no records', () async {
      response = null;

      expect(await reader.readTotalCaloriesBurned(from: from, to: to), isEmpty);
    });

    // #1459: the plugin's calorie read answered a rate limit with an empty
    // list, so every workout lost its energy and the import moved on.
    test(
      'a rate-limited read throws rather than reporting no energy',
      () async {
        response = PlatformException(
          code: HealthConnectWorkoutReader.rateLimitedCode,
        );

        await expectLater(
          reader.readTotalCaloriesBurned(from: from, to: to),
          throwsA(
            isA<PlatformException>().having(
              HealthConnectWorkoutReader.isRateLimited,
              'isRateLimited',
              isTrue,
            ),
          ),
        );
      },
    );
  });

  group('hasWorkoutReadPermissions', () {
    test('relays the platform\'s answer', () async {
      response = true;
      expect(await reader.hasWorkoutReadPermissions(), isTrue);
      expect(lastCall?.method, 'hasWorkoutReadPermissions');

      response = false;
      expect(await reader.hasWorkoutReadPermissions(), isFalse);
    });

    test('an empty answer is not a grant', () async {
      response = null;
      expect(await reader.hasWorkoutReadPermissions(), isFalse);
    });

    test('a refusal arrives as a PlatformException the caller can catch',
        () async {
      response = PlatformException(
        code: HealthConnectWorkoutReader.rateLimitedCode,
        message: 'Rate limited request quota has been exceeded.',
      );

      await expectLater(
        reader.hasWorkoutReadPermissions(),
        throwsA(
          isA<PlatformException>().having(
            (e) => HealthConnectWorkoutReader.isRateLimited(e),
            'isRateLimited',
            isTrue,
          ),
        ),
      );
    });
  });

  group('isRateLimited', () {
    test('only the rate-limited code counts', () {
      expect(
        HealthConnectWorkoutReader.isRateLimited(
          PlatformException(code: 'health_connect_rate_limited'),
        ),
        isTrue,
      );
      expect(
        HealthConnectWorkoutReader.isRateLimited(
          PlatformException(code: 'health_connect_unavailable'),
        ),
        isFalse,
      );
      expect(
        HealthConnectWorkoutReader.isRateLimited(StateError('rate limited')),
        isFalse,
      );
    });
  });
}
