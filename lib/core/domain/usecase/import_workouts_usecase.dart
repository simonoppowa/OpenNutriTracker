import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_physical_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/log_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';

/// Pulls finished workouts out of Health Connect / Apple Health and files
/// them as activities, crediting a user-tunable share of the energy the
/// device reported.
///
/// Imported activities are ordinary [UserActivityEntity] rows: they raise the
/// day's calorie and macro goals exactly as a manually logged workout does
/// (see [LogUserActivityUsecase]), they are editable, and they are deletable.
/// The only thing that marks them is [UserActivityEntity.externalId], which
/// is what stops the same platform record being imported twice.
class ImportWorkoutsUsecase {
  /// Read window pushed back beyond the watermark on every run. Fitness apps
  /// routinely sync a session to the health store minutes or hours after it
  /// finished, so a window that started exactly where the last one ended
  /// would miss them permanently. Re-reading is free — the external id
  /// dedupe absorbs the overlap.
  static const overlapTolerance = Duration(hours: 24);

  /// Debounce for [importIfDue]. Startup and every app resume ask for an
  /// import; without this a user switching apps would trigger a platform read
  /// every few seconds.
  static const minimumInterval = Duration(minutes: 15);

  /// The clock the import window is measured against. Pinned by tests so a
  /// watermark, a backfill window and a debounce can be exercised without
  /// waiting; production never assigns it. Mirrors [DayBoundaryCalc.clock].
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  final _log = Logger('ImportWorkoutsUsecase');

  final HealthImportRepository _healthImportRepository;
  final ConfigRepository _configRepository;
  final UserActivityRepository _userActivityRepository;
  final GetPhysicalActivityUsecase _getPhysicalActivityUsecase;
  final LogUserActivityUsecase _logUserActivityUsecase;

  ImportWorkoutsUsecase(
    this._healthImportRepository,
    this._configRepository,
    this._userActivityRepository,
    this._getPhysicalActivityUsecase,
    this._logUserActivityUsecase,
  );

  /// Runs an import if one is due, swallowing failures.
  ///
  /// This is the background entry point — app start and app resume — where
  /// there is no user waiting on an answer and nowhere to show an error, so a
  /// platform that refuses the read is logged and shrugged off. The
  /// user-initiated path calls [importNow] instead and gets the exception.
  Future<int> importIfDue() async {
    try {
      final config = await _configRepository.getConfig();
      if (!config.healthImportEnabled) return 0;
      final lastImportAt = config.healthLastImportAt;
      if (lastImportAt != null &&
          clock().difference(lastImportAt) < minimumInterval) {
        return 0;
      }
      return await importNow();
    } catch (error, stackTrace) {
      _log.severe('Background workout import failed', error, stackTrace);
      return 0;
    }
  }

  /// Imports every workout in the window that isn't already filed, and
  /// returns how many were written.
  ///
  /// Returns 0 without touching the platform when the user has not opted in.
  /// Throws whatever the health store throws — a revoked permission or an
  /// uninstalled Health Connect is something the user needs to be told about,
  /// not something to silently absorb.
  Future<int> importNow() async {
    final config = await _configRepository.getConfig();
    if (!config.healthImportEnabled) return 0;

    final to = clock();
    final from =
        (config.healthLastImportAt ??
                to.subtract(
                  const Duration(days: ConfigEntity.healthImportBackfillDays),
                ))
            .subtract(overlapTolerance);

    final workouts = await _healthImportRepository.getWorkouts(
      from: from,
      to: to,
    );
    final seenIds = await _userActivityRepository.getExternalIdsSince(from);
    final activityByCode = {
      for (final activity
          in await _getPhysicalActivityUsecase.getAllPhysicalActivities())
        activity.code: activity,
    };

    var imported = 0;
    for (final workout in workouts) {
      if (!_isImportable(workout) || !seenIds.add(workout.id)) continue;
      await _logUserActivityUsecase.logActivity(
        _toUserActivity(workout, config, activityByCode),
        // A workout that started at 00:30 under an 03:00 day boundary belongs
        // to the previous diary column, and its calories have to raise that
        // day's goal, not today's.
        day: DayBoundaryCalc.logicalDayOfMinutes(
          workout.start,
          config.dayStartOffsetTotalMinutes,
        ),
      );
      imported++;
    }

    // Written even when nothing was imported: the watermark is also what
    // debounces the next run, and an empty window is still a window covered.
    await _configRepository.setConfigHealthLastImportAt(to);
    if (imported > 0) {
      _log.info('Imported $imported workout(s) from the platform health store');
    }
    return imported;
  }

  /// A workout the app can turn into a meaningful diary row: it lasted some
  /// time, and the device attributed some energy to it. Anything else would
  /// land as a zero-calorie entry that only adds noise.
  bool _isImportable(ExternalWorkout workout) {
    final energy = workout.energyBurnedKcal;
    return energy != null && energy > 0 && workout.end.isAfter(workout.start);
  }

