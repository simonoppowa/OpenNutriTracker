import 'dart:async';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_diary_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

/// Exports logged meals and their nutrients to Health Connect / Apple Health.
///
/// Writing is opt-in per profile: a meal is written only when the profile
/// whose diary changed has [ConfigEntity.healthExportEnabled] set, both when
/// the change is requested and when the queue gets to it, so a switch, or an
/// opt-out undone while the queue is busy, cannot write a change made
/// without consent. Removing a record needs no consent: a deleted entry's
/// record goes whether or not the profile still exports.
///
/// Each profile keeps an export ledger: for every entry the export wrote,
/// where the store holds its record. It is the durable account of the
/// store, kept apart from the diary. A record stays in it after its entry
/// is deleted until the store lets the record go, and keeps its old time
/// after an edit made while export was off — HealthKit finds a record only
/// by that time. Edits, merges and imports rewrite only ledger entries, so
/// nothing logged before an opt-in is backfilled by the way.
///
/// Operations run one at a time, in the order they were requested, so a
/// delete or an edit can never overtake the write it follows. Callers do not
/// await them, and a failure is logged and reported as false, so a health
/// store problem never holds up or breaks the diary.
///
/// Health Connect addresses records by client record id, so each operation
/// writes or deletes that one record. HealthKit cannot, and its only delete
/// removes every meal this app wrote starting in a one-minute window, from
/// any profile. There an operation replaces whole windows: it stores them as
/// pending first, reads every profile's ledger records in them, deletes the
/// windows, writes each consenting profile's entries back at their current
/// times, and only then drops the windows from the pending set. That is
/// idempotent, so whatever stops it part-way — a failed call, or the app
/// being killed — is put right by replaying the pending windows, which the
/// next operation and the next app start ([replayPendingWindows]) do. A
/// Health Connect delete that does not go through stays pending the same
/// way.
class ExportMealIntakeUsecase {
  // TODO: Implement "Export now" backfill for historical date ranges (follow-up to issue #1245)
  // TODO: Implement hydration / water intake export to Health Connect / Apple Health (follow-up to issue #1245)

  static final _log = Logger('ExportMealIntakeUsecase');

  /// Attempts per store call or window replacement, the first included.
  static const _attempts = 3;

  /// How many times a window replacement widens to the windows its entries
  /// move into before it gives up and leaves the lot pending.
  static const _maxWidenings = 4;

  final HealthExportRepository _healthExportRepository;
  final HealthExportDiaryRepository _diaryRepository;
  final ConfigRepository _configRepository;

  /// The pause before the first retry; each later one waits longer.
  final Duration _retryDelay;

  /// The tail of the operation queue. Never completes with an error.
  Future<void> _queue = Future.value();

  /// Numbers the diary operations in the order they are requested.
  int _requests = 0;

  /// Per profile, the first request number after its last [forgetProfile]:
  /// anything of that profile requested earlier and not yet run belongs to
  /// the storage being wiped, which [forgetProfile] has accounted for.
  final Map<String, int> _forgottenBefore = {};

