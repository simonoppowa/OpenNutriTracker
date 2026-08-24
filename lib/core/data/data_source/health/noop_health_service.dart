import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';

/// The [HealthService] used when there is no health store to talk to —
/// an unsupported platform, or a plugin that failed to initialise.
///
/// It reports itself unavailable rather than pretending to work, so the
/// settings screen can say why the feature is off instead of silently doing
/// nothing when the user flips the switch.
class NoopHealthService implements HealthService {
  const NoopHealthService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<List<ExternalWorkout>> readWorkouts({
    required DateTime from,
    required DateTime to,
  }) async => const <ExternalWorkout>[];

  @override
  Future<double?> readLatestBodyFatPercent() async => null;
}
