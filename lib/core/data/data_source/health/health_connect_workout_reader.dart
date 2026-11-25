import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/health/calorie_record.dart';
import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';

/// Android-only reader for finished Health Connect exercise sessions.
///
/// The `health` plugin cannot serve these: its workout read also reads
/// distance and steps, and Play's Health Connect permissions policy refused
/// both for this app. `MainActivity`'s `com.opennutritracker/health_connect`
/// channel reads the session records directly instead — see
/// `HealthConnectWorkoutReader.kt` for the full reasoning.
///
/// Returns workouts with no energy: a Health Connect session carries none of
/// its own. The TOTAL_CALORIES_BURNED records that do carry it come through
/// [readTotalCaloriesBurned], and attributing them to a session is
/// [HealthPackageService]'s job.
class HealthConnectWorkoutReader {
  static const _channel = MethodChannel('com.opennutritracker/health_connect');

  static final _log = Logger('HealthConnectWorkoutReader');

  final MethodChannel _methodChannel;

  HealthConnectWorkoutReader({MethodChannel? channel})
    : _methodChannel = channel ?? _channel;

  /// The [PlatformException.code] Health Connect's request quota answers
  /// with ("Rate limited request quota has been exceeded"). The quota
  /// replenishes by itself, so unlike the other codes it is worth waiting out.
  static const rateLimitedCode = 'health_connect_rate_limited';

  /// Whether [error] is Health Connect refusing a call for quota reasons.
  static bool isRateLimited(Object error) =>
      error is PlatformException && error.code == rateLimitedCode;

  /// Whether the exercise and calorie read grants a workout import needs are
  /// both still held.
  ///
  /// Asked through this channel rather than the `health` plugin's
  /// `hasPermissions`, because the plugin's Android side makes that call in a
  /// coroutine with no exception handler: a Health Connect that is rate
  /// limited or unreachable ends the app's process, which no Dart `catch`
  /// can stop. Here the same failure arrives as a [PlatformException].
  ///
  /// Throws like [readExerciseSessions].
  Future<bool> hasWorkoutReadPermissions() async =>
      await _methodChannel.invokeMethod<bool>('hasWorkoutReadPermissions') ??
      false;

  /// Sessions starting within `[from, to)`.
  ///
  /// Throws [PlatformException] when the platform refuses — code
  /// `permission_denied` for a revoked grant, [rateLimitedCode] when the
  /// request quota is spent, `health_connect_unavailable` for anything else.
  /// Callers treat all of them as a failed read rather than an empty one, so
  /// a refusal never advances the import watermark.
  Future<List<ExternalWorkout>> readExerciseSessions({
    required DateTime from,
    required DateTime to,
  }) async {
    final sessions = await _methodChannel.invokeListMethod<dynamic>(
      'readExerciseSessions',
      <String, dynamic>{
        'fromMillis': from.millisecondsSinceEpoch,
        'toMillis': to.millisecondsSinceEpoch,
      },
    );
    if (sessions == null) return const <ExternalWorkout>[];

    final workouts = <ExternalWorkout>[];
    for (final session in sessions) {
      final workout = _toWorkout(session);
      if (workout != null) workouts.add(workout);
    }
    return workouts;
  }

  /// TOTAL_CALORIES_BURNED records Health Connect returns for `[from, to)`.
  ///
  /// Read here rather than through the `health` plugin, whose Android side
  /// catches every exception, a rate limit included, and answers with an
  /// empty list. The import then saw sessions with no energy, skipped them
  /// all and moved its watermark past them (#1459). Through this channel a
  /// refusal throws like [readExerciseSessions] does.
  Future<List<CalorieRecord>> readTotalCaloriesBurned({
    required DateTime from,
    required DateTime to,
  }) async {
    final records = await _methodChannel
        .invokeListMethod<dynamic>('readTotalCaloriesBurned', <String, dynamic>{
          'fromMillis': from.millisecondsSinceEpoch,
          'toMillis': to.millisecondsSinceEpoch,
        });
    if (records == null) return const <CalorieRecord>[];

    final calories = <CalorieRecord>[];
    for (final record in records) {
      final calorieRecord = _toCalorieRecord(record);
      if (calorieRecord != null) calories.add(calorieRecord);
    }
    return calories;
  }

  /// One channel entry as a [CalorieRecord], or null when it is incomplete.
  /// Dropping one record costs that record's energy, not the import.
  CalorieRecord? _toCalorieRecord(dynamic record) {
    if (record is! Map) {
      _log.warning('Skipping calorie record: expected a map, got $record');
      return null;
    }
    final start = record['startMillis'];
    final end = record['endMillis'];
    final kcal = record['kcal'];
    final sourceName = record['sourceName'];
    if (start is! int || end is! int || kcal is! num || sourceName is! String) {
      _log.warning('Skipping malformed calorie record: $record');
      return null;
    }
    return CalorieRecord(
      start: DateTime.fromMillisecondsSinceEpoch(start),
      end: DateTime.fromMillisecondsSinceEpoch(end),
      kcal: kcal.toDouble(),
      sourceName: sourceName,
    );
  }

  /// One channel entry as an [ExternalWorkout], or null when it is missing
  /// something the import cannot do without. A single unreadable record is
  /// worth a log line, not a failed import of every other workout.
  ExternalWorkout? _toWorkout(dynamic session) {
    if (session is! Map) {
      _log.warning('Skipping health session: expected a map, got $session');
      return null;
    }
    final id = session['uuid'];
    final start = session['startMillis'];
    final end = session['endMillis'];
    final activityTypeName = session['activityTypeName'];
    if (id is! String ||
        start is! int ||
        end is! int ||
        activityTypeName is! String) {
      _log.warning('Skipping malformed health session: $session');
      return null;
    }
    final sourceName = session['sourceName'];
    return ExternalWorkout(
      id: id,
      start: DateTime.fromMillisecondsSinceEpoch(start),
      end: DateTime.fromMillisecondsSinceEpoch(end),
      activityTypeName: activityTypeName,
      sourceAppName: sourceName is String ? sourceName : null,
    );
  }
}
