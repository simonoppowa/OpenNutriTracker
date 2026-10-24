import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';

/// Repository over the platform health store for nutrition export.
///
/// Thin by design — [HealthService] already speaks in plugin-free terms, so
/// there is nothing to translate here. It exists so the export use case
/// depends on a repository like every other use case in the app does, rather
/// than reaching into a data source directly.
class HealthExportRepository {
  final HealthService _healthService;

  HealthExportRepository(this._healthService);

  Future<bool> isAvailable() async => await _healthService.isAvailable();

  Future<bool> requestPermissions() async =>
      await _healthService.requestNutritionWritePermissions();

  bool get hasRecordIdentity => _healthService.hasRecordIdentity;

  Future<bool> writeMeal(ExternalMealIntake intake) async =>
      await _healthService.writeMeal(intake);

  Future<bool> deleteMeal(String clientRecordId) async =>
      await _healthService.deleteMeal(clientRecordId);

  Future<bool> deleteMealWindow(DateTime start) async =>
      await _healthService.deleteMealWindow(start);
}
