import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/health/external_workout.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';
import 'package:opennutritracker/core/data/data_source/physical_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/data/repository/physical_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_physical_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/import_workouts_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/log_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';

import '../fixture/user_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// Stands in for the platform health store. The `health` plugin can't run
/// under `flutter test` at all, which is exactly why every call to it sits
/// behind [HealthService].
class _FakeHealthService extends Fake implements HealthService {
  List<ExternalWorkout> workouts = const [];
  double? bodyFatPercent;
  bool throwOnRead = false;

  int readWorkoutsCalls = 0;
  DateTime? lastFrom;
  DateTime? lastTo;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<ExternalWorkout>> readWorkouts({
    required DateTime from,
    required DateTime to,
  }) async {
    readWorkoutsCalls++;
    lastFrom = from;
    lastTo = to;
    if (throwOnRead) {
      throw StateError('Health Connect permission revoked');
    }
    return workouts;
  }

  @override
  Future<double?> readLatestBodyFatPercent() async => bodyFatPercent;
}

ExternalWorkout _workout({
  String id = 'record-1',
  String activityTypeName = 'RUNNING',
  required DateTime start,
  Duration duration = const Duration(hours: 1),
  double? energyBurnedKcal = 500,
}) => ExternalWorkout(
  id: id,
  start: start,
  end: start.add(duration),
  activityTypeName: activityTypeName,
  energyBurnedKcal: energyBurnedKcal,
  sourceAppName: 'Fake Watch',
);

