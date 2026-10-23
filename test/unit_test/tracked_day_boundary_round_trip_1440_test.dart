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
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// #1440: moving "Day starts at" to 23:00 and back to 0:00 replaced
/// 2026-10-14's stored goals with 2026-10-13's.
///
/// Mirrors release run #1434, step DD2: two rows on consecutive days with
/// different goals, each holding one entry logged from Home at a clock
/// time before 23:00, and nothing logged on the day after the second.
///
/// The move to 23:00 lists 2026-10-14's entry under 2026-10-13, so
/// `reconcileTrackedDays` finds the 14th's row listing nothing while it
/// still counts calories, and deletes it. The move back lists the entry on
/// the 14th again, finds no row there, and `_newRow` builds one from the
/// nearest row (ties go to the earlier day): the 13th's goals and
/// per-nutrient goals, keyed at midnight. The nutrient-goal save in
/// between plays no part, and neither does the row's 2.4.0-era `day`.
///
/// These tests describe the expected behaviour. On c293acff4 all but the
/// 04:00 round trip over a day with an entry after 04:00 fail; on 2.4.0
/// (680eafaa8), where a boundary change is only a config write, all pass.
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

  /// A row as 2.4.0 wrote it: keyed by date, `day` the creation moment,
  /// holding one toast.
  TrackedDayDBO row(
    DateTime createdAt, {
    required double kcalGoal,
    double? ironGoal,
    double? fibreGoal,
  }) => TrackedDayDBO(
    day: createdAt,
    calorieGoal: kcalGoal,
    caloriesTracked: 200,
    carbsGoal: kcalGoal / 8,
    carbsTracked: 40,
    fatGoal: kcalGoal / 30,
    fatTracked: 2,
    proteinGoal: kcalGoal / 20,
    proteinTracked: 6,
    fibreGoal: fibreGoal,
    ironGoal: ironGoal,
  );

  /// 2026-10-13 and 2026-10-14 as the run left them: different goals, an
  /// entry each before 23:00, and nothing logged on the 15th.
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
      row(
        labelledRows ? DateTime(2026, 10, 13) : the13th,
        kcalGoal: 3004.6,
        fibreGoal: 42,
      ),
    );
    await trackedDayBox.put(
      '2026-10-14',
      row(
        labelledRows ? DateTime(2026, 10, 14) : the14th,
        kcalGoal: 2743.9,
        fibreGoal: 44,
        ironGoal: 12.5,
      ),
    );
  }

  void expectThe14thKeepsItsGoals() {
    final the14th = trackedDayBox.get('2026-10-14');
    expect(the14th, isNotNull);
    expect(the14th!.calorieGoal, 2743.9, reason: 'calorie goal');
    expect(the14th.carbsGoal, 2743.9 / 8, reason: 'carbs goal');
    expect(the14th.fibreGoal, 44, reason: 'fibre goal');
    expect(the14th.ironGoal, 12.5, reason: 'iron goal');
    expect(the14th.caloriesTracked, 200);
  }

  test('a 23:00 round trip with a nutrient-goal save between keeps the '
      'goals of 2026-10-14', () async {
    await seedTwoDays();

    await setDayBoundary.setDayBoundary(23, 0);
    // Settings → Nutrient goals → Save: the logical day under 23:00.
    final today = DayBoundaryCalc.currentLogicalDayMinutes(23 * 60);
    expect(today, DateTime(2026, 10, 21));
    await addTrackedDay.addNewTrackedDayIfAbsent(today, 2702.4, 337, 90, 135);
    await addTrackedDay.updateDayNutrientGoals(today, fibreGoal: 44);
    await setDayBoundary.setDayBoundary(0, 0);

    expectThe14thKeepsItsGoals();
  });

  test('the same round trip with no save in between', () async {
    await seedTwoDays();

    await setDayBoundary.setDayBoundary(23, 0);
    await setDayBoundary.setDayBoundary(0, 0);

    expectThe14thKeepsItsGoals();
  });

  test('the move to 23:00 alone keeps a row for 2026-10-14', () async {
    await seedTwoDays();

    await setDayBoundary.setDayBoundary(23, 0);

    // Fails here: the row is deleted, since its day lists nothing.
    expect(trackedDayBox.containsKey('2026-10-14'), isTrue);
  });

  group('how wide the trigger is', () {
    test('rows written by 2.5.0, keyed at midnight, go the same way', () async {
      await seedTwoDays(labelledRows: true);

      await setDayBoundary.setDayBoundary(23, 0);
      await setDayBoundary.setDayBoundary(0, 0);

      expectThe14thKeepsItsGoals();
    });

    test('a 04:00 round trip keeps the goals of a day with an entry after '
        '04:00', () async {
      await seedTwoDays();

      await setDayBoundary.setDayBoundary(4, 0);
      await setDayBoundary.setDayBoundary(0, 0);

      expectThe14thKeepsItsGoals();
    });

    test('a 04:00 round trip keeps the goals of a day whose only entry was '
        'before 04:00', () async {
      await seedTwoDays(onThe14th: DateTime(2026, 10, 14, 1, 30));

      await setDayBoundary.setDayBoundary(4, 0);
      await setDayBoundary.setDayBoundary(0, 0);

      expectThe14thKeepsItsGoals();
    });
  });
}
