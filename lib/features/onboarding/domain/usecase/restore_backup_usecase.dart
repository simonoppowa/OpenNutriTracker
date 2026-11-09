import 'package:logging/logging.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';

/// How a restore from the onboarding intro page ended (#1355).
enum RestoreBackupOutcome {
  /// The backup's diary, recipes, weight log, favourites and goal settings
  /// are now in the profile being set up.
  restored,

  /// The user dismissed the file picker. Nothing was written.
  cancelled,

  /// The picked file is not a backup this app can read, or the import
  /// failed. [ImportDataUsecase] decodes every entry before it writes one,
  /// so a file that does not decode leaves the profile untouched.
  failed,

  /// The active profile already has a body profile, so it is not a new
  /// one. Refused before the picker opens, so nothing was written.
  profileHasData,
}

class RestoreBackupResult {
  final RestoreBackupOutcome outcome;

  /// Why the restore failed, for the message. Set only for
  /// [RestoreBackupOutcome.failed].
  final ExportImportFailureReason? failureReason;

  const RestoreBackupResult(this.outcome, [this.failureReason]);
}

/// Restores a JSON backup into the profile onboarding is setting up, so a
/// user moving phones does not have to finish the wizard before importing
/// (#1355).
///
/// It runs the same [ImportDataUsecase.importData] as Settings → Import,
/// with the same file names, so a backup is accepted or rejected exactly
/// as it is there. The backup carries no body profile (height, weight,
/// birthday, PAL, goal; see `docs/export-format.md`), so onboarding still
/// asks for those afterwards.
class RestoreBackupUsecase {
  static final _log = Logger('RestoreBackupUsecase');

  final ImportDataUsecase _importDataUsecase;

  /// Whether the active profile already has a body profile.
  final Future<bool> Function() _hasUserData;

  /// Recomputes and stores the goals of the tracked day for [day], as
  /// `SettingsBloc.updateTrackedDay` does.
  final Future<void> Function(DateTime day) _updateDayGoals;

  RestoreBackupUsecase(
    this._importDataUsecase, {
    required Future<bool> Function() hasUserData,
    required Future<void> Function(DateTime day) updateDayGoals,
  }) : _hasUserData = hasUserData,
       _updateDayGoals = updateDayGoals;

  /// Lets the user pick a backup and writes it to the active profile.
  ///
  /// Only the JSON bundle is offered: it is the format meant for restoring.
  /// The CSV bundle leaves out recipes, the weight log, favourites and the
  /// goal settings, and stays available under Settings → Import.
  Future<RestoreBackupResult> restore() async {
    // Onboarding always runs on a profile without a body profile: a first
    // run, a profile just added, or one the demo wiped. A profile that has
    // one is in use, and merging a backup into it from here would skip the
    // Settings dialog that says what an import does.
    if (await _hasUserData()) {
      return const RestoreBackupResult(RestoreBackupOutcome.profileHasData);
    }

    try {
      final imported = await _importDataUsecase.importData(
        ExportImportBloc.userActivityJsonFileName,
        ExportImportBloc.userIntakeJsonFileName,
        ExportImportBloc.trackedDayJsonFileName,
        ExportImportBloc.recipeJsonFileName,
        ExportImportBloc.weightLogJsonFileName,
        ExportImportBloc.customActivityTemplateJsonFileName,
        goalSettingsJsonFileName: ExportImportBloc.goalSettingsJsonFileName,
        favouriteJsonFileName: ExportImportBloc.favouriteJsonFileName,
      );
      if (imported) {
        return const RestoreBackupResult(RestoreBackupOutcome.restored);
      }
      // A profile switch overtook the import, which then wrote nothing.
      _log.warning('Restore abandoned: the active profile changed');
      return const RestoreBackupResult(
        RestoreBackupOutcome.failed,
        ExportImportFailureReason.unexpected,
      );
    } on ExportImportFailure catch (error, stackTrace) {
      if (error.reason == ExportImportFailureReason.cancelled) {
        return const RestoreBackupResult(RestoreBackupOutcome.cancelled);
      }
      _log.severe('Restore failed (${error.reason.name})', error, stackTrace);
      return RestoreBackupResult(RestoreBackupOutcome.failed, error.reason);
    } catch (error, stackTrace) {
      _log.severe('Restore failed (unexpected)', error, stackTrace);
      return const RestoreBackupResult(
        RestoreBackupOutcome.failed,
        ExportImportFailureReason.unexpected,
      );
    }
  }

  /// Recomputes today's goals once onboarding has saved the body profile.
  ///
  /// Settings → Import does this right after the import, but during
  /// onboarding there is no body profile yet to compute a goal from. Until
  /// this runs, a row for today that came with the backup still holds the
  /// goals of the device it was exported on, and the Diary reads them off
  /// that row. A failure is logged: the data is already restored, and Home
  /// computes today's goal live.
  Future<void> syncTodayGoals() async {
    try {
      await _updateDayGoals(DateTime.now());
    } catch (error, stackTrace) {
      _log.warning(
        "Could not recompute today's goals after the restore",
        error,
        stackTrace,
      );
    }
  }
}