void main() {
  // A fixed "now", well clear of both midnight and any configurable day
  // boundary, so the window arithmetic below reads the same in every zone.
  final now = DateTime(2026, 5, 23, 12, 0);

  late Box<ConfigDBO> configBox;
  late Box<UserActivityDBO> activityBox;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<UserDBO> userBox;

  late ConfigDataSource configDataSource;
  late ConfigRepository configRepository;
  late UserActivityRepository userActivityRepository;
  late TrackedDayRepository trackedDayRepository;
  late GetKcalGoalUsecase getKcalGoalUsecase;
  late GetMacroGoalUsecase getMacroGoalUsecase;
  late _FakeHealthService healthService;
  late ImportWorkoutsUsecase usecase;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    configBox = await Hive.openBox<ConfigDBO>('health_import_config_test');
    activityBox = await Hive.openBox<UserActivityDBO>(
      'health_import_activity_test',
    );
    trackedDayBox = await Hive.openBox<TrackedDayDBO>(
      'health_import_tracked_day_test',
    );
    userBox = await Hive.openBox<UserDBO>('health_import_user_test');
    // Explicit rather than relying on the teardown's delete: a box that
    // survives into the next test carries a watermark and an already-imported
    // record with it, which is precisely what these tests are checking.
    await configBox.clear();
    await activityBox.clear();
    await trackedDayBox.clear();
    await userBox.clear();

    final provider = FakeHiveDBProvider(
      configBox: configBox,
      userActivityBox: activityBox,
      trackedDayBox: trackedDayBox,
      userBox: userBox,
    );

    configDataSource = ConfigDataSource(provider);
    await configDataSource.initializeConfig();
    configRepository = ConfigRepository(configDataSource);
    userActivityRepository = UserActivityRepository(
      UserActivityDataSource(provider),
    );
    trackedDayRepository = TrackedDayRepository(TrackedDayDataSource(provider));

    final userRepository = UserRepository(UserDataSource(provider));
    await userRepository.updateUserData(
      UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight,
    );

    getKcalGoalUsecase = GetKcalGoalUsecase(
      userRepository,
      configRepository,
      userActivityRepository,
    );
    getMacroGoalUsecase = GetMacroGoalUsecase(configRepository);

    healthService = _FakeHealthService();
    usecase = ImportWorkoutsUsecase(
      HealthImportRepository(healthService),
      configRepository,
      userActivityRepository,
      GetPhysicalActivityUsecase(
        PhysicalActivityRepository(PhysicalActivityDataSource()),
      ),
      LogUserActivityUsecase(
        AddUserActivityUsecase(userActivityRepository),
        AddTrackedDayUsecase(trackedDayRepository),
        getKcalGoalUsecase,
        getMacroGoalUsecase,
      ),
    );

    ImportWorkoutsUsecase.clock = () => now;
    await configDataSource.setConfigHealthImportEnabled(true);
  });

  tearDown(() async {
    ImportWorkoutsUsecase.clock = DateTime.now;
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  group('ImportWorkoutsUsecase budget invariant', () {
    test(
      'an imported workout becomes an activity and raises the day goal',
      () async {
        healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];
        // Read before importing: the goal excluding activities is the base the
        // tracked day is created from, and it must not move afterwards.
        final baseKcalGoal = await getKcalGoalUsecase.getKcalGoal(
          totalKcalActivitiesParam: 0,
        );
        final baseCarbsGoal = await getMacroGoalUsecase.getCarbsGoal(
          baseKcalGoal,
        );

        final imported = await usecase.importNow();

        expect(imported, equals(1));
        final activities = await userActivityRepository.getAllUserActivityDBO();
        expect(activities, hasLength(1));
        expect(activities.single.burnedKcal, closeTo(500, 0.001));
        expect(activities.single.duration, closeTo(60, 0.001));
        expect(activities.single.externalId, equals('record-1'));
        expect(activities.single.date, equals(DateTime(2026, 5, 23, 7, 0)));

        final trackedDay = await trackedDayRepository.getTrackedDay(
          DateTime(2026, 5, 23),
        );
        expect(trackedDay, isNotNull);
        expect(trackedDay!.calorieGoal, closeTo(baseKcalGoal + 500, 0.001));
        expect(
          trackedDay.carbsGoal,
          closeTo(baseCarbsGoal + MacroCalc.getTotalCarbsGoal(500), 0.001),
        );
        expect(
          trackedDay.fatGoal,
          closeTo(
            await getMacroGoalUsecase.getFatsGoal(baseKcalGoal) +
                MacroCalc.getTotalFatsGoal(500),
            0.001,
          ),
        );
        expect(
          trackedDay.proteinGoal,
          closeTo(
            await getMacroGoalUsecase.getProteinsGoal(baseKcalGoal) +
                MacroCalc.getTotalProteinsGoal(500),
            0.001,
          ),
        );
      },
    );

    test(
      'a workout before the day boundary is filed on the previous day',
      () async {
        // 00:30 with a 03:00 boundary belongs to the 22nd's diary column, so
        // that is the day whose goal has to rise (#139).
        await configDataSource.setConfigDayStartOffsetHours(3);
        healthService.workouts = [
          _workout(start: DateTime(2026, 5, 23, 0, 30)),
        ];

        await usecase.importNow();

        expect(
          await trackedDayRepository.getTrackedDay(DateTime(2026, 5, 22)),
          isNotNull,
        );
        expect(
          await trackedDayRepository.getTrackedDay(DateTime(2026, 5, 23)),
          isNull,
        );
      },
    );

    test('the multiplier scales the credit, not the record', () async {
      await configDataSource.setConfigHealthWorkoutKcalMultiplier(0.7);
      healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];
      final baseKcalGoal = await getKcalGoalUsecase.getKcalGoal(
        totalKcalActivitiesParam: 0,
      );

      await usecase.importNow();

      // 500 kcal reported, 70% credited: 350 toward the goal, 500 kept as
      // what the device actually said.
      final activity =
          (await userActivityRepository.getAllUserActivityDBO()).single;
      expect(activity.burnedKcal, closeTo(350, 0.001));
      expect(activity.userKcal, closeTo(350, 0.001));
      expect(activity.sourceReportedKcal, closeTo(500, 0.001));

      final trackedDay = await trackedDayRepository.getTrackedDay(
        DateTime(2026, 5, 23),
      );
      expect(trackedDay!.calorieGoal, closeTo(baseKcalGoal + 350, 0.001));
    });
  });

  group('ImportWorkoutsUsecase filtering', () {
    test('a record already imported is never imported again', () async {
      healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];

      expect(await usecase.importNow(), equals(1));
      expect(await usecase.importNow(), equals(0));
      expect(
        await userActivityRepository.getAllUserActivityDBO(),
        hasLength(1),
      );
    });

    test('two records with the same id in one batch import once', () async {
      healthService.workouts = [
        _workout(start: DateTime(2026, 5, 23, 7, 0)),
        _workout(start: DateTime(2026, 5, 23, 9, 0)),
      ];

      expect(await usecase.importNow(), equals(1));
    });

    test('records without usable energy or duration are skipped', () async {
      healthService.workouts = [
        _workout(
          id: 'no-energy',
          start: DateTime(2026, 5, 23, 7, 0),
          energyBurnedKcal: null,
        ),
        _workout(
          id: 'zero-energy',
          start: DateTime(2026, 5, 23, 8, 0),
          energyBurnedKcal: 0,
        ),
        _workout(
          id: 'instant',
          start: DateTime(2026, 5, 23, 9, 0),
          duration: Duration.zero,
        ),
      ];

      expect(await usecase.importNow(), equals(0));
      expect(await userActivityRepository.getAllUserActivityDBO(), isEmpty);
      expect(await trackedDayRepository.getAllTrackedDaysDBO(), isEmpty);
    });

    test('nothing is read at all while the user has not opted in', () async {
      await configDataSource.setConfigHealthImportEnabled(false);
      healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];

      expect(await usecase.importNow(), equals(0));
      expect(healthService.readWorkoutsCalls, isZero);
    });
  });

  group('ImportWorkoutsUsecase window and watermark', () {
    test('the first run backfills, later runs follow the watermark', () async {
      await usecase.importNow();

      expect(
        healthService.lastFrom,
        equals(
          now
              .subtract(const Duration(days: 30))
              .subtract(ImportWorkoutsUsecase.overlapTolerance),
        ),
      );
      expect(healthService.lastTo, equals(now));

      final later = now.add(const Duration(hours: 2));
      ImportWorkoutsUsecase.clock = () => later;
      await usecase.importNow();

      // The watermark from the first run, pulled back by the overlap
      // tolerance so a late-syncing workout still gets picked up.
      expect(
        healthService.lastFrom,
        equals(now.subtract(ImportWorkoutsUsecase.overlapTolerance)),
      );
    });

    test('the watermark advances even when nothing was imported', () async {
      await usecase.importNow();

      final config = await configRepository.getConfig();
      expect(config.healthLastImportAt, equals(now));
    });
  });

  group('ImportWorkoutsUsecase background entry point', () {
    test('importIfDue debounces repeated resumes', () async {
      healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];

      expect(await usecase.importIfDue(), equals(1));
      expect(healthService.readWorkoutsCalls, equals(1));

      ImportWorkoutsUsecase.clock = () => now.add(const Duration(minutes: 5));
      expect(await usecase.importIfDue(), equals(0));
      expect(healthService.readWorkoutsCalls, equals(1));

      ImportWorkoutsUsecase.clock = () => now.add(const Duration(minutes: 20));
      expect(await usecase.importIfDue(), equals(0));
      expect(healthService.readWorkoutsCalls, equals(2));
    });

    test('a failing health store is swallowed in the background and raised '
        'on the user-initiated path', () async {
      healthService.throwOnRead = true;

      expect(await usecase.importIfDue(), equals(0));
      expect(() => usecase.importNow(), throwsStateError);
    });
  });

  group('ImportWorkoutsUsecase activity mapping', () {
    test(
      'a known workout type is filed under its compendium activity',
      () async {
        healthService.workouts = [
          _workout(
            activityTypeName: 'RUNNING',
            start: DateTime(2026, 5, 23, 7, 0),
          ),
        ];

        await usecase.importNow();

        final activity =
            (await userActivityRepository.getAllUserActivityDBO()).single;
        expect(activity.physicalActivityDBO.code, equals('12150'));
        expect(
          activity.physicalActivityDBO.specificActivity,
          equals('running'),
        );
      },
    );

    test('an unmapped workout type becomes a named Custom activity', () async {
      healthService.workouts = [
        _workout(
          activityTypeName: 'ROWING_MACHINE',
          start: DateTime(2026, 5, 23, 7, 0),
        ),
      ];

      await usecase.importNow();

      final activity =
          (await userActivityRepository.getAllUserActivityDBO()).single;
      expect(
        activity.physicalActivityDBO.code,
        equals(PhysicalActivityEntity.customCode),
      );
      expect(
        activity.physicalActivityDBO.specificActivity,
        equals('Rowing machine'),
      );
    });
  });
}
