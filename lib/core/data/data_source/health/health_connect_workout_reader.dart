import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
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
/// its own, and attributing it from the calorie records is
/// [HealthPackageService]'s job.
class HealthConnectWorkoutReader {
  static const _channel = MethodChannel('com.opennutritracker/health_connect');

  static final _log = Logger('HealthConnectWorkoutReader');

  final MethodChannel _methodChannel;

  HealthConnectWorkoutReader({MethodChannel? channel})
    : _methodChannel = channel ?? _channel;

  /// Sessions starting within `[from, to)`.
  ///
  /// Throws [PlatformException] when the platform refuses — code
  /// `permission_denied` for a revoked grant, `health_connect_unavailable`
  /// for anything else. Callers treat both as a failed read rather than an
  /// empty one, so a refusal never advances the import watermark.
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