  UserActivityEntity _toUserActivity(
    ExternalWorkout workout,
    ConfigEntity config,
    Map<String, PhysicalActivityEntity> activityByCode,
  ) {
    final reportedKcal = workout.energyBurnedKcal!;
    final creditedKcal =
        reportedKcal * config.effectiveHealthWorkoutKcalMultiplier;
    return UserActivityEntity(
      IdGenerator.getUniqueID(),
      workout.end.difference(workout.start).inSeconds / 60,
      creditedKcal,
      workout.start,
      _physicalActivityFor(workout, activityByCode),
      // Mirrored into burnedKcal above because the aggregation layer sums
      // that field; userKcal records that the figure is a measured one rather
      // than something the MET formula produced, so editing prefills it.
      userKcal: creditedKcal,
      externalId: workout.id,
      sourceReportedKcal: reportedKcal,
    );
  }

  /// Picks the compendium activity an imported workout is filed under. Only
  /// its name and icon matter — the MET value is never consulted, because the
  /// device's own energy figure overrides it.
  ///
  /// Workout types with no honest compendium counterpart become Custom
  /// activities labelled with the platform's own type name, which reads
  /// better than filing a rowing machine session under canoeing.
  PhysicalActivityEntity _physicalActivityFor(
    ExternalWorkout workout,
    Map<String, PhysicalActivityEntity> activityByCode,
  ) {
    final code = _compendiumCodeByWorkoutType[workout.activityTypeName];
    final activity = code == null ? null : activityByCode[code];
    if (activity != null) return activity;
    return PhysicalActivityEntity.customNamed(
      _readableTypeName(workout.activityTypeName),
    );
  }

  /// `HIGH_INTENSITY_INTERVAL_TRAINING` reads as "High intensity interval
  /// training". Not localized: this is the platform's label for the record,
  /// carried through the way a user-typed Quick Add name is.
  String _readableTypeName(String activityTypeName) {
    final words = activityTypeName.toLowerCase().replaceAll('_', ' ').trim();
    if (words.isEmpty) return activityTypeName;
    return words[0].toUpperCase() + words.substring(1);
  }
}

/// `HealthWorkoutActivityType` name to '2024 Adult Compendium of Physical
/// Activities' code, for the types that have a fair counterpart in the
/// activity list this app ships. Codes are the ones from
/// `PhysicalActivityDataSource`; unlisted types fall back to a Custom
/// activity.
const _compendiumCodeByWorkoutType = <String, String>{
  'AMERICAN_FOOTBALL': '15230',
  'ARCHERY': '15010',
  'BADMINTON': '15030',
  'BASEBALL': '15620',
  'BASKETBALL': '15055',
  'BIKING': '01015',
  'BIKING_STATIONARY': '02010',
  'BOWLING': '15090',
  'BOXING': '15100',
  'CALISTHENICS': '02030',
  'CARDIO_DANCE': '03015',
  'CLIMBING': '15533',
  'CRICKET': '15150',
  'CROSS_COUNTRY_SKIING': '19080',
  'CURLING': '15170',
  'DANCING': '03015',
  'DOWNHILL_SKIING': '19075',
  'EQUESTRIAN_SPORTS': '15370',
  'FENCING': '15200',
  'FITNESS_GAMING': '15750',
  'FLEXIBILITY': '02170',
  'FRISBEE_DISC': '15240',
  'FUNCTIONAL_STRENGTH_TRAINING': '02050',
  'GOLF': '15255',
  'GYMNASTICS': '15300',
  'HANDBALL': '15320',
  'HIGH_INTENSITY_INTERVAL_TRAINING': '02210',
  'HIKING': '17080',
  'HOCKEY': '15350',
  'ICE_SKATING': '19030',
  'JUMP_ROPE': '02068',
  'KICKBOXING': '15430',
  'LACROSSE': '15460',
  'MARTIAL_ARTS': '15430',
  'PICKLEBALL': '15740',
  'PILATES': '02165',
  'RACQUETBALL': '15530',
  'ROCK_CLIMBING': '15533',
  'RUGBY': '15560',
  'RUNNING': '12150',
  'RUNNING_TREADMILL': '12180',
  'SAILING': '18120',
  'SCUBA_DIVING': '18200',
  'SKATING': '15590',
  'SKIING': '19075',
  'SNOWSHOEING': '19260',
  'SOCCER': '15610',
  'SOCIAL_DANCE': '03015',
  'SOFTBALL': '15620',
  'SQUASH': '15652',
  'STRENGTH_TRAINING': '02050',
  'SURFING': '18220',
  'SWIMMING': '18350',
  'SWIMMING_OPEN_WATER': '18350',
  'SWIMMING_POOL': '18350',
  'TABLE_TENNIS': '15660',
  'TAI_CHI': '15670',
  'TENNIS': '15675',
  'TRACK_AND_FIELD': '15732',
  'TRADITIONAL_STRENGTH_TRAINING': '02050',
  'UNDERWATER_DIVING': '18200',
  'VOLLEYBALL': '15710',
  'WALKING': '17160',
  'WALKING_TREADMILL': '17160',
  'WATER_FITNESS': '18355',
  'WATER_POLO': '18360',
  'WEIGHTLIFTING': '02055',
  'WRESTLING': '15730',
};
