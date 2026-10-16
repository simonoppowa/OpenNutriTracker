import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

/// Exports logged meals and their nutrients to Health Connect / Apple Health.
///
/// Opt-in: only runs when [ConfigEntity.healthExportEnabled] is true.
/// Failures to export are caught and logged so a health store issue never
/// interferes with saving food records locally.
class ExportMealIntakeUsecase {
  // TODO: Implement "Export now" backfill for historical date ranges (follow-up to issue #1245)
  // TODO: Implement hydration / water intake export to Health Connect / Apple Health (follow-up to issue #1245)

  static final _log = Logger('ExportMealIntakeUsecase');

  final HealthExportRepository _healthExportRepository;
  final ConfigRepository _configRepository;
  final IntakeRepository _intakeRepository;

  ExportMealIntakeUsecase(
    this._healthExportRepository,
    this._configRepository,
    this._intakeRepository,
  );

  /// Exports a single [IntakeEntity] to the connected health store if enabled.
  Future<bool> exportIntake(IntakeEntity intake) async {
    try {
      final config = await _configRepository.getConfig();
      if (!config.healthExportEnabled) return false;

      final externalIntake = ExternalMealIntake.fromIntake(intake);
      return await _healthExportRepository.writeMeal(externalIntake);
    } catch (error, stackTrace) {
      _log.warning('Failed to export intake ${intake.id}', error, stackTrace);
      return false;
    }
  }

  /// Deletes an exported intake from the health store when deleted in the app.
  ///
  /// Call after the intake has left the local repository.
  Future<bool> deleteIntake(IntakeEntity intake) async {
    try {
      final config = await _configRepository.getConfig();
      if (!config.healthExportEnabled) return false;

      final clientRecordId = 'ont_intake_${intake.id}';
      // iOS can only delete by time window, and one window can hold several
      // entries — a bulk add gives every row the same timestamp. Withholding
      // the window then leaves the record in Apple Health rather than erasing
      // meals the diary still has. Android deletes by record id regardless.
      final shared = await _windowHasOtherIntake(intake);
      return await _healthExportRepository.deleteMeal(
        clientRecordId,
        at: shared ? null : intake.dateTime,
      );
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to delete intake ${intake.id} from health store',
        error,
        stackTrace,
      );
      return false;
    }
  }

  /// Whether another diary entry starts inside [intake]'s iOS delete window,
  /// `[dateTime, dateTime + sampleDuration]`.
  Future<bool> _windowHasOtherIntake(IntakeEntity intake) async {
    final start = intake.dateTime;
    final end = start.add(ExternalMealIntake.sampleDuration);
    final intakes = await _intakeRepository.getAllIntakesDBO();
    return intakes.any(
      (other) =>
          other.id != intake.id &&
          !other.dateTime.isBefore(start) &&
          !other.dateTime.isAfter(end),
    );
  }
}
