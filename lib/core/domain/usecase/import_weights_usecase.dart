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

  Future<int>? _inFlight;
  String? _inFlightProfileId;

  final _weightsImported = StreamController<void>.broadcast();

  /// Fires after a run that wrote weight-log entries, for screens that keep
  /// their own copy of the log, such as the weight history.
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
      final inFlight = _inFlight;
      if (inFlight != null &&
          _inFlightProfileId == _hiveDBProvider.activeProfileId) {
        return await inFlight;
      }
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
    final inFlight = _inFlight;
    if (inFlight != null && _inFlightProfileId == profileId) return inFlight;
    final run = _import();
    _inFlight = run;
    _inFlightProfileId = profileId;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) {
        _inFlight = null;
        _inFlightProfileId = null;
      }
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

    final latestByDay = latestReadingPerDay(readings);

    final written = <String, ExternalWeight>{};
    for (final MapEntry(key: day, value: reading) in latestByDay.entries) {
      final existing = await _weightLogRepository.getEntry(day);
      if (existing != null && !existing.isImported) continue;
      if (existing?.externalId == reading.id &&
          existing?.weightKg == reading.weightKg) {
        continue;
      }
      // The tombstones are read here, as the last await before the write,
      // rather than taken from the snapshot above: the platform read is long,
      // and a day the user deleted while it ran would otherwise be written
      // straight back. `DeleteWeightLogUsecase` stores the tombstone before
      // it removes the row, so a deletion is visible here once it has begun.
      final deletedIds = (await _configRepository.getConfig())
          .healthDeletedExternalIds;
      if (deletedIds.contains(reading.id)) continue;
      if (!_stillOnProfile(profileId)) return written.length;
      await _weightLogRepository.addEntry(
        WeightLogEntity(
          date: day,
          weightKg: reading.weightKg,
          externalId: reading.id,
        ),
      );
      written[reading.id] = reading;
    }

    if (!_stillOnProfile(profileId)) return written.length;

    if (written.isNotEmpty) await _updateCurrentWeight(profileId, written);

    // Every write from here on resolves its box from whichever profile is
    // active at the moment of the call, so each is checked right before it
    // is made: a switch during the steps above must not hand this profile's
    // watermark to another one, which would cost that one its backfill.
    if (!_stillOnProfile(profileId)) return written.length;
    await _configRepository.setConfigHealthWeightLastImportAt(to);
    if (!_stillOnProfile(profileId)) return written.length;
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
      _weightsImported.add(null);
    }
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
  @visibleForTesting
  static Map<DateTime, ExternalWeight> latestReadingPerDay(
    List<ExternalWeight> readings,
  ) {
    final latest = <DateTime, ExternalWeight>{};
    for (final reading in readings) {
      final local = reading.measuredAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final current = latest[day];
      if (current == null || reading.measuredAt.isAfter(current.measuredAt)) {
        latest[day] = reading;
      }
    }
    return latest;
  }

  /// Makes the newest reading the user's current weight — but only when it
  /// is newer than the weight the user gave. A reading from last week that
  /// synced late must not overwrite a weight the user entered today.
  ///
  /// A weight entered in the app lands in the log as a manual entry, and the
  /// newest entry wins. A weight given at onboarding never reaches the log,
  /// though, so a profile without a manual entry is measured against the
  /// moment the profile was created instead: only a reading taken after that
  /// can replace it. For the default profile of an install that predates
  /// profiles, that moment is the upgrade — later than the weight itself, so
  /// the comparison errs toward keeping the user's weight.
  ///
  /// Bound to [profileId]: each read and the write are checked against it
  /// right before they are made, so a switch mid-way cannot carry this
  /// profile's weight into another.
  Future<void> _updateCurrentWeight(
    String profileId,
    Map<String, ExternalWeight> written,
  ) async {
    if (!await _userRepository.hasUserData()) return;
    if (!_stillOnProfile(profileId)) return;
    final entries = await _weightLogRepository.getAllEntries();
    if (entries.isEmpty) return;
    final newest = entries.reduce((a, b) => b.date.isAfter(a.date) ? b : a);
    final reading = written[newest.externalId];
    if (reading == null) return;
    if (!entries.any((entry) => !entry.isImported)) {
      final enteredBy = _hiveDBProvider.profileBox.get(profileId)?.createdAt;
      if (enteredBy != null && !reading.measuredAt.isAfter(enteredBy)) return;
    }
    if (!_stillOnProfile(profileId)) return;
    final user = await _userRepository.getUserData();
    if (user.weightKG == newest.weightKg) return;
    user.weightKG = newest.weightKg;
    if (!_stillOnProfile(profileId)) return;
    await _userRepository.updateUserData(user);
  }

  bool _stillOnProfile(String profileId) {
    if (_hiveDBProvider.activeProfileId == profileId) return true;
    _log.info(
      'Abandoning the weight import: the active profile changed mid-run',
    );
    return false;
  }
}
