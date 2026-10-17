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

  /// Re-exports [after], an edit of [before] that has already been stored.
  ///
  /// Health Connect upserts by record id, so the new payload replaces the old
  /// one. HealthKit has no such identity and deletes only by time window, so
  /// there every window the edit touches is replaced whole: deleted, then
  /// each diary entry starting in it rewritten — the edited one and any
  /// siblings — so nothing in it is lost or counted twice.
  Future<bool> exportUpdatedIntake(
    IntakeEntity before,
    IntakeEntity after,
  ) async {
    try {
      final config = await _configRepository.getConfig();
      if (!config.healthExportEnabled) return false;

      if (_healthExportRepository.upsertsByRecordId) {
        return await _healthExportRepository.writeMeal(
          ExternalMealIntake.fromIntake(after),
        );
      }

      final windows = {before.dateTime, after.dateTime};
      for (final start in windows) {
        final deleted = await _healthExportRepository.deleteMeal(
          'ont_intake_${after.id}',
          at: start,
        );
        // Rewriting over a window that is still there would double it.
        if (!deleted) return false;
      }

      final rewrites = <String, IntakeEntity>{};
      for (final start in windows) {
        for (final intake in await _intakesInWindow(start)) {
          rewrites[intake.id] = intake;
        }
      }
      rewrites[after.id] = after;

      var allWritten = true;
      for (final intake in rewrites.values) {
        final written = await _healthExportRepository.writeMeal(
          ExternalMealIntake.fromIntake(intake),
        );
        allWritten = allWritten && written;
      }
      return allWritten;
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to export edited intake ${after.id}',
        error,
        stackTrace,
      );
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

  /// Whether another diary entry starts inside [intake]'s iOS delete window.
  Future<bool> _windowHasOtherIntake(IntakeEntity intake) async {
    final inWindow = await _intakesInWindow(intake.dateTime);
    return inWindow.any((other) => other.id != intake.id);
  }

  /// The diary entries starting inside the iOS delete window that opens at
  /// [start], `[start, start + sampleDuration)`.
  Future<List<IntakeEntity>> _intakesInWindow(DateTime start) async {
    final end = start.add(ExternalMealIntake.sampleDuration);
    final intakes = await _intakeRepository.getAllIntakesDBO();
    return intakes
        .where(
          (intake) =>
              !intake.dateTime.isBefore(start) && intake.dateTime.isBefore(end),
        )
        .map(IntakeEntity.fromIntakeDBO)
        .toList();
  }
}
