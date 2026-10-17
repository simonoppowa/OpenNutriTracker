import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/repository/health_export_diary_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

/// Exports logged meals and their nutrients to Health Connect / Apple Health.
///
/// Opt-in per profile: an operation runs only when the profile that changed
/// its diary has [ConfigEntity.healthExportEnabled] set. The profile is the
/// one active when the operation is requested, so a later switch does not
/// move it under another profile's consent.
///
/// Operations run one at a time, in the order they were requested, so a
/// delete or an edit can never overtake the write it follows. Callers do not
/// await them, and a failure is logged and reported as false, so a health
/// store problem never holds up or breaks the diary.
///
/// Health Connect addresses records by client record id, so each operation
/// writes or deletes that one record. HealthKit cannot, and its only delete
/// removes every meal this app wrote in a one-minute window, from any
/// profile. There every operation instead makes the windows it touches match
/// the diaries: it reads what every profile still holds there, deletes the
/// window, and rewrites those entries. That is idempotent, so the order of
/// completion no longer matters either.
class ExportMealIntakeUsecase {
  // TODO: Implement "Export now" backfill for historical date ranges (follow-up to issue #1245)
  // TODO: Implement hydration / water intake export to Health Connect / Apple Health (follow-up to issue #1245)

  static final _log = Logger('ExportMealIntakeUsecase');

  final HealthExportRepository _healthExportRepository;
  final HealthExportDiaryRepository _diaryRepository;

  /// The tail of the operation queue. Never completes with an error.
  Future<void> _queue = Future.value();

  ExportMealIntakeUsecase(this._healthExportRepository, this._diaryRepository);

  /// Exports a newly logged [intake]. Call after it has been stored.
  Future<bool> exportIntake(IntakeEntity intake) {
    final profileId = _diaryRepository.activeProfileId;
    return _serialized('export intake ${intake.id}', () async {
      if (!await _diaryRepository.isExportEnabled(profileId)) return false;
      if (!_healthExportRepository.hasRecordIdentity) {
        return _replaceWindows({intake.dateTime});
      }
      return _healthExportRepository.writeMeal(
        ExternalMealIntake.fromIntake(intake),
      );
    });
  }

  /// Re-exports [after], an edit of [before]. Call after it has been stored.
  Future<bool> exportUpdatedIntake(IntakeEntity before, IntakeEntity after) =>
      exportUpdatedIntakes([(before, after)]);

  /// Re-exports a batch of stored edits, each as a (before, after) pair.
  Future<bool> exportUpdatedIntakes(List<(IntakeEntity, IntakeEntity)> edits) {
    final profileId = _diaryRepository.activeProfileId;
    return _serialized('export ${edits.length} edited intakes', () async {
      if (edits.isEmpty) return false;
      if (!await _diaryRepository.isExportEnabled(profileId)) return false;
      if (!_healthExportRepository.hasRecordIdentity) {
        return _replaceWindows({
          for (final (before, after) in edits) ...[
            before.dateTime,
            after.dateTime,
          ],
        });
      }
      var allWritten = true;
      for (final (_, after) in edits) {
        final written = await _healthExportRepository.writeMeal(
          ExternalMealIntake.fromIntake(after),
        );
        allWritten = allWritten && written;
      }
      return allWritten;
    });
  }

  /// Removes a deleted [intake]'s record. Call after it has left the diary.
  Future<bool> deleteIntake(IntakeEntity intake) {
    final profileId = _diaryRepository.activeProfileId;
    return _serialized('delete intake ${intake.id}', () async {
      if (!await _diaryRepository.isExportEnabled(profileId)) return false;
      if (!_healthExportRepository.hasRecordIdentity) {
        return _replaceWindows({intake.dateTime});
      }
      return _healthExportRepository.deleteMeal(
        ExternalMealIntake.recordIdOf(intake.id),
      );
    });
  }

  Future<bool> _serialized(String what, Future<bool> Function() operation) {
    final result = _queue
        .then((_) => operation())
        .then<bool>(
          (done) => done,
          onError: (Object error, StackTrace stackTrace) {
            _log.warning('Failed to $what', error, stackTrace);
            return false;
          },
        );
    _queue = result;
    return result;
  }

  /// Makes each HealthKit window opening at one of [starts] hold exactly the
  /// exporting profiles' diary entries that start in it.
  Future<bool> _replaceWindows(Set<DateTime> starts) async {
    // Read everything before touching the store: a profile switch during
    // the read aborts here, with nothing deleted yet.
    final snapshot = await _diaryRepository.snapshotWindows(
      starts,
      ExternalMealIntake.sampleDuration,
    );
    if (snapshot.hasOptedOutEntries) {
      // A profile that stopped exporting may still own a record in there,
      // and it cannot be rewritten without its consent.
      _log.info('Left a meal window alone: it holds an opted-out profile');
      return false;
    }

    var allWritten = true;
    // One window at a time, deleting before rewriting. Overlapping windows
    // still come out right: the second delete removes the overlap's rewrite
    // from the first, and the second rewrite puts it back once.
    for (final start in starts) {
      if (!await _healthExportRepository.deleteMealWindow(start)) return false;
      final end = start.add(ExternalMealIntake.sampleDuration);
      for (final intake in snapshot.exported) {
        final time = intake.dateTime;
        if (time.isBefore(start) || !time.isBefore(end)) continue;
        final written = await _healthExportRepository.writeMeal(
          ExternalMealIntake.fromIntake(intake),
        );
        allWritten = allWritten && written;
      }
    }
    return allWritten;
  }
}
