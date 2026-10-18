import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:opennutritracker/core/data/data_source/health/external_weight.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// Pulls body weight readings out of Health Connect / Apple Health and files
/// them in the weight log.
///
/// This is how a smart scale reaches the app, whether its companion app
/// writes to the health store directly or an aggregator such as Health Sync
/// copies the readings there from Garmin, Fitbit, Withings and the like.
///
/// The weight log holds one entry per calendar day, so each day keeps its
/// latest reading. Three rules decide what may be written:
///
///  * a weight the user entered for a day is never replaced — an imported
///    entry is marked by [WeightLogEntity.externalId], a manual one is not;
///  * an imported entry is replaced by a later reading from the same day;
///  * a day whose latest reading the user deleted stays empty until a newer
///    reading arrives (see `DeleteWeightLogUsecase`).
///
/// When the newest entry in the whole log came from this run, and is newer
/// than the weight the user gave, it also becomes the user's current weight,
/// which is what BMI and the calorie goal use.
///
/// Scheduling mirrors [ImportWorkoutsUsecase]: [importIfDue] at app start and
/// resume, debounced and failure-swallowing; [importNow] from the settings
/// screen, serialized per profile and throwing.
class ImportWeightsUsecase {
  /// How far each run reads back past the watermark, for readings a scale's
  /// app syncs to the health store some time after they were taken.
  static const overlapTolerance = Duration(hours: 24);

  /// Debounce for [importIfDue].
  static const minimumInterval = Duration(minutes: 15);

  /// Pinned by tests; production never assigns it.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  final _log = Logger('ImportWeightsUsecase');

  /// The run in flight for each profile. Keyed by profile rather than kept
  /// in one slot: a switch away and back while a run is still reading must
  /// join that run, not start a second one for the same profile whose older
  /// snapshot could then land after the newer run's writes.
  final _inFlight = <String, Future<int>>{};

  final _weightsImported = StreamController<void>.broadcast();

  /// Fires after a run that changed the weight data: it filed readings, or
  /// it moved the user's current weight. Screens that keep their own copy of
  /// the log, and the refresh a weight change sets off, listen to it. The
  /// count a run returns does not cover the second case — a retry that only
  /// finishes an interrupted run files nothing — so callers should not rely
  /// on it for that.
  Stream<void> get weightsImported => _weightsImported.stream;

  final HealthImportRepository _healthImportRepository;
  final ConfigRepository _configRepository;
  final WeightLogRepository _weightLogRepository;
  final UserRepository _userRepository;
  final HiveDBProvider _hiveDBProvider;

  ImportWeightsUsecase(
    this._healthImportRepository,
    this._configRepository,
    this._weightLogRepository,
    this._userRepository,
    this._hiveDBProvider,
  );

  /// Runs an import if weight import is on and the last one is not too
  /// recent. Logs and swallows failures — nobody is waiting on the answer.
  Future<int> importIfDue() async {
    try {
      final inFlight = _inFlight[_hiveDBProvider.activeProfileId];
      if (inFlight != null) return await inFlight;
      final config = await _configRepository.getConfig();
      if (!config.healthWeightImportEnabled) return 0;
      final lastImportAt = config.healthWeightLastImportAt;
      if (lastImportAt != null &&
          clock().difference(lastImportAt) < minimumInterval) {
        return 0;
      }
      return await importNow();
    } catch (error, stackTrace) {
      _log.severe('Background weight import failed', error, stackTrace);
      return 0;
    }
  }

  /// Imports the readings in the window and returns how many days were
  /// written. Returns 0 without touching the platform when weight import is
  /// off, and throws whatever the health store throws.
  Future<int> importNow() {
    final profileId = _hiveDBProvider.activeProfileId;
    final inFlight = _inFlight[profileId];
    if (inFlight != null) return inFlight;
    final run = _import();
    _inFlight[profileId] = run;
    return run.whenComplete(() {
      if (identical(_inFlight[profileId], run)) _inFlight.remove(profileId);
    });
  }

