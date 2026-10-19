import 'dart:async';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_diary_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

/// Exports logged meals and their nutrients to Health Connect / Apple Health.
///
/// Opt-in per profile: an operation runs only when the profile whose diary
/// changed has [ConfigEntity.healthExportEnabled] set, both when the
/// operation is requested and when it runs, so a switch, or an opt-out that
/// is undone while the queue is busy, cannot move a change under consent it
/// was made without.
///
/// Only new entries are written as such. Each profile keeps an export
/// ledger of the entries the export has put in the store; edits, merges,
/// imports and HealthKit window rewrites touch only ledger entries, so
/// nothing logged before an opt-in is ever backfilled by the way.
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
/// the diaries: it reads what every profile has exported there, deletes the
/// window, and rewrites those entries. That is idempotent, so the order of
/// completion no longer matters either.
///
/// Store calls are retried a couple of times with a growing delay; on
/// HealthKit the retry is the whole window, delete and rewrites together. A
/// window that still does not come out whole — its delete failed, one of its
/// rewrites failed, the diaries could not be read, or an opted-out profile
/// blocks it — is kept in a persisted pending set, and so is every Health
/// Connect delete that did not go through. The next operation and the next
/// app start ([replayPendingWindows]) take them up.
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

  /// Exports a newly logged [intake] of [profileId], the active profile by
  /// default. Call after it has been stored.
  Future<bool> exportIntake(IntakeEntity intake, {String? profileId}) {
    final owner = profileId ?? _diaryRepository.activeProfileId;
    final consent = _consentNow(owner);
    return _serialized('export intake ${intake.id}', () async {
      if (!await _consents(owner, consent)) return false;
      // Marked before the write: the ledger lists what the store should
      // hold, so a write that fails is redone by the next edit or rewrite.
      await _diaryRepository.updateLedger(owner, add: {intake.id});
      if (!_healthExportRepository.hasRecordIdentity) {
        return _replaceWindows({intake.dateTime});
      }
      await _drainRecordDeletes();
      return _retrying(
        () => _healthExportRepository.writeMeal(
          ExternalMealIntake.fromIntake(intake, profileId: owner),
        ),
      );
    });
  }

  /// Re-exports [after], an edit of [before]. Call after it has been stored.
  Future<bool> exportUpdatedIntake(IntakeEntity before, IntakeEntity after) =>
      exportUpdatedIntakes([(before, after)]);

  /// Re-exports a batch of stored edits of the active profile, each as a
  /// (before, after) pair. Entries the store never received are skipped.
  Future<bool> exportUpdatedIntakes(List<(IntakeEntity, IntakeEntity)> edits) {
    final owner = _diaryRepository.activeProfileId;
    final consent = _consentNow(owner);
    return _serialized('export ${edits.length} edited intakes', () async {
      if (edits.isEmpty) return false;
      if (!await _consents(owner, consent)) return false;
      final exported = await _diaryRepository.exportedAmong(owner, {
        for (final (_, after) in edits) after.id,
      });
      final relevant = [
        for (final edit in edits)
          if (exported.contains(edit.$2.id)) edit,
      ];
      if (relevant.isEmpty) return true;
      if (!_healthExportRepository.hasRecordIdentity) {
        return _replaceWindows({
          for (final (before, after) in relevant) ...[
            before.dateTime,
            after.dateTime,
          ],
        });
      }
      await _drainRecordDeletes();
      var allWritten = true;
      for (final (_, after) in relevant) {
        final written = await _retrying(
          () => _healthExportRepository.writeMeal(
            ExternalMealIntake.fromIntake(after, profileId: owner),
          ),
        );
        allWritten = allWritten && written;
      }
      return allWritten;
    });
  }

  /// Removes a deleted [intake]'s record. Call after it has left the diary.
  Future<bool> deleteIntake(IntakeEntity intake) {
    final owner = _diaryRepository.activeProfileId;
    final consent = _consentNow(owner);
    return _serialized('delete intake ${intake.id}', () async {
      final wasExported = (await _diaryRepository.exportedAmong(owner, {
        intake.id,
      })).isNotEmpty;
      await _diaryRepository.updateLedger(owner, remove: {intake.id});
      if (!wasExported) return true;
      if (!await _consents(owner, consent)) return false;
      if (!_healthExportRepository.hasRecordIdentity) {
        return _replaceWindows({intake.dateTime});
      }
      await _drainRecordDeletes();
      final recordId = ExternalMealIntake.recordIdOf(owner, intake.id);
      final deleted = await _retrying(
        () => _healthExportRepository.deleteMeal(recordId),
      );
      // The diary row is gone, so this id is the only way left to reach the
      // record: keep it until a delete goes through.
      if (!deleted) await _storePendingDeletes(add: {recordId});
      return deleted;
    });
  }

  /// Queues the removal of every record [profileId] exported, ahead of that
  /// profile's storage being wiped or deleted, which takes the ids and times
  /// that address the records with it.
  ///
  /// Reads the diary right away and stores what has to go — Health Connect
  /// record ids, or HealthKit windows — in the persisted pending sets, then
  /// empties the profile's ledger, so await this before destroying the
  /// boxes. The deletions run on the queue, and whatever does not succeed
  /// stays pending for the next health operation or app start. Never throws:
  /// a health store problem must not stand in the way of a wipe the user
  /// asked for.
  Future<void> forgetProfile(String profileId) async {
    try {
      final diary = await _diaryRepository.readProfile(profileId);
      final exported = diary?.exported ?? const <IntakeEntity>[];
      if (exported.isEmpty) return;

      if (_healthExportRepository.hasRecordIdentity) {
        final ids = {
          for (final intake in exported)
            ExternalMealIntake.recordIdOf(profileId, intake.id),
        };
        await _storePendingDeletes(add: ids);
        unawaited(
          _serialized(
            'remove the records of profile $profileId',
            () => _drainRecordDeletes(also: ids),
          ),
        );
      } else {
        final windows = {for (final intake in exported) intake.dateTime};
        await _storePendingWindows(add: windows);
        unawaited(
          _serialized(
            'remove the records of profile $profileId',
            // The wiped profile's entries may still be on disk when this
            // runs, so it is left out of the rewrite explicitly.
            () => _replaceWindows(windows, exceptProfile: profileId),
          ),
        );
      }
      await _guarded(
        () => _diaryRepository.clearLedger(profileId),
        'clear the export ledger of profile $profileId',
      );
    } catch (error, stackTrace) {
      _log.warning(
        'Could not read profile $profileId to remove its exported meals',
        error,
        stackTrace,
      );
    }
  }

  /// Takes up whatever a failure left pending: Health Connect record deletes
  /// or HealthKit windows. Called on app start; every later operation takes
  /// them up along the way too.
  Future<bool> replayPendingWindows() =>
      _serialized('replay pending health exports', () async {
        if (_healthExportRepository.hasRecordIdentity) {
          return _drainRecordDeletes();
        }
        return _replaceWindows(const {});
      });

  /// [owner]'s opt-in as stored right now. For the active profile the read
  /// happens before this returns; a failed read counts as no consent.
  Future<bool> _consentNow(String owner) =>
      _diaryRepository.isExportEnabled(owner).catchError((Object _) => false);

  /// Whether [owner] consented both when the operation was requested and
  /// now, as it runs.
  Future<bool> _consents(String owner, Future<bool> atRequest) async =>
      await atRequest && await _diaryRepository.isExportEnabled(owner);

  /// Deletes every pending Health Connect record, plus [also], dropping each
  /// from the pending set only once its delete succeeded.
  Future<bool> _drainRecordDeletes({Set<String> also = const {}}) async {
    final ids = {
      ...await _readOrEmpty(
        _configRepository.getHealthPendingRecordDeletes,
        'pending record deletes',
      ),
      ...also,
    };
    if (ids.isEmpty) return true;
    final deleted = <String>{};
    for (final id in ids) {
      if (await _retrying(() => _healthExportRepository.deleteMeal(id))) {
        deleted.add(id);
      }
    }
    await _storePendingDeletes(add: ids.difference(deleted), remove: deleted);
    return deleted.length == ids.length;
  }

  /// Runs [call] up to [_attempts] times until it reports success, treating
  /// a throw as a failure. Only for calls that are safe to repeat: a Health
  /// Connect write is an upsert, a delete is idempotent, and a HealthKit
  /// window is retried whole, never one of its writes alone.
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
  /// pending from an earlier failure, hold exactly the exported diary
  /// entries of exporting profiles that start in it. [exceptProfile]'s
  /// entries are left out.
  ///
  /// The plugin deletes with HealthKit's `strictStartDate`, so a window's
  /// delete takes only meals that start inside it; a meal that starts
  /// earlier and runs into it is untouched, and so is not rewritten here.
  Future<bool> _replaceWindows(
    Set<DateTime> requested, {
    String? exceptProfile,
  }) async {
    final starts = {
      ...requested,
      ...await _readOrEmpty(
        _configRepository.getHealthPendingExportWindows,
        'pending meal windows',
      ),
    };
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
      await _storePendingWindows(add: starts);
      rethrow;
    }

    final done = <DateTime>{};
    final failed = <DateTime>{};
    // One window at a time, deleting before rewriting. Overlapping windows
    // still come out right: the second delete removes the overlap's rewrite
    // from the first, and the second rewrite puts it back once.
    for (final start in starts) {
      final end = start.add(ExternalMealIntake.sampleDuration);
      bool inside(IntakeEntity intake) =>
          !intake.dateTime.isBefore(start) && intake.dateTime.isBefore(end);

      if (snapshot.blocked.any(inside)) {
        // A profile that stopped exporting may still own a record in here,
        // and it cannot be rewritten without its consent. The window stays
        // pending, blocked, and is rebuilt by the first operation that finds
        // that profile exporting again or its entries gone.
        _log.info('Kept a meal window pending: it holds an opted-out profile');
        failed.add(start);
        continue;
      }

      final entries = [
        for (final entry in snapshot.exported)
          if (inside(entry.intake)) entry,
      ];
      // Retried whole: a write that failed may have saved part of a meal,
      // and only deleting the window again keeps the retry from doubling it.
      final replaced = await _retrying(() => _replaceWindow(start, entries));
      (replaced ? done : failed).add(start);
    }
    await _storePendingWindows(add: failed, remove: done);
    return failed.isEmpty;
  }

  /// One attempt at clearing the window at [start] and writing [entries]
  /// into it, stopping at the first failure.
  Future<bool> _replaceWindow(
    DateTime start,
    List<ProfileIntake> entries,
  ) async {
    if (!await _healthExportRepository.deleteMealWindow(start)) return false;
    for (final entry in entries) {
      final written = await _healthExportRepository.writeMeal(
        ExternalMealIntake.fromIntake(entry.intake, profileId: entry.profileId),
      );
      if (!written) return false;
    }
    return true;
  }

  Future<void> _storePendingWindows({
    Set<DateTime> add = const {},
    Set<DateTime> remove = const {},
  }) => _guarded(
    () => _configRepository.updateHealthPendingExportWindows(
      add: add,
      remove: remove,
    ),
    'store pending meal windows',
  );

  Future<void> _storePendingDeletes({
    Set<String> add = const {},
    Set<String> remove = const {},
  }) => _guarded(
    () => _configRepository.updateHealthPendingRecordDeletes(
      add: add,
      remove: remove,
    ),
    'store pending record deletes',
  );

  Future<Set<T>> _readOrEmpty<T>(
    Future<Set<T>> Function() read,
    String what,
  ) async {
    try {
      return await read();
    } catch (error, stackTrace) {
      _log.warning('Could not read $what', error, stackTrace);
      return {};
    }
  }

  Future<void> _guarded(Future<void> Function() step, String what) async {
    try {
      await step();
    } catch (error, stackTrace) {
      _log.warning('Could not $what', error, stackTrace);
    }
  }
}
