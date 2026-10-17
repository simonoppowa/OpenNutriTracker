import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';

/// The app's whole surface onto the platform health store — Health Connect
/// on Android, Apple Health on iOS.
///
/// Everything the `health` plugin can throw at us stops here: the plugin is
/// only ever touched by [HealthService] implementations, so the import/export
/// pipeline, its use cases and its tests never load a method channel.
abstract class HealthService {
  /// Whether this device can serve health data at all — right platform, and
  /// on Android a Health Connect install that is actually usable.
  Future<bool> isAvailable();

  /// Asks the user for read access to workouts and body fat percentage.
  /// Returns whether the request came back granted.
  Future<bool> requestPermissions();

  /// Asks the user for write access to nutrition/meals in the health store.
  /// Returns whether the request came back granted.
  Future<bool> requestNutritionWritePermissions();

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

  /// Whether [writeMeal] replaces an earlier record with the same id. True on
  /// Health Connect, which upserts by client record id. False on HealthKit,
  /// where the plugin drops the id, so a rewrite adds a second meal unless the
  /// caller deletes the old one first.
  bool get upsertsByRecordId;

  /// Writes a meal intake record to the platform health store.
  /// Returns whether the write was successful.
  Future<bool> writeMeal(ExternalMealIntake intake);

  /// Deletes a previously written meal intake record from the health store.
  /// [clientRecordId] is used on Android (Health Connect).
  /// [at] is used on iOS (HealthKit), which cannot delete by record id: every
  /// meal this app wrote starting in `[at, at + sampleDuration)` is removed.
  /// Pass null to delete nothing there; iOS then returns false.
  Future<bool> deleteMeal(String clientRecordId, {DateTime? at});
}