  Future<int> _import() async {
    final profileId = _hiveDBProvider.activeProfileId;
    final config = await _configRepository.getConfig();
    if (!config.healthWeightImportEnabled) return 0;

    final to = clock();
    final from = readWindowStart(
      now: to,
      lastImportAt: config.healthWeightLastImportAt,
    );

    final readings = await _healthImportRepository.getWeights(
      from: from,
      to: to,
    );
    if (!_stillOnProfile(profileId)) return 0;

    // The day each record id is already filed on. A reading keeps that day:
    // re-read after the device's time zone changed, the same instant can
    // fall on another local calendar day, and filing it there as well would
    // log one weigh-in twice.
    final filedDays = <String, DateTime>{
      for (final entry in await _weightLogRepository.getAllEntries())
        if (entry.externalId != null) entry.externalId!: entry.date,
    };
    final latestByDay = latestReadingPerDay(readings, filedDays: filedDays);

    final written = <String, ExternalWeight>{};
    for (final MapEntry(key: day, value: reading) in latestByDay.entries) {
      // Everything a write depends on is read fresh, right before it, rather
      // than taken from before the platform read, which is long:
      //
      //  * the config, because "Delete all my data" clears it without
      //    changing the profile id, and an import still on its way back must
      //    not refill the wiped log — nor one the user just turned off;
      //  * the tombstones in it, because a day deleted meanwhile would be
      //    written straight back (`DeleteWeightLogUsecase` stores the
      //    tombstone before it removes the row);
      //  * the row itself, last, because a weight the user logged meanwhile
      //    is a manual entry and must not be overwritten.
      final current = await _configRepository.getConfig();
      if (!_mayWrite(profileId, current)) return written.length;
      if (current.healthDeletedExternalIds.contains(reading.id)) continue;
      // An earlier reading from a deleted day, which the health store hands
      // back once the deleted newest one is gone from it too.
      final deletedUpTo = current.deletedWeightDayCutoff(day);
      if (deletedUpTo != null && !reading.measuredAt.isAfter(deletedUpTo)) {
        continue;
      }
      final existing = await _weightLogRepository.getEntry(day);
      if (!_stillOnProfile(profileId)) return written.length;
      if (existing != null && !existing.isImported) continue;
      if (existing?.externalId == reading.id &&
          existing?.weightKg == reading.weightKg) {
        continue;
      }
      await _weightLogRepository.addEntry(
        WeightLogEntity(
          date: day,
          weightKg: reading.weightKg,
          externalId: reading.id,
          measuredAt: reading.measuredAt,
        ),
      );
      written[reading.id] = reading;
    }

    // Every run, not only one that filed something: the current weight is
    // derived from the log as it stands, so a run killed between filing its
    // newest reading and updating the weight is finished by the next one,
    // however long that takes to come.
    final weightChanged = await _updateCurrentWeight(profileId);

    // Every write from here on resolves its box from whichever profile is
    // active at the moment of the call, so each is checked right before it
    // is made: a switch during the steps above must not hand this profile's
    // watermark to another one, which would cost that one its backfill, and
    // a wipe must not get a config back with a watermark in it.
    if (!await _mayStillWrite(profileId)) return written.length;
    await _configRepository.setConfigHealthWeightLastImportAt(to);
    if (!await _mayStillWrite(profileId)) return written.length;
    // Deleted weight readings share the workout tombstones, so the cutoff
    // has to keep every tombstone either import can still ask about. This
    // import's own window never reaches past the backfill floor (see
    // [readWindowStart]), but the workout import resumes from its own
    // watermark however old it is — a workout import left off for a month
    // while weights kept syncing would otherwise come back to find its
    // deletions pruned. Measuring against the workout watermark covers both:
    // the cutoff is the earlier of its next window and the floor.
    await _configRepository.pruneConfigHealthDeletedWorkouts(
      ConfigEntity.oldestUsefulTombstone(
        now: to,
        lastImportAt: config.healthLastImportAt,
        overlapTolerance: overlapTolerance,
      ),
    );
    if (written.isNotEmpty) {
      _log.info(
        'Imported ${written.length} weight reading(s) from the platform '
        'health store',
      );
    }
    if (written.isNotEmpty || weightChanged) _weightsImported.add(null);
    return written.length;
  }

  /// Where a run's read window starts: the watermark pushed back by
  /// [overlapTolerance], or a full backfill when there is no watermark.
  ///
  /// Never earlier than the backfill floor, even after a long absence. The
  /// tombstones that keep deleted readings deleted are pruned at that floor,
  /// so a window reaching past it could return a reading whose tombstone is
  /// already gone. The cost is that someone away for more than a month gets
  /// the same month of history a first import does.
  @visibleForTesting
  static DateTime readWindowStart({
    required DateTime now,
    required DateTime? lastImportAt,
  }) {
    final backfillFloor = now
        .subtract(const Duration(days: ConfigEntity.healthImportBackfillDays))
        .subtract(overlapTolerance);
    if (lastImportAt == null) return backfillFloor;
    final start = lastImportAt.subtract(overlapTolerance);
    return start.isBefore(backfillFloor) ? backfillFloor : start;
  }

  /// Groups readings by the local calendar day they were taken on — the key
  /// the weight log itself uses — keeping the latest reading of each day.
  ///
  /// A reading whose id is in [filedDays] stays on the day it was filed on,
  /// whatever day its instant falls on in the current time zone.
  @visibleForTesting
  static Map<DateTime, ExternalWeight> latestReadingPerDay(
    List<ExternalWeight> readings, {
    Map<String, DateTime> filedDays = const {},
  }) {
    final latest = <DateTime, ExternalWeight>{};
    for (final reading in readings) {
      final local = reading.measuredAt.toLocal();
      final day =
          filedDays[reading.id] ?? DateTime(local.year, local.month, local.day);
      final current = latest[day];
      if (current == null || reading.measuredAt.isAfter(current.measuredAt)) {
        latest[day] = reading;
      }
    }
    return latest;
  }

