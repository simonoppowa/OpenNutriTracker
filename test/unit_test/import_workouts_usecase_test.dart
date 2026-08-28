import 'dart:async';

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
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
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

  /// Holds a read open so a second caller can arrive mid-import.
  Completer<void>? readGate;

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
    final gate = readGate;
    if (gate != null) await gate.future;
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
  late FakeHiveDBProvider provider;
  late ImportWorkoutsUsecase usecase;
  late DeleteUserActivityUsecase deleteUsecase;

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

    provider = FakeHiveDBProvider(
      activeProfileId: 'profile-a',
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
      provider,
    );

    deleteUsecase = DeleteUserActivityUsecase(
      userActivityRepository,
      configRepository,
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

  // #944: the boxes every write below goes through are resolved from
  // HiveDBProvider at the moment of the call, and switching profiles swaps
  // that box-set in place. A run that read profile A's opt-in flag and came
  // back from the platform under profile B used to file A's workouts, and A's
  // watermark, into B — a profile that never opted in.
  group('ImportWorkoutsUsecase profile isolation', () {
    test('a switch during the platform read files nothing', () async {
      healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];
      healthService.readGate = Completer<void>();

      final run = usecase.importNow();
      // The switch lands while the health store is still answering, which is
      // the long await and the likeliest moment for it.
      provider.activeProfileId = 'profile-b';
      healthService.readGate!.complete();

      expect(await run, equals(0));
      expect(await userActivityRepository.getAllUserActivityDBO(), isEmpty);
    });

    test(
      'a switch during the platform read leaves the watermark alone',
      () async {
        // The watermark matters as much as the rows: written into B it would
        // debounce B's own first import and silently narrow its backfill window.
        healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];
        healthService.readGate = Completer<void>();

        final run = usecase.importNow();
        provider.activeProfileId = 'profile-b';
        healthService.readGate!.complete();
        await run;

        expect((await configRepository.getConfig()).healthLastImportAt, isNull);
      },
    );

    test('the abandoned window is imported again on the next run', () async {
      // Abandoning is only cheap if nothing is lost by it. Switching back and
      // running again has to produce the workout the first run walked away
      // from.
      healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];
      healthService.readGate = Completer<void>();

      final abandoned = usecase.importNow();
      provider.activeProfileId = 'profile-b';
      healthService.readGate!.complete();
      expect(await abandoned, equals(0));

      provider.activeProfileId = 'profile-a';
      expect(await usecase.importNow(), equals(1));
      expect(
        await userActivityRepository.getAllUserActivityDBO(),
        hasLength(1),
      );
    });

    test(
      'a caller on another profile does not join the run in flight',
      () async {
        // The serialization guard is only sound for callers asking the same
        // question. Handing B the answer to A's question would report A's count
        // as B's and skip the import B asked for.
        healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];
        healthService.readGate = Completer<void>();

        final onA = usecase.importNow();
        provider.activeProfileId = 'profile-b';
        final onB = usecase.importNow();
        healthService.readGate!.complete();

        await onA;
        await onB;
        expect(
          healthService.readWorkoutsCalls,
          equals(2),
          reason: 'B must read the platform for itself, not inherit A\'s read',
        );
      },
    );
  });

  group('ImportWorkoutsUsecase serialization', () {
    test('two overlapping runs import the workout once', () async {
      // Startup and a resume landing on top of each other: without a guard
      // both read the same window, both find nothing filed against the
      // record yet, and both write it — one session, two diary rows, the
      // day's goal raised twice.
      healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];
      healthService.readGate = Completer<void>();

      final first = usecase.importNow();
      final second = usecase.importNow();
      healthService.readGate!.complete();

      expect(await first, equals(1));
      expect(await second, equals(1));
      expect(healthService.readWorkoutsCalls, equals(1));
      expect(
        await userActivityRepository.getAllUserActivityDBO(),
        hasLength(1),
      );
    });

    test('a background run joins the manual one already in flight', () async {
      healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];
      healthService.readGate = Completer<void>();

      final manual = usecase.importNow();
      final background = usecase.importIfDue();
      healthService.readGate!.complete();

      expect(await manual, equals(1));
      expect(await background, equals(1));
      expect(healthService.readWorkoutsCalls, equals(1));
    });

    test('a failed run does not wedge the next one', () async {
      healthService.throwOnRead = true;
      await expectLater(usecase.importNow(), throwsStateError);

      healthService.throwOnRead = false;
      healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];

      expect(await usecase.importNow(), equals(1));
    });
  });

  group('ImportWorkoutsUsecase deletion', () {
    test('a deleted workout is not imported again', () async {
      // The window deliberately overlaps the last one, and the dedupe set is
      // built from the activities on file — so without a tombstone the very
      // next run would hand the user back the workout they just deleted.
      healthService.workouts = [_workout(start: DateTime(2026, 5, 23, 7, 0))];
      expect(await usecase.importNow(), equals(1));

      final imported =
          (await userActivityRepository.getAllUserActivityDBO()).single;
      await deleteUsecase.deleteUserActivity(
        UserActivityEntity.fromUserActivityDBO(imported),
      );

      ImportWorkoutsUsecase.clock = () => now.add(const Duration(hours: 2));

      expect(await usecase.importNow(), equals(0));
      expect(await userActivityRepository.getAllUserActivityDBO(), isEmpty);
    });

    test('the tombstone outlives a re-import of the whole window', () async {
      healthService.workouts = [
        _workout(id: 'kept', start: DateTime(2026, 5, 23, 7, 0)),
        _workout(id: 'unwanted', start: DateTime(2026, 5, 23, 9, 0)),
      ];
      await usecase.importNow();

      final unwanted = (await userActivityRepository.getAllUserActivityDBO())
          .firstWhere((activity) => activity.externalId == 'unwanted');
      await deleteUsecase.deleteUserActivity(
        UserActivityEntity.fromUserActivityDBO(unwanted),
      );

      // Back to a full backfill, as a fresh watermark-less run would do.
      await configRepository.setConfigHealthLastImportAt(null);
      ImportWorkoutsUsecase.clock = () => now.add(const Duration(hours: 2));

      expect(await usecase.importNow(), equals(0));
      final remaining = await userActivityRepository.getAllUserActivityDBO();
      expect(remaining, hasLength(1));
      expect(remaining.single.externalId, equals('kept'));
    });

    test('deleting a manually logged activity records nothing', () async {
      await userActivityRepository.addUserActivity(
        UserActivityEntity(
          'manual-1',
          30,
          200,
          DateTime(2026, 5, 23, 7, 0),
          PhysicalActivityEntity.custom,
          userKcal: 200,
        ),
      );

      await deleteUsecase.deleteUserActivity(
        UserActivityEntity.fromUserActivityDBO(
          (await userActivityRepository.getAllUserActivityDBO()).single,
        ),
      );

      final config = await configRepository.getConfig();
      expect(config.healthDeletedExternalIds, isEmpty);
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
