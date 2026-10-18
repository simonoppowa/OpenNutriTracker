import 'dart:async';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
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
///
/// Every store call is retried a couple of times with a growing delay. A
/// HealthKit window that still does not come out whole — its delete failed,
/// one of its rewrites failed, or the diaries could not be read — is kept in
/// a persisted pending set, which the next HealthKit operation and the next
/// app start ([replayPendingWindows]) take up again.
class ExportMealIntakeUsecase {
  // TODO: Implement "Export now" backfill for historical date ranges (follow-up to issue #1245)
  // TODO: Implement hydration / water intake export to Health Connect / Apple Health (follow-up to issue #1245)

  static final _log = Logger('ExportMealIntakeUsecase');

  /// Attempts per store call, the first included.
  static const _attempts = 3;

  final HealthExportRepository _healthExportRepository;
  final HealthExportDiaryRepository _diaryRepository;
  final ConfigRepository _configRepository;

  /// The pause before the first retry; each later one waits longer.
  final Duration _retryDelay;

  /// The tail of the operation queue. Never completes with an error.
  Future<void> _queue = Future.value();

  ExportMealIntakeUsecase(
    this._healthExportRepository,
    this._diaryRepository,
    this._configRepository, {
    Duration retryDelay = const Duration(milliseconds: 500),
  }) : _retryDelay = retryDelay;

  /// Exports a newly logged [intake]. Call after it has been stored.
  Future<bool> exportIntake(IntakeEntity intake) {
    final profileId = _diaryRepository.activeProfileId;
    return _serialized('export intake ${intake.id}', () async {
      if (!await _diaryRepository.isExportEnabled(profileId)) return false;
      if (!_healthExportRepository.hasRecordIdentity) {
        return _replaceWindows({intake.dateTime});
      }
      return _retrying(
        () => _healthExportRepository.writeMeal(
          ExternalMealIntake.fromIntake(intake),
        ),
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
        final written = await _retrying(
          () => _healthExportRepository.writeMeal(
            ExternalMealIntake.fromIntake(after),
          ),
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
      return _retrying(
        () => _healthExportRepository.deleteMeal(
          ExternalMealIntake.recordIdOf(intake.id),
        ),
      );
    });
  }

  /// Queues the removal of every record [profileId] exported, ahead of that
  /// profile's storage being wiped or deleted, which takes the ids and times
  /// that address the records with it.
  ///
  /// Reads the diary right away, so await this before destroying the boxes;
  /// the deletions themselves run on the queue. Never throws: a health store
  /// problem must not stand in the way of a wipe the user asked for.
  Future<void> forgetProfile(String profileId) async {
    try {
      final diary = await _diaryRepository.readProfile(profileId);
      // Never opted in: nothing of this profile is in the store.
      if (diary == null || diary.exportEnabled == null) return;
      final intakes = diary.intakes;
      if (intakes.isEmpty) return;
      unawaited(
        _serialized('remove the records of profile $profileId', () async {
          if (!_healthExportRepository.hasRecordIdentity) {
            // The wiped profile's entries may still be on disk when this
            // runs, so it is left out of the rewrite explicitly.
            return _replaceWindows({
              for (final intake in intakes) intake.dateTime,
            }, exceptProfile: profileId);
          }
          var allDeleted = true;
          for (final intake in intakes) {
            final deleted = await _retrying(
              () => _healthExportRepository.deleteMeal(
                ExternalMealIntake.recordIdOf(intake.id),
              ),
            );
            allDeleted = allDeleted && deleted;
          }
          return allDeleted;
        }),
      );
    } catch (error, stackTrace) {
      _log.warning(
        'Could not read profile $profileId to remove its exported meals',
        error,
        stackTrace,
      );
    }
  }

  /// Takes up the HealthKit windows a failure left behind. Called on app
  /// start; every HealthKit operation also takes them up along the way.
  Future<bool> replayPendingWindows() =>
      _serialized('replay pending meal windows', () async {
        if (_healthExportRepository.hasRecordIdentity) return true;
        return _replaceWindows(const {});
      });

  /// Runs [call] up to [_attempts] times until it reports success, treating
  /// a throw as a failure.
  Future<bool> _retrying(Future<bool> Function() call) async {
    for (var attempt = 1; ; attempt++) {
      try {
        if (await call()) return true;
      } catch (error, stackTrace) {
        _log.fine('Health store call failed', error, stackTrace);
      }
      if (attempt == _attempts) return false;
      await Future<void>.delayed(_retryDelay * attempt);
    }
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

  /// Makes each HealthKit window opening at one of [requested], or still
  /// pending from an earlier failure, hold exactly the exporting profiles'
  /// diary entries that start in it. [exceptProfile]'s entries are left out.
  Future<bool> _replaceWindows(
    Set<DateTime> requested, {
    String? exceptProfile,
  }) async {
    final pending = await _readPending();
    final starts = {...requested, ...pending};
    if (starts.isEmpty) return true;

    // Read everything before touching the store: a profile switch during
    // the read aborts here, with nothing deleted yet.
    final ExportWindowSnapshot snapshot;
    try {
      snapshot = await _diaryRepository.snapshotWindows(
        starts,
        ExternalMealIntake.sampleDuration,
        exceptProfile: exceptProfile,
      );
    } catch (_) {
      await _writePending(starts);
      rethrow;
    }

    var allDone = true;
    // One window at a time, deleting before rewriting. Overlapping windows
    // still come out right: the second delete removes the overlap's rewrite
    // from the first, and the second rewrite puts it back once.
    for (final start in starts) {
      final end = start.add(ExternalMealIntake.sampleDuration);
      bool inside(IntakeEntity intake) =>
          !intake.dateTime.isBefore(start) && intake.dateTime.isBefore(end);

      if (snapshot.optedOut.any(inside)) {
        // A profile that stopped exporting may still own a record in here,
        // and it cannot be rewritten without its consent. Retrying cannot
        // change that, so the window is dropped rather than kept pending.
        _log.info('Left a meal window alone: it holds an opted-out profile');
        pending.remove(start);
        allDone = false;
        continue;
      }

      var done = await _retrying(
        () => _healthExportRepository.deleteMealWindow(start),
      );
      if (done) {
        for (final intake in snapshot.exported.where(inside)) {
          final written = await _retrying(
            () => _healthExportRepository.writeMeal(
              ExternalMealIntake.fromIntake(intake),
            ),
          );
          done = done && written;
        }
      }
      if (done) {
        pending.remove(start);
      } else {
        pending.add(start);
        allDone = false;
      }
    }
    await _writePending(pending);
    return allDone;
  }

  Future<Set<DateTime>> _readPending() async {
    try {
      return await _configRepository.getHealthPendingExportWindows();
    } catch (error, stackTrace) {
      _log.warning('Could not read pending meal windows', error, stackTrace);
      return {};
    }
  }

  Future<void> _writePending(Set<DateTime> windows) async {
    try {
      await _configRepository.setHealthPendingExportWindows(windows);
    } catch (error, stackTrace) {
      _log.warning('Could not store pending meal windows', error, stackTrace);
    }
  }
}