  /// Makes the newest imported entry in the log the user's current weight —
  /// but only when it is newer than the weight the user gave. A reading from
  /// last week that synced late must not overwrite a weight entered today.
  /// Returns whether the current weight changed.
  ///
  /// Imported entries are ordered by when they were taken, not by the day
  /// they are filed under: an entry keeps its day across a time-zone change,
  /// so a later reading can sit on an earlier date. Against a manual entry,
  /// which has only a day, the imported one has to be on a later day.
  ///
  /// A profile with no manual entry has its weight from onboarding, which
  /// onboarding also logs as a manual entry from now on. Profiles onboarded
  /// before that are measured against the moment the profile was created:
  /// only a reading taken after it can replace the weight. For the default
  /// profile of an install that predates profiles, that moment is the
  /// upgrade — later than the weight itself, so this errs toward keeping it.
  ///
  /// Bound to [profileId]: each read and the write are checked against it
  /// right before they are made, so a switch mid-way cannot carry this
  /// profile's weight into another, nor a wipe bring a user back.
  Future<bool> _updateCurrentWeight(String profileId) async {
    if (!await _userRepository.hasUserData()) return false;
    if (!_stillOnProfile(profileId)) return false;
    final candidate = _currentWeightCandidate(
      await _weightLogRepository.getAllEntries(),
      _hiveDBProvider.profileBox.get(profileId)?.createdAt,
    );
    if (candidate == null) return false;
    if (!await _mayStillWrite(profileId)) return false;
    if (!await _userRepository.hasUserData()) return false;
    if (!_stillOnProfile(profileId)) return false;
    // The log again, after the guards: a weight the user entered while they
    // ran is now the newest entry, and has already become the current
    // weight. Writing the imported one over it would leave the profile at
    // odds with the history.
    final current = _currentWeightCandidate(
      await _weightLogRepository.getAllEntries(),
      _hiveDBProvider.profileBox.get(profileId)?.createdAt,
    );
    if (current != candidate) return false;
    if (!_stillOnProfile(profileId)) return false;
    // Read last, right before the save, and only the weight changed: the
    // save writes the whole user, so a copy read before the guards above
    // would undo a profile edit (height, goal, activity level) that landed
    // while they ran.
    final user = await _userRepository.getUserData();
    if (user.weightKG == candidate.weightKg) return false;
    user.weightKG = candidate.weightKg;
    if (!_stillOnProfile(profileId)) return false;
    await _userRepository.updateUserData(user);
    return true;
  }

  /// The imported entry that should be the current weight, or null when the
  /// user's own weight is newer. See [_updateCurrentWeight].
  static WeightLogEntity? _currentWeightCandidate(
    List<WeightLogEntity> entries,
    DateTime? profileCreatedAt,
  ) {
    WeightLogEntity? newestImported;
    WeightLogEntity? newestManual;
    for (final entry in entries) {
      if (entry.isImported) {
        if (newestImported == null ||
            _takenAt(entry).isAfter(_takenAt(newestImported))) {
          newestImported = entry;
        }
      } else if (newestManual == null ||
          entry.date.isAfter(newestManual.date)) {
        newestManual = entry;
      }
    }
    if (newestImported == null) return null;
    if (newestManual != null) {
      return newestImported.date.isAfter(newestManual.date)
          ? newestImported
          : null;
    }
    if (profileCreatedAt != null &&
        !_takenAt(newestImported).isAfter(profileCreatedAt)) {
      return null;
    }
    return newestImported;
  }

  /// When an imported entry's reading was taken. An entry filed before that
  /// was recorded counts as the start of its day, the earliest it can have
  /// been — which errs toward keeping a weight the user gave.
  static DateTime _takenAt(WeightLogEntity entry) =>
      entry.measuredAt ?? entry.date;

  /// Whether the run that started under [profileId] may still write: the
  /// profile is still active and weight import is still on for it. The flag
  /// also goes when "Delete all my data" clears the profile's config, which
  /// leaves the profile id as it was.
  bool _mayWrite(String profileId, ConfigEntity config) {
    if (!_stillOnProfile(profileId)) return false;
    if (config.healthWeightImportEnabled) return true;
    _log.info(
      'Abandoning the weight import: weight import was turned off or the '
      'profile was wiped mid-run',
    );
    return false;
  }

  /// [_mayWrite] against the config as it is now.
  Future<bool> _mayStillWrite(String profileId) async =>
      _mayWrite(profileId, await _configRepository.getConfig());

  bool _stillOnProfile(String profileId) {
    if (_hiveDBProvider.activeProfileId == profileId) return true;
    _log.info(
      'Abandoning the weight import: the active profile changed mid-run',
    );
    return false;
  }
}
