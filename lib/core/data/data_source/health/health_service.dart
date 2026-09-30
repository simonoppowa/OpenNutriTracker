import 'package:opennutritracker/core/data/data_source/health/external_weight.dart';
import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';

/// The app's whole surface onto the platform health store — Health Connect
/// on Android, Apple Health on iOS.
///
/// Everything the `health` plugin can throw at us stops here: the plugin is
/// only ever touched by [HealthService] implementations, so the import
/// pipeline, its use case and its tests never load a method channel.
abstract class HealthService {
  /// Whether this device can serve health data at all — right platform, and
  /// on Android a Health Connect install that is actually usable.
  Future<bool> isAvailable();

  /// Asks the user for read access to workouts and body fat percentage.
  /// Returns whether the request came back granted.
  Future<bool> requestPermissions();

  /// Workout records overlapping `[from, to]`, oldest-first ordering not
  /// guaranteed. Throws if the platform refuses the read (revoked
  /// permission, Health Connect uninstalled) — callers decide whether that
  /// is a background hiccup to log or a failure to show the user.
  Future<List<ExternalWorkout>> readWorkouts({
    required DateTime from,
    required DateTime to,
  });

  /// Most recent body fat percentage on record, as a percentage in 0..100.
  /// Null when nothing is recorded or the read was not permitted — the
  /// suggestion calculator treats that as "fall back to BMI".
  Future<double?> readLatestBodyFatPercent();

  /// Asks the user for read access to body weight. Separate from
  /// [requestPermissions] because weight import is its own opt-in, and the
  /// platform should only be asked for what the user switched on.
  Future<bool> requestWeightPermissions();

  /// Body weight readings taken within `[from, to]`, in no guaranteed order.
  /// Throws if the platform refuses the read, as [readWorkouts] does.
  Future<List<ExternalWeight>> readWeights({
    required DateTime from,
    required DateTime to,
  });
}
