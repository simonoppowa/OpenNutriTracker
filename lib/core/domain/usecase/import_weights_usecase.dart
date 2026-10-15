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
/// When the newest entry in the whole log came from this run, it also becomes
/// the user's current weight, which is what BMI and the calorie goal use.
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
    final deletedIds = config.healthDeletedExternalIds;

    final writtenIds = <String>{};
    for (final MapEntry(key: day, value: reading) in latestByDay.entries) {
      if (deletedIds.contains(reading.id)) continue;
      final existing = await _weightLogRepository.getEntry(day);
      if (existing != null && !existing.isImported) continue;
      if (existing?.externalId == reading.id &&
          existing?.weightKg == reading.weightKg) {
        continue;
      }
      if (!_stillOnProfile(profileId)) return writtenIds.length;
      await _weightLogRepository.addEntry(
        WeightLogEntity(
          date: day,
          weightKg: reading.weightKg,
          externalId: reading.id,
        ),
      );
      writtenIds.add(reading.id);
    }

    if (!_stillOnProfile(profileId)) return writtenIds.length;

    if (writtenIds.isNotEmpty) await _updateCurrentWeight(writtenIds);

    await _configRepository.setConfigHealthWeightLastImportAt(to);
    // Deleted weight readings share the workout tombstones, so this prunes
    // against the same floor the workout import does. [readWindowStart]
    // never reads back past that floor, which is what makes the shared
    // pruning safe for both.
    await _configRepository.pruneConfigHealthDeletedWorkouts(
      ConfigEntity.oldestUsefulTombstone(
        now: to,
        lastImportAt: to,
        overlapTolerance: overlapTolerance,
      ),
    );
    if (writtenIds.isNotEmpty) {
      _log.info(
        'Imported ${writtenIds.length} weight reading(s) from the platform '
        'health store',
      );
    }
    return writtenIds.length;
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
  /// is also the newest entry in the log. A reading from last week that
  /// synced late must not overwrite a weight the user entered today.
  Future<void> _updateCurrentWeight(Set<String> writtenIds) async {
    if (!await _userRepository.hasUserData()) return;
    final entries = await _weightLogRepository.getAllEntries();
    if (entries.isEmpty) return;
    final newest = entries.reduce((a, b) => b.date.isAfter(a.date) ? b : a);
    if (!writtenIds.contains(newest.externalId)) return;
    final user = await _userRepository.getUserData();
    if (user.weightKG == newest.weightKg) return;
    user.weightKG = newest.weightKg;
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
