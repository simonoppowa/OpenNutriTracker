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
}
