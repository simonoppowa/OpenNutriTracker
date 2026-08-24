import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';

/// Repository over the platform health store.
///
/// Thin by design — [HealthService] already speaks in plugin-free terms, so
/// there is nothing to translate here. It exists so the import use case
/// depends on a repository like every other use case in the app does, rather
/// than reaching into a data source directly.
class HealthImportRepository {
  final HealthService _healthService;

  HealthImportRepository(this._healthService);

  Future<bool> isAvailable() async => await _healthService.isAvailable();

  Future<bool> requestPermissions() async =>
      await _healthService.requestPermissions();

  Future<List<ExternalWorkout>> getWorkouts({
    required DateTime from,
    required DateTime to,
  }) async => await _healthService.readWorkouts(from: from, to: to);

  Future<double?> getLatestBodyFatPercent() async =>
      await _healthService.readLatestBodyFatPercent();
}
