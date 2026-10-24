import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// #1440: moving "Day starts at" to 23:00 and back to 0:00 replaced
/// 2026-10-14's stored goals with 2026-10-13's and nulled its nutrient
/// goals.
///
/// Mirrors release run #1434, step DD2: two rows on consecutive days with
/// different goals, as 2.4.0 wrote them (keyed by date, `day` the moment
/// the row was created), each holding one entry logged from Home at a
/// clock time before 23:00, and nothing logged on the day after the
/// second.
///
/// Under 23:00 a clock-time entry is listed on the day before its
/// calendar date, so every row's entries move a day back. The pass used
/// to delete the row its entries left and rebuild a row for the day they
/// reached from the nearest row's goals; the round trip then rebuilt the
/// 14th from the 13th. A row now moves with its entries instead.
final _meal = MealEntity(
  code: null,
  name: 'Toast',
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: 100,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity(
    energyKcal100: 200,
    carbohydrates100: 40,
    fat100: 2,
    proteins100: 6,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<ConfigDBO> configBox;
  late Box<IntakeDBO> intakeBox;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<UserActivityDBO> activityBox;
  late FakeHiveDBProvider db;
  late IntakeRepository intakeRepository;
  late AddTrackedDayUsecase addTrackedDay;
  late SetDayBoundaryUsecase setDayBoundary;

  setUpAll(() {
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    final tag = DateTime.now().microsecondsSinceEpoch;
    configBox = await Hive.openBox<ConfigDBO>('r1440_config_$tag');
    intakeBox = await Hive.openBox<IntakeDBO>('r1440_intake_$tag');
    trackedDayBox = await Hive.openBox<TrackedDayDBO>('r1440_day_$tag');
    activityBox = await Hive.openBox<UserActivityDBO>('r1440_act_$tag');
    db = FakeHiveDBProvider(
      configBox: configBox,
      intakeBox: intakeBox,
      trackedDayBox: trackedDayBox,
      userActivityBox: activityBox,
    );
    await ConfigDataSource(db).initializeConfig();
    intakeRepository = IntakeRepository(IntakeDataSource(db));
    addTrackedDay = AddTrackedDayUsecase(
      TrackedDayRepository(TrackedDayDataSource(db)),
    );
    setDayBoundary = SetDayBoundaryUsecase(db, ConfigDataSource(db));
    // The run's clock: 22:15 on 2026-10-22, before the 23:00 boundary.
    DayBoundaryCalc.clock = () => DateTime(2026, 10, 22, 22, 15);
  });

  tearDown(() async {
    DayBoundaryCalc.clock = DateTime.now;
    await configBox.deleteFromDisk();
    await intakeBox.deleteFromDisk();
    await trackedDayBox.deleteFromDisk();
    await activityBox.deleteFromDisk();
  });

  /// One 200 kcal toast logged at [at].
  Future<void> logToast(String id, DateTime at) => intakeRepository.addIntake(
    IntakeEntity(
      id: id,
      unit: 'g',
      amount: 100,
      type: IntakeTypeEntity.breakfast,
      meal: _meal,
      dateTime: at,
    ),
  );

  /// The 13th as the run left it: goals from an older weight, fibre 42,
  /// no per-nutrient goals of its own.
  TrackedDayDBO the13thRow(DateTime day) => TrackedDayDBO(
    day: day,
    calorieGoal: 3004.6,
    caloriesTracked: 200,
    carbsGoal: 375.6,
    carbsTracked: 40,
    fatGoal: 106.8,
    fatTracked: 2,
    proteinGoal: 135.2,
    proteinTracked: 6,
    fibreGoal: 42,
  );

  /// The 14th: other goals, and every per-nutrient goal set.
  TrackedDayDBO the14thRow(DateTime day) => TrackedDayDBO(
    day: day,
    calorieGoal: 2743.9,
    caloriesTracked: 200,
    carbsGoal: 343.0,
    carbsTracked: 40,
    fatGoal: 94.5,
    fatTracked: 2,
    proteinGoal: 130.3,
    proteinTracked: 6,
    fibreGoal: 44,
    satFatGoal: 20,
    sugarsGoal: 50,
    sodiumGoal: 2300,
    calciumGoal: 1000,
    ironGoal: 12.5,
    potassiumGoal: 3500,
    vitaminDGoal: 15,
    vitaminB12Goal: 2.4,
    magnesiumGoal: 400,
  );

  /// 2026-10-13 and 2026-10-14 with an entry each, and nothing logged on
  /// the 15th.
  ///
  /// With [labelledRows], `day` is the midnight label 2.5.0 writes instead
  /// of 2.4.0's creation moment.
  Future<void> seedTwoDays({
    DateTime? onThe14th,
    bool labelledRows = false,
  }) async {
    final the13th = DateTime(2026, 10, 13, 17, 45, 46, 541);
    final the14th = onThe14th ?? DateTime(2026, 10, 14, 20, 17, 10, 732);
    await logToast('13th', the13th);
    await logToast('14th', the14th);
    await trackedDayBox.put(
      '2026-10-13',
      the13thRow(labelledRows ? DateTime(2026, 10, 13) : the13th),
    );
    await trackedDayBox.put(
      '2026-10-14',
      the14thRow(labelledRows ? DateTime(2026, 10, 14) : the14th),
    );
  }

  /// Every row, by key, as the Diary reads it.
  Map<dynamic, TrackedDayEntity> snapshot() => {
    for (final key in trackedDayBox.keys)
      key: TrackedDayEntity.fromTrackedDayDBO(trackedDayBox.get(key)!),
  };

  group('a 23:00 round trip over rows 2.4.0 keyed by clock time', () {
    test('gives every row back with all its goals, its key and its '
        'day', () async {
      await seedTwoDays();
      final before = snapshot();

      await setDayBoundary.setDayBoundary(23, 0);
      await setDayBoundary.setDayBoundary(0, 0);

      expect(snapshot(), before);
    });

    test('the same with a nutrient-goal save between', () async {
      await seedTwoDays();
      final before = snapshot();

      await setDayBoundary.setDayBoundary(23, 0);
      // Settings → Nutrient goals → Save: the logical day under 23:00.
      final today = DayBoundaryCalc.currentLogicalDayMinutes(23 * 60);
      expect(today, DateTime(2026, 10, 21));
      await addTrackedDay.addNewTrackedDayIfAbsent(today, 2702.4, 337, 90, 135);
      await addTrackedDay.updateDayNutrientGoals(today, fibreGoal: 44);
      await setDayBoundary.setDayBoundary(0, 0);

      final after = snapshot();
      expect(after.remove('2026-10-21')!.fibreGoal, 44);
      expect(after, before);
    });

    test('under 23:00 each row is on the day its entry is listed '
        'under', () async {
      await seedTwoDays();
      final the13th = TrackedDayEntity.fromTrackedDayDBO(
        trackedDayBox.get('2026-10-13')!,
      );
      final the14th = TrackedDayEntity.fromTrackedDayDBO(
        trackedDayBox.get('2026-10-14')!,
      );

      await setDayBoundary.setDayBoundary(23, 0);

      final moved = snapshot();
      expect(moved.keys, unorderedEquals(['2026-10-12', '2026-10-13']));
      expect(
        moved['2026-10-12'],
        _onDay(the13th, DateTime(2026, 10, 12, 17, 45, 46, 541)),
      );
      expect(
        moved['2026-10-13'],
        _onDay(the14th, DateTime(2026, 10, 13, 20, 17, 10, 732)),
      );
    });

    test('rows written by 2.5.0, keyed at midnight, come back the '
        'same', () async {
      await seedTwoDays(labelledRows: true);
      final before = snapshot();

      await setDayBoundary.setDayBoundary(23, 0);
      await setDayBoundary.setDayBoundary(0, 0);

      expect(snapshot(), before);
    });
  });

  test('a 04:00 round trip leaves a day with an entry after 04:00 as it '
      'was', () async {
    await seedTwoDays();
    final before = snapshot();

    await setDayBoundary.setDayBoundary(4, 0);
    await setDayBoundary.setDayBoundary(0, 0);

    expect(snapshot(), before);
  });

  group('a day whose only entry joins a day with a row of its own', () {
    // Under 04:00 the 14th's 01:30 toast is listed on the 13th, which
    // keeps its own 17:45 toast, so the 14th's row has nowhere to go.
    final early = DateTime(2026, 10, 14, 1, 30);

    test('keeps its row and goals while it lists nothing', () async {
      await seedTwoDays(onThe14th: early);

      await setDayBoundary.setDayBoundary(4, 0);

      final the13th = trackedDayBox.get('2026-10-13')!;
      expect(the13th.caloriesTracked, 400);
      expect(the13th.calorieGoal, 3004.6);
      final the14th = trackedDayBox.get('2026-10-14');
      expect(the14th, isNotNull, reason: 'its goals are its own');
      expect(the14th!.caloriesTracked, 0);
      expect(the14th.carbsTracked, 0);
      expect(the14th.calorieGoal, 2743.9);
      expect(the14th.ironGoal, 12.5);
    });

    test('a 04:00 round trip gives every row back', () async {
      await seedTwoDays(onThe14th: early);
      final before = snapshot();

      await setDayBoundary.setDayBoundary(4, 0);
      await setDayBoundary.setDayBoundary(0, 0);

      expect(snapshot(), before);
    });
  });

  test('a day split by the move gives its early entry the goals it was '
      'logged under, and a round trip adds no row', () async {
    // The 13th and the 15th have rows with other goals; nothing was
    // logged on the 14th. Under 04:00 the 15th's 02:00 toast is listed on
    // the 14th, and its 12:00 toast keeps the 15th's row where it is.
    await logToast('13th', DateTime(2026, 10, 13, 12));
    await logToast('15th-early', DateTime(2026, 10, 15, 2));
    await logToast('15th-noon', DateTime(2026, 10, 15, 12));
    await trackedDayBox.put('2026-10-13', the13thRow(DateTime(2026, 10, 13)));
    await trackedDayBox.put(
      '2026-10-15',
      the14thRow(DateTime(2026, 10, 15))
        ..caloriesTracked = 400
        ..carbsTracked = 80
        ..fatTracked = 4
        ..proteinTracked = 12,
    );
    final before = snapshot();

    await setDayBoundary.setDayBoundary(4, 0);

    final the14th = trackedDayBox.get('2026-10-14')!;
    expect(the14th.caloriesTracked, 200);
    expect(the14th.calorieGoal, 2743.9, reason: 'the 15th\'s, not the 13th\'s');
    expect(the14th.ironGoal, 12.5);
    expect(trackedDayBox.get('2026-10-15')!.caloriesTracked, 200);

    await setDayBoundary.setDayBoundary(0, 0);

    expect(snapshot(), before);
  });

  // #1441: Home shows the current goals, the Diary the logical today's
  // row. With the boundary moved past the hour, the logical today used to
  // keep yesterday's row, set under an older macro split.
  test('under 23:00 the logical today has the row today\'s entries were '
      'logged under, with today\'s macro split', () async {
    // Yesterday under 50/19/31, today under 45/21/34, both 2934 kcal.
    await logToast('21st', DateTime(2026, 10, 21, 12));
    await logToast('22nd', DateTime(2026, 10, 22, 19));
    await trackedDayBox.put(
      '2026-10-21',
      TrackedDayDBO(
        day: DateTime(2026, 10, 21),
        calorieGoal: 2934,
        caloriesTracked: 200,
        carbsGoal: 366.8,
        carbsTracked: 40,
        fatGoal: 61.9,
        fatTracked: 2,
        proteinGoal: 227.4,
        proteinTracked: 6,
      ),
    );
    await trackedDayBox.put(
      '2026-10-22',
      TrackedDayDBO(
        day: DateTime(2026, 10, 22),
        calorieGoal: 2934,
        caloriesTracked: 200,
        carbsGoal: 330.1,
        carbsTracked: 40,
        fatGoal: 68.5,
        fatTracked: 2,
        proteinGoal: 249.4,
        proteinTracked: 6,
      ),
    );

    await setDayBoundary.setDayBoundary(23, 0);

    final today = DayBoundaryCalc.currentLogicalDayMinutes(23 * 60);
    expect(today, DateTime(2026, 10, 21));
    final row = trackedDayBox.get('2026-10-21')!;
    expect(row.caloriesTracked, 200);
    expect(row.carbsGoal, 330.1);
    expect(row.fatGoal, 68.5);
    expect(row.proteinGoal, 249.4);
  });
}

/// [row] with its `day` moved to [day].
TrackedDayEntity _onDay(TrackedDayEntity row, DateTime day) => TrackedDayEntity(
  day: day,
  calorieGoal: row.calorieGoal,
  caloriesTracked: row.caloriesTracked,
  carbsGoal: row.carbsGoal,
  carbsTracked: row.carbsTracked,
  fatGoal: row.fatGoal,
  fatTracked: row.fatTracked,
  proteinGoal: row.proteinGoal,
  proteinTracked: row.proteinTracked,
  fibreGoal: row.fibreGoal,
  satFatGoal: row.satFatGoal,
  sugarsGoal: row.sugarsGoal,
  sodiumGoal: row.sodiumGoal,
  calciumGoal: row.calciumGoal,
  ironGoal: row.ironGoal,
  potassiumGoal: row.potassiumGoal,
  vitaminDGoal: row.vitaminDGoal,
  vitaminB12Goal: row.vitaminB12Goal,
  magnesiumGoal: row.magnesiumGoal,
);
