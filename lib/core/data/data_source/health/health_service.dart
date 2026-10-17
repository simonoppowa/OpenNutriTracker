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

  /// Whether meal records are addressed by their client record id. True on
  /// Health Connect, which upserts and deletes by it, so callers use
  /// [writeMeal] and [deleteMeal]. False on HealthKit, where the plugin drops
  /// the id: a rewrite adds a second meal, and the only delete is
  /// [deleteMealWindow].
  bool get hasRecordIdentity;

  /// Writes a meal intake record to the platform health store.
  /// Returns whether the write was successful.
  Future<bool> writeMeal(ExternalMealIntake intake);

  /// Deletes the meal written under [clientRecordId]. Only where
  /// [hasRecordIdentity]; returns false elsewhere.
  Future<bool> deleteMeal(String clientRecordId);

  /// Deletes every meal this app wrote starting in
  /// `[start, start + ExternalMealIntake.sampleDuration)`, whichever diary
  /// entry wrote it. Only where [hasRecordIdentity] is false; returns false
  /// elsewhere.
  Future<bool> deleteMealWindow(DateTime start);
}