  bool _forgotten(String owner, int request) =>
      request < (_forgottenBefore[owner] ?? 0);

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
    final request = _requests++;
    return _serialized('export intake ${intake.id}', () async {
      if (_forgotten(owner, request)) return false;
      if (!await _consents(owner, consent)) return false;
      // In the ledger before the write: it lists what the store should
      // hold, so a write that fails is redone by the next edit or rewrite.
      await _diaryRepository.updateLedger(
        owner,
        put: {intake.id: intake.dateTime},
      );
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
  /// (before, after) pair. Entries the store never received are skipped;
  /// without consent nothing is written and the ledger keeps where the old
  /// records are.
  Future<bool> exportUpdatedIntakes(List<(IntakeEntity, IntakeEntity)> edits) {
    final owner = _diaryRepository.activeProfileId;
    final consent = _consentNow(owner);
    final request = _requests++;
    return _serialized('export ${edits.length} edited intakes', () async {
      if (_forgotten(owner, request)) return false;
      if (edits.isEmpty) return false;
      if (!await _consents(owner, consent)) return false;
      final stored = await _diaryRepository.exportedAt(owner, {
        for (final (_, after) in edits) after.id,
      });
      if (stored.isEmpty) return true;
      if (!_healthExportRepository.hasRecordIdentity) {
        // Where the records are, not where the entries were before this
        // edit: an edit made while export was off moved the entry but not
        // its record.
        return _replaceWindows(stored.values.toSet());
      }
      await _drainRecordDeletes();
      var allWritten = true;
      for (final (_, after) in edits) {
        if (!stored.containsKey(after.id)) continue;
        final written = await _retrying(
          () => _healthExportRepository.writeMeal(
            ExternalMealIntake.fromIntake(after, profileId: owner),
          ),
        );
        if (written) {
          await _diaryRepository.updateLedger(
            owner,
            put: {after.id: after.dateTime},
          );
        }
        allWritten = allWritten && written;
      }
      return allWritten;
    });
  }

  /// Removes a deleted [intake]'s record. Call after it has left the diary.
  /// Needs no consent: the record goes even if the profile stopped
  /// exporting. Until it is gone, the ledger, or the pending deletes, keep
  /// what finds it.
  Future<bool> deleteIntake(IntakeEntity intake) {
    final owner = _diaryRepository.activeProfileId;
    final request = _requests++;
    return _serialized('delete intake ${intake.id}', () async {
      if (_forgotten(owner, request)) return false;
      final stored = await _diaryRepository.exportedAt(owner, {intake.id});
      final at = stored[intake.id];
      if (at == null) return true;
      if (!_healthExportRepository.hasRecordIdentity) {
        // The record leaves the ledger once its window is cleared.
        return _replaceWindows({at});
      }
      await _drainRecordDeletes();
      final recordId = ExternalMealIntake.recordIdOf(owner, intake.id);
      final deleted = await _retrying(
        () => _healthExportRepository.deleteMeal(recordId),
      );
      // Not deleted: the id moves to the pending deletes, which find the
      // record without the ledger.
      if (!deleted) {
        await _configRepository.updateHealthPendingRecordDeletes(
          add: {recordId},
        );
      }
      await _diaryRepository.updateLedger(owner, remove: {intake.id});
      return deleted;
    });
  }

  /// Removes every record [profileId] exported, ahead of that profile's
  /// storage being wiped or deleted.
  ///
  /// Reads the profile's ledger right away. It accounts for queued work as
  /// well as done work: a queued delete or edit leaves its record in the
  /// ledger, at its old time, until the queue gets to it, and the queued
  /// operations themselves are dropped. What has to go —
  /// Health Connect record ids, or HealthKit windows — is stored in the
  /// persisted pending sets before the ledger is emptied, so await this
  /// before destroying the boxes. Queued operations of the profile then find
  /// nothing of it in the ledger and leave the store alone; the deletions
  /// follow on the queue and stay pending until they succeed. Never throws,
  /// and never waits on the store: a health store problem must not stand in
  /// the way of a wipe the user asked for.
  Future<void> forgetProfile(String profileId) async {
    // Requested but not yet run, an operation of this profile would write
    // a meal of the storage being wiped after the ledger was read: it is
    // dropped instead. One already running put its record in the ledger
    // before writing it, so the read below finds it.
    _forgottenBefore[profileId] = _requests;
    try {
      final ledger = await _diaryRepository.ledgerOf(profileId);
      if (ledger.isEmpty) return;
      final byId = _healthExportRepository.hasRecordIdentity;
      if (byId) {
        await _configRepository.updateHealthPendingRecordDeletes(
          add: {
            for (final id in ledger.keys)
              ExternalMealIntake.recordIdOf(profileId, id),
          },
        );
      } else {
        await _configRepository.updateHealthPendingExportWindows(
          add: ledger.values.toSet(),
        );
      }
      await _diaryRepository.clearLedger(profileId);
      unawaited(
        _serialized(
          'remove the records of profile $profileId',
          () => byId
              ? _drainRecordDeletes()
              // The profile's entries may still be on disk when this runs,
              // so it is left out of the rewrite explicitly.
              : _replaceWindows(const {}, exceptProfile: profileId),
        ),
      );
    } catch (error, stackTrace) {
      _log.warning(
        'Could not record the exported meals of profile $profileId',
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

  /// Deletes every pending Health Connect record, dropping each from the
  /// pending set only once its delete succeeded.
  Future<bool> _drainRecordDeletes() async {
    final ids = await _readOrEmpty(
      _configRepository.getHealthPendingRecordDeletes,
      'pending record deletes',
    );
    if (ids.isEmpty) return true;
    final deleted = <String>{};
    for (final id in ids) {
      if (await _retrying(() => _healthExportRepository.deleteMeal(id))) {
        deleted.add(id);
      }
    }
    await _guarded(
      () => _configRepository.updateHealthPendingRecordDeletes(remove: deleted),
      'store pending record deletes',
    );
    return deleted.length == ids.length;
  }

  /// Runs [call] up to [_attempts] times until it reports success, treating
  /// a throw as a failure. Only for calls that are safe to repeat: a Health
  /// Connect write is an upsert, a delete is idempotent, and a HealthKit
  /// replacement redoes its windows whole.
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

  static bool _within(DateTime time, DateTime start) =>
      !time.isBefore(start) &&
      time.isBefore(start.add(ExternalMealIntake.sampleDuration));

  static bool _covered(DateTime time, Set<DateTime> starts) =>
      starts.any((start) => _within(time, start));

  /// Makes each HealthKit window opening at one of [requested], or still
  /// pending, hold exactly the records the ledgers say should start in it,
  /// with each consenting profile's entry rewritten at its current time.
  /// [exceptProfile]'s records are deleted with their windows and not read.
  ///
  /// The plugin deletes with HealthKit's `strictStartDate`, so a window's
  /// delete takes exactly the records that start inside it, which are the
  /// ledger records timed inside it. An entry rewritten at a time outside
  /// its old window pulls the window it moves into into the replacement,
  /// so a retry can clear what a failed attempt left there.
  Future<bool> _replaceWindows(
    Set<DateTime> requested, {
    String? exceptProfile,
  }) async {
    final windows = {
      ...requested,
      ...await _readOrEmpty(
        _configRepository.getHealthPendingExportWindows,
        'pending meal windows',
      ),
    };
    if (windows.isEmpty) return true;

    // Read everything before touching the store: a profile switch during
    // the read aborts here, with nothing deleted yet.
    var records = <LedgerRecord>[];
    for (var widenings = 0; ; widenings++) {
      try {
        records = await _diaryRepository.recordsInWindows(
          windows,
          ExternalMealIntake.sampleDuration,
          exceptProfile: exceptProfile,
        );
      } catch (_) {
        // Nothing touched; kept so the next operation tries again.
        await _guarded(
          () => _configRepository.updateHealthPendingExportWindows(
            add: windows,
          ),
          'store pending meal windows',
        );
        rethrow;
      }
      final movedTo = {
        for (final record in records)
          if (record.current != null &&
              record.consenting &&
              !_covered(record.current!.dateTime, windows))
            record.current!.dateTime,
      };
      if (movedTo.isEmpty) break;
      windows.addAll(movedTo);
      if (widenings == _maxWidenings) {
        await _configRepository.updateHealthPendingExportWindows(add: windows);
        return false;
      }
    }

    // Pending before the store is touched, so a stop part-way is replayed.
    // If even that cannot be stored, nothing is touched.
    await _configRepository.updateHealthPendingExportWindows(add: windows);

    // A profile that stopped exporting may still own a record in a window,
    // and its entry cannot be rewritten without its consent. Such a window
    // stays pending, and is rebuilt by the first replacement that finds the
    // profile exporting again or the entry gone.
    final blocked = {
      for (final start in windows)
        if (records.any(
          (record) =>
              _within(record.exportedAt, start) &&
              record.current != null &&
              !record.consenting,
        ))
          start,
    };
    if (blocked.isNotEmpty) {
      _log.info('Kept meal windows pending: they hold an opted-out profile');
    }
    final active = windows.difference(blocked);

    var done = false;
    for (var attempt = 1; ; attempt++) {
      final outcome = await _replaceOnce(active, records);
      records = outcome.records;
      done = outcome.complete;
      if (done || attempt == _attempts) break;
      await Future<void>.delayed(_retryDelay * attempt);
    }

    if (done) {
      await _guarded(
        () => _configRepository.updateHealthPendingExportWindows(
          remove: active,
        ),
        'store pending meal windows',
      );
    }
    return done && blocked.isEmpty;
  }

  /// One attempt: delete every window in [windows], then write back each
  /// consenting record whose window was cleared, and update the ledgers to
  /// match. Returns the records as they now stand.
  Future<({bool complete, List<LedgerRecord> records})> _replaceOnce(
    Set<DateTime> windows,
    List<LedgerRecord> records,
  ) async {
    final cleared = <DateTime>{};
    for (final start in windows) {
      try {
        if (await _healthExportRepository.deleteMealWindow(start)) {
          cleared.add(start);
        }
      } catch (error, stackTrace) {
        _log.fine('Clearing a meal window failed', error, stackTrace);
      }
    }
    var complete = cleared.length == windows.length;

    final after = <LedgerRecord>[];
    final put = <String, Map<String, DateTime>>{};
    final remove = <String, Set<String>>{};
    for (final record in records) {
      if (!_covered(record.exportedAt, cleared)) {
        after.add(record);
        continue;
      }
      final current = record.current;
      if (current == null) {
        // An orphan: its record went with the window.
        (remove[record.profileId] ??= {}).add(record.intakeId);
        continue;
      }
      if (!record.consenting) {
        after.add(record);
        continue;
      }
      var written = false;
      try {
        written = await _healthExportRepository.writeMeal(
          ExternalMealIntake.fromIntake(current, profileId: record.profileId),
        );
      } catch (error, stackTrace) {
        _log.fine('Rewriting a meal failed', error, stackTrace);
      }
      if (written) {
        final moved = record.rewritten();
        after.add(moved);
        (put[record.profileId] ??= {})[record.intakeId] = moved.exportedAt;
      } else {
        // Its old record is gone, and part of the new one may be in the
        // store: the next attempt clears its new window too, which the
        // widening made part of the replacement.
        after.add(record.rewritten());
        complete = false;
      }
    }
    for (final profileId in {...put.keys, ...remove.keys}) {
      await _guarded(
        () => _diaryRepository.updateLedger(
          profileId,
          put: put[profileId] ?? const {},
          remove: remove[profileId] ?? const {},
        ),
        'update the export ledger of profile $profileId',
      );
    }
    return (complete: complete, records: after);
  }

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
