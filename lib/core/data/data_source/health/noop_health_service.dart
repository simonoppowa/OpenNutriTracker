import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';

/// The [HealthService] used when there is no health store to talk to —
/// an unsupported platform, or a plugin that failed to initialise.
///
/// It reports itself unavailable rather than pretending to work, so the
/// settings screen can say why the feature is off instead of silently doing
/// nothing when the user flips the switch.
class NoopHealthService implements HealthService {
  /// Standing in for HealthKit, pass false: the meal export then treats
  /// every failed write or delete as a HealthKit window, which it keeps
  /// pending until the plugin works again on a later launch. Reporting Health
  /// Connect's record ids there would send edits and deletes down a path that
  /// keeps nothing to recover.
  const NoopHealthService({this.hasRecordIdentity = true});

  @override
  final bool hasRecordIdentity;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<bool> requestNutritionWritePermissions() async => false;

  @override
  Future<List<ExternalWorkout>> readWorkouts({
    required DateTime from,
    required DateTime to,
  }) async => const <ExternalWorkout>[];

  @override
  Future<double?> readLatestBodyFatPercent() async => null;

  @override
  Future<bool> writeMeal(ExternalMealIntake intake) async => false;

  @override
  Future<bool> deleteMeal(String clientRecordId) async => false;

  @override
  Future<bool> deleteMealWindow(DateTime start) async => false;
}
