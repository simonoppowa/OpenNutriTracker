import 'package:opennutritracker/core/data/data_source/health/health_export_records.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';

/// Thin, like [HealthImportRepository]: the service already speaks in
/// plugin-free terms.
class HealthExportRepository {
  final HealthService _healthService;

  HealthExportRepository(this._healthService);

  Future<bool> isAvailable() => _healthService.isAvailable();

  Future<bool> requestPermissions() =>
      _healthService.requestExportPermissions();

  Future<void> replaceDay({
    required DateTime from,
    required DateTime to,
    required List<ExportedMeal> meals,
    required List<ExportedWater> water,
  }) => _healthService.replaceExportedDay(
    from: from,
    to: to,
    meals: meals,
    water: water,
  );
}
