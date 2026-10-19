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
/// next operation and the next app start ([replayPendingWindows]) do.
/// Health Connect writes and deletes are stored as pending before they are
/// tried and leave the pending sets only once they went through, so they are
/// replayed the same way.
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

  /// Per profile, how many times [forgetProfile] has run. Work that started
  /// before a wipe of a profile compares this to drop what it would still
  /// do for that profile: no ledger writes, no rewrites, and no clearing of
  /// pending windows the wipe may have added.
  final Map<String, int> _wipes = {};

  Map<String, int> _wipesNow() => Map.of(_wipes);

  bool _wipedSince(String profileId, Map<String, int> before) =>
      (_wipes[profileId] ?? 0) != (before[profileId] ?? 0);

  bool _anyWipeSince(Map<String, int> before) =>
      _wipes.keys.any((profileId) => _wipedSince(profileId, before));

  static String _writeKey(String profileId, String intakeId) =>
      '$profileId/$intakeId';

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
      final wipes = _wipesNow();
      final start = ExternalMealIntake.recordStart(intake.dateTime);
      if (!_healthExportRepository.hasRecordIdentity) {
        // The window is pending before the ledger names it, so a stop in
        // between still writes the meal on replay.
        await _configRepository.updateHealthPendingExportWindows(add: {start});
        await _diaryRepository.updateLedger(owner, put: {intake.id: start});
        return _replaceWindows({start});
      }
      await _drainPendingRecords();
      return _writeRecords(owner, [intake], wipes);
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
      final wipes = _wipesNow();
      await _drainPendingRecords();
      return _writeRecords(owner, [
        for (final (_, after) in edits)
          if (stored.containsKey(after.id)) after,
      ], wipes);
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
      // Pending before the attempt, and off the ledger after it is: from
      // here the pending deletes find the record, and only a confirmed
      // delete drops it.
      await _configRepository.updateHealthPendingRecordDeletes(
        add: {ExternalMealIntake.recordIdOf(owner, intake.id)},
      );
      await _configRepository.updateHealthPendingRecordWrites(
        remove: {_writeKey(owner, intake.id)},
      );
      await _diaryRepository.updateLedger(owner, remove: {intake.id});
      return _drainPendingRecords();
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
    // Work already running past that point leaves this profile alone from
    // here on.
    _wipes[profileId] = (_wipes[profileId] ?? 0) + 1;
    try {
      // A write that never landed has nothing to delete, and must not land.
      final writes = await _configRepository.getHealthPendingRecordWrites();
      await _configRepository.updateHealthPendingRecordWrites(
        remove: {
          for (final key in writes)
            if (key.startsWith('$profileId/')) key,
        },
      );
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
              ? _drainPendingRecords()
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

  /// Takes up whatever a failure left pending: Health Connect record writes
  /// and deletes, or HealthKit windows. Called on app start; every later
  /// operation takes them up along the way too.
  Future<bool> replayPendingWindows() =>
      _serialized('replay pending health exports', () async {
        if (_healthExportRepository.hasRecordIdentity) {
          return _drainPendingRecords();
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

  /// Writes [intakes] of [owner] to Health Connect. Each is a pending write
  /// before the attempt; it joins the ledger, and leaves the pending set,
  /// only once written. If the pending writes cannot be stored, nothing is
  /// written.
  Future<bool> _writeRecords(
    String owner,
    List<IntakeEntity> intakes,
    Map<String, int> wipes,
  ) async {
    if (intakes.isEmpty) return true;
    await _configRepository.updateHealthPendingRecordWrites(
      add: {for (final intake in intakes) _writeKey(owner, intake.id)},
    );
    var allWritten = true;
    for (final intake in intakes) {
      allWritten = await _writeRecord(owner, intake, wipes) && allWritten;
    }
    return allWritten;
  }

  /// One pending Health Connect write: the write, then the ledger, then off
  /// the pending set. A failure leaves it pending for the next replay.
  Future<bool> _writeRecord(
    String owner,
    IntakeEntity intake,
    Map<String, int> wipes,
  ) async {
    final key = _writeKey(owner, intake.id);
    final recordId = ExternalMealIntake.recordIdOf(owner, intake.id);
    final written = await _retrying(
      () => _healthExportRepository.writeMeal(
        ExternalMealIntake.fromIntake(intake, profileId: owner),
      ),
    );
    if (!written) return false;
    if (_wipedSince(owner, wipes)) {
      // The profile was wiped while this was being written: the record
      // belongs to storage that is gone, so it goes too.
      await _configRepository.updateHealthPendingRecordDeletes(
        add: {recordId},
      );
      await _configRepository.updateHealthPendingRecordWrites(remove: {key});
      return false;
    }
    await _diaryRepository.updateLedger(
      owner,
      put: {intake.id: ExternalMealIntake.recordStart(intake.dateTime)},
    );
    await _configRepository.updateHealthPendingRecordWrites(remove: {key});
    return true;
  }

  /// Takes up pending Health Connect deletes, then pending writes.
  Future<bool> _drainPendingRecords() async {
    final deleted = await _drainRecordDeletes();
    final written = await _drainRecordWrites();
    return deleted && written;
  }

  /// Writes every pending Health Connect write whose profile exports and
  /// whose entry is still in its diary. One whose entry is gone is dropped;
  /// one whose profile has stopped exporting waits.
  Future<bool> _drainRecordWrites() async {
    final keys = await _readOrEmpty(
      _configRepository.getHealthPendingRecordWrites,
      'pending record writes',
    );
    var allWritten = true;
    for (final key in keys) {
      final slash = key.indexOf('/');
      final owner = key.substring(0, slash);
      final intakeId = key.substring(slash + 1);
      final wipes = _wipesNow();
      if (!await _diaryRepository.isExportEnabled(owner)) {
        allWritten = false;
        continue;
      }
      final intake = await _diaryRepository.intakeOf(owner, intakeId);
      if (intake == null) {
        await _configRepository.updateHealthPendingRecordWrites(
          remove: {key},
        );
        continue;
      }
      allWritten = await _writeRecord(owner, intake, wipes) && allWritten;
    }
    return allWritten;
  }

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
    await _configRepository.updateHealthPendingRecordDeletes(remove: deleted);
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
    final wipes = _wipesNow();

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
              !_covered(record.currentStart, windows))
            record.currentStart,
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
      final outcome = await _replaceOnce(active, records, wipes);
      records = outcome.records;
      done = outcome.complete;
      if (done || attempt == _attempts) break;
      await Future<void>.delayed(_retryDelay * attempt);
    }

    // A wipe that landed meanwhile added its windows to the pending set, and
    // perhaps some of these; they are its to clear, not this replacement's.
    if (_anyWipeSince(wipes)) return false;
    if (done) {
      await _configRepository.updateHealthPendingExportWindows(remove: active);
    }
    return done && blocked.isEmpty;
  }

  /// One attempt: delete every window in [windows], then write back each
  /// consenting record whose window was cleared, and update the ledgers to
  /// match. Returns the records as they now stand.
  Future<({bool complete, List<LedgerRecord> records})> _replaceOnce(
    Set<DateTime> windows,
    List<LedgerRecord> records,
    Map<String, int> wipes,
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
      if (_wipedSince(record.profileId, wipes)) {
        // Wiped meanwhile: its record went with the window, and its ledger
        // is the wipe's.
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
      if (_wipedSince(profileId, wipes)) continue;
      try {
        await _diaryRepository.updateLedger(
          profileId,
          put: put[profileId] ?? const {},
          remove: remove[profileId] ?? const {},
        );
      } catch (error, stackTrace) {
        // The store and the ledger now disagree on where a record is, so the
        // windows stay pending until a replacement gets both written.
        _log.warning('Could not update an export ledger', error, stackTrace);
        complete = false;
      }
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
