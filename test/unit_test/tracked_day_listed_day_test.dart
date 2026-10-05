import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/log_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/tracked_day_reconciler.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

import '../fixture/physical_activity_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// #1317: the Diary shows "Nothing added" for a day whose entries it lists.
///
/// The summary card is drawn only when the day has a tracked-day row, so
/// every writer has to put an entry's calories on the row of the day the
/// Diary lists that entry under. With a day-start boundary configured the
/// Diary files an entry logged at 02:00 under the previous day; these
/// tests pin that the row follows it. The later groups pin the pass that
/// brings rows written under another keying — by an older build, or
/// before the boundary moved — back in line with the listed entries.
class _FakeKcalGoal extends Fake implements GetKcalGoalUsecase {
  @override
  Future<double> getKcalGoal({
    dynamic userEntity,
    double? totalKcalActivitiesParam,
    double? kcalUserAdjustment,
  }) async => 2000;
}

class _FakeMacroGoal extends Fake implements GetMacroGoalUsecase {
  @override
  Future<double> getCarbsGoal(double totalCalorieGoal) async => 250;

  @override
  Future<double> getFatsGoal(double totalCalorieGoal) async => 70;

  @override
  Future<double> getProteinsGoal(double totalCalorieGoal) async => 100;
}

class _FakeProductsRepository extends Fake implements ProductsRepository {}

class _FakeRemoteSearchCache extends Fake
    implements RemoteSearchCacheDataSource {}

class _FakeContext extends Fake implements BuildContext {}

/// 200 kcal per 100 g, and no barcode, so logging it never reaches the
/// remote-cache refresh.
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

  late GetIntakeUsecase getIntake;
  late GetUserActivityUsecase getActivities;
  late GetTrackedDayUsecase getTrackedDay;
  late MealDetailBloc mealDetailBloc;
  late LogUserActivityUsecase logActivity;
  late IntakeRepository intakeRepository;
  late UserActivityRepository activityRepository;

  setUpAll(() {
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    final tag = DateTime.now().microsecondsSinceEpoch;
    configBox = await Hive.openBox<ConfigDBO>('listed_day_config_$tag');
    intakeBox = await Hive.openBox<IntakeDBO>('listed_day_intake_$tag');
    trackedDayBox = await Hive.openBox<TrackedDayDBO>('listed_day_day_$tag');
    activityBox = await Hive.openBox<UserActivityDBO>('listed_day_act_$tag');
    db = FakeHiveDBProvider(
      configBox: configBox,
      intakeBox: intakeBox,
      trackedDayBox: trackedDayBox,
      userActivityBox: activityBox,
    );
    await ConfigDataSource(db).initializeConfig();

    intakeRepository = IntakeRepository(IntakeDataSource(db));
    final trackedDayRepository = TrackedDayRepository(TrackedDayDataSource(db));
    activityRepository = UserActivityRepository(UserActivityDataSource(db));
    final addTrackedDay = AddTrackedDayUsecase(trackedDayRepository);
    getIntake = GetIntakeUsecase(intakeRepository);
    getActivities = GetUserActivityUsecase(activityRepository);
    getTrackedDay = GetTrackedDayUsecase(trackedDayRepository);
    mealDetailBloc = MealDetailBloc(
      AddIntakeUsecase(intakeRepository),
      addTrackedDay,
      _FakeKcalGoal(),
      _FakeMacroGoal(),
      getTrackedDay,
      _FakeProductsRepository(),
      _FakeRemoteSearchCache(),
    );
    logActivity = LogUserActivityUsecase(
      AddUserActivityUsecase(activityRepository),
      addTrackedDay,
      _FakeKcalGoal(),
      _FakeMacroGoal(),
    );
  });

  tearDown(() async {
    await mealDetailBloc.close();
    await configBox.deleteFromDisk();
    await intakeBox.deleteFromDisk();
    await trackedDayBox.deleteFromDisk();
    await activityBox.deleteFromDisk();
  });

  Future<void> setBoundary(int hours) =>
      ConfigDataSource(db).setConfigDayStartOffsetHours(hours);

  /// What the Diary's CalendarDayBloc loads for the cell [label].
  Future<({int intakes, int activities, TrackedDayDBO? row})> diaryDay(
    DateTime label, {
    int boundaryHours = 0,
  }) async {
    final intakes = await getIntake.getBreakfastIntakeByDay(
      label,
      dayStartOffsetHours: boundaryHours,
    );
    final activities = await getActivities.getUserActivityByDay(
      label,
      dayStartOffsetHours: boundaryHours,
    );
    final row = await getTrackedDay.getTrackedDay(label);
    return (
      intakes: intakes.length,
      activities: activities.length,
      row: row == null ? null : TrackedDayDBO.fromTrackedDayEntity(row),
    );
  }

  Future<void> addFood(DateTime day) => mealDetailBloc.addIntake(
    _FakeContext(),
    'g',
    '100',
    IntakeTypeEntity.breakfast,
    _meal,
    day,
  );

  UserActivityEntity activityAt(DateTime at) => UserActivityEntity(
    'walk-${at.microsecondsSinceEpoch}',
    30,
    150,
    at,
    PhysicalActivityFixtures.moderateBicycling,
  );

  group('without a day boundary', () {
    test('food added to a past Diary day gets that day\'s row', () async {
      // table_calendar hands the Diary a UTC midnight for the cell.
      final label = DateTime.utc(2026, 10, 1);
      await addFood(label);

      final day = await diaryDay(label);
      expect(day.intakes, 1);
      expect(day.row, isNotNull);
      expect(day.row!.caloriesTracked, 200);
    });

    test('an activity logged on a past day with food keeps the row', () async {
      final label = DateTime.utc(2026, 10, 1);
      await addFood(label);
      await logActivity.logActivity(activityAt(label), day: label);

      final day = await diaryDay(label);
      expect(day.intakes, 1);
      expect(day.activities, 1);
      expect(day.row!.caloriesTracked, 200);
      expect(day.row!.calorieGoal, 2150);
    });
  });

  group('with a 04:00 day boundary', () {
    setUp(() => setBoundary(4));

    test('food logged from Home at 02:00 lands on the row of the day the '
        'Diary lists it under', () async {
      // Home hands MealDetailBloc a raw DateTime.now().
      final at = DateTime(2026, 10, 5, 2);
      await addFood(at);

      final listedUnder = DateTime.utc(2026, 10, 4);
      final day = await diaryDay(listedUnder, boundaryHours: 4);
      expect(day.intakes, 1, reason: 'the Diary lists the 02:00 entry here');
      expect(day.row, isNotNull, reason: 'else the Diary says Nothing added');
      expect(day.row!.caloriesTracked, 200);

      final nextDay = await diaryDay(
        DateTime.utc(2026, 10, 5),
        boundaryHours: 4,
      );
      expect(nextDay.intakes, 0);
      expect(nextDay.row, isNull, reason: 'nothing is listed on the 5th');
    });

    test('an activity logged from Home at 02:00 raises the goal of the day '
        'the Diary lists it under', () async {
      final at = DateTime(2026, 10, 5, 2);
      await logActivity.logActivity(activityAt(at), day: at);

      final day = await diaryDay(DateTime.utc(2026, 10, 4), boundaryHours: 4);
      expect(day.activities, 1);
      expect(day.row, isNotNull);
      expect(day.row!.calorieGoal, 2150);
      expect(
        (await diaryDay(DateTime.utc(2026, 10, 5), boundaryHours: 4)).row,
        isNull,
      );
    });

    test('a Diary cell label is used as-is, not rolled back', () async {
      final label = DateTime.utc(2026, 10, 4);
      await addFood(label);

      final day = await diaryDay(label, boundaryHours: 4);
      expect(day.intakes, 1);
      expect(day.row!.caloriesTracked, 200);
      expect(day.row!.day.day, 4);
    });
  });

  /// An intake as an older build left it: in the box, with no row
  /// written for it here.
  Future<void> addLoggedIntake(String id, DateTime at) =>
      intakeRepository.addIntake(
        IntakeEntity(
          id: id,
          unit: 'g',
          amount: 100,
          type: IntakeTypeEntity.breakfast,
          meal: _meal,
          dateTime: at,
        ),
      );

  /// A row as an older build keyed it, holding one 200 kcal toast.
  TrackedDayDBO legacyRow(DateTime day, {double kcal = 200}) => TrackedDayDBO(
    day: day,
    calorieGoal: 1800,
    caloriesTracked: kcal,
    carbsGoal: 225,
    carbsTracked: kcal / 5,
    fatGoal: 60,
    fatTracked: kcal / 100,
    proteinGoal: 90,
    proteinTracked: kcal * 3 / 100,
    fibreGoal: 35,
  );

  double totalTracked() =>
      trackedDayBox.values.fold(0.0, (sum, row) => sum + row.caloriesTracked);

  Future<int> reconcile({Future<TrackedDayGoals> Function()? currentGoals}) =>
      ensureTrackedDaysMatchEntries(
        db,
        ConfigDataSource(db),
        currentGoals: currentGoals,
      );

  group('a row an older build keyed to another day than its entries', () {
    setUp(() => setBoundary(4));

    // Logged from Home at 02:00 under a 04:00 boundary: the Diary lists it
    // on the 4th, but the old keying put its calories on a row for the 5th.
    Future<void> logAsOlderBuild() async {
      await addLoggedIntake('toast', DateTime(2026, 10, 5, 2));
      await trackedDayBox.put(
        '2026-10-05',
        legacyRow(DateTime(2026, 10, 5, 2)),
      );
    }

    test('moves onto the day the Diary lists its entries under, and the '
        'stale row goes with its marker', () async {
      await logAsOlderBuild();

      expect(await reconcile(), 2);

      final day = await diaryDay(DateTime.utc(2026, 10, 4), boundaryHours: 4);
      expect(day.intakes, 1);
      expect(day.row, isNotNull, reason: 'else the Diary says Nothing added');
      expect(day.row!.caloriesTracked, 200);
      expect(day.row!.carbsTracked, 40);
      expect(day.row!.calorieGoal, 1800, reason: 'the nearest row\'s goal');
      expect(day.row!.fibreGoal, 35);

      final nextDay = await diaryDay(
        DateTime.utc(2026, 10, 5),
        boundaryHours: 4,
      );
      expect(nextDay.intakes, 0);
      expect(nextDay.row, isNull, reason: 'nothing is listed on the 5th');
      expect(totalTracked(), 200);
    });

    test('a later entry on the stale row\'s day starts a row of its '
        'own', () async {
      await logAsOlderBuild();
      await reconcile();

      await addFood(DateTime(2026, 10, 5, 12));

      final nextDay = await diaryDay(
        DateTime.utc(2026, 10, 5),
        boundaryHours: 4,
      );
      expect(nextDay.intakes, 1);
      expect(nextDay.row!.caloriesTracked, 200, reason: 'not 400');
      expect(totalTracked(), 400);
    });

    test('a second pass writes nothing', () async {
      await logAsOlderBuild();
      await reconcile();

      expect(await reconcile(), 0);
    });

    test('a row with nothing listed and nothing counted keeps its '
        'goal', () async {
      // Every entry of the 30th was deleted again; the row stays.
      await trackedDayBox.put(
        '2026-09-30',
        legacyRow(DateTime(2026, 9, 30), kcal: 0),
      );

      expect(await reconcile(), 0);
      expect(trackedDayBox.get('2026-09-30')!.calorieGoal, 1800);
    });
  });

  group('a profile an older build left without any row', () {
    final label = DateTime.utc(2026, 9, 20);

    Future<TrackedDayGoals> currentGoals() async =>
        (kcal: 2000.0, carbs: 250.0, fat: 70.0, protein: 100.0);

    test('gets the row of a day with entries, from the current goal raised '
        'by its activity, totals summed from its entries', () async {
      await addLoggedIntake('legacy-toast', label);
      await activityRepository.addUserActivity(activityAt(label));
      expect(await getTrackedDay.getTrackedDay(label), isNull);

      await reconcile(currentGoals: currentGoals);

      final row = (await diaryDay(label)).row!;
      expect(row.caloriesTracked, 200);
      expect(row.carbsTracked, 40);
      expect(row.calorieGoal, 2150);
      expect(row.carbsGoal, 250 + MacroCalc.getTotalCarbsGoal(150));
    });

    test('a day with nothing logged stays without a row', () async {
      await reconcile(currentGoals: currentGoals);
      expect(trackedDayBox.isEmpty, isTrue);
    });
  });

  group('moving the day boundary', () {
    late SetDayBoundaryUsecase setDayBoundary;

    setUp(() {
      setDayBoundary = SetDayBoundaryUsecase(db, ConfigDataSource(db));
    });

    test('takes the rows along: no entry counted twice, no marker left on '
        'a day with nothing listed', () async {
      await addFood(DateTime(2026, 10, 4, 12));
      await addFood(DateTime(2026, 10, 5, 2));
      expect((await diaryDay(DateTime.utc(2026, 10, 5))).row, isNotNull);

      await setDayBoundary.setDayBoundary(4, 0);

      final day = await diaryDay(DateTime.utc(2026, 10, 4), boundaryHours: 4);
      expect(day.intakes, 2);
      expect(day.row!.caloriesTracked, 400);
      final nextDay = await diaryDay(
        DateTime.utc(2026, 10, 5),
        boundaryHours: 4,
      );
      expect(nextDay.intakes, 0);
      expect(nextDay.row, isNull);
      expect(totalTracked(), 400);
    });

    test('moves the energy an activity burned with it, and back', () async {
      final at = DateTime(2026, 10, 5, 2);
      await addFood(DateTime(2026, 10, 4, 12));
      await logActivity.logActivity(activityAt(at), day: at);

      await setDayBoundary.setDayBoundary(4, 0);

      final day = await diaryDay(DateTime.utc(2026, 10, 4), boundaryHours: 4);
      expect(day.activities, 1);
      expect(day.row!.calorieGoal, 2150);
      expect(
        (await diaryDay(DateTime.utc(2026, 10, 5), boundaryHours: 4)).row,
        isNull,
      );

      await setDayBoundary.setDayBoundary(0, 0);

      final back = await diaryDay(DateTime.utc(2026, 10, 4));
      expect(back.row!.calorieGoal, 2000);
      expect(back.row!.caloriesTracked, 200);
      final nextDay = await diaryDay(DateTime.utc(2026, 10, 5));
      expect(nextDay.activities, 1);
      expect(nextDay.row!.calorieGoal, 2150);
      expect(nextDay.row!.caloriesTracked, 0);
    });

    test('a day that keeps entries of its own keeps its row', () async {
      await addFood(DateTime(2026, 10, 5, 2));
      await addFood(DateTime(2026, 10, 5, 12));

      await setDayBoundary.setDayBoundary(4, 0);

      final day = await diaryDay(DateTime.utc(2026, 10, 4), boundaryHours: 4);
      expect(day.row!.caloriesTracked, 200);
      expect(day.row!.calorieGoal, 2000);
      final nextDay = await diaryDay(
        DateTime.utc(2026, 10, 5),
        boundaryHours: 4,
      );
      expect(nextDay.row!.caloriesTracked, 200);
    });
  });

  group('writers running alongside the pass', () {
    test('a row another writer creates while the pass awaits the goals is '
        'updated, not replaced', () async {
      final label = DateTime.utc(2026, 9, 20);
      await addLoggedIntake('legacy-toast', label);

      await reconcile(
        currentGoals: () async {
          // The pass's one await: another screen logs a food on the same
          // day meanwhile, creating its row.
          await addFood(label);
          return (kcal: 1234.0, carbs: 1.0, fat: 1.0, protein: 1.0);
        },
      );

      final row = (await diaryDay(label)).row!;
      expect(row.caloriesTracked, 400, reason: 'both entries, once each');
      expect(row.calorieGoal, 2000, reason: 'the writer\'s goal stays');
    });

    test('reads and rewrites the rows before it first yields', () async {
      await setBoundary(4);
      await addLoggedIntake('toast', DateTime(2026, 10, 5, 2));
      await trackedDayBox.put(
        '2026-10-05',
        legacyRow(DateTime(2026, 10, 5, 2)),
      );

      final pending = reconcileTrackedDays(db, offsetMinutes: 4 * 60);
      // No other code has run since the call: there was no point at which
      // a writer could land between the pass's reads and its writes.
      expect(trackedDayBox.get('2026-10-04')?.caloriesTracked, 200);
      expect(trackedDayBox.containsKey('2026-10-05'), isFalse);
      expect(await pending, 2);
    });

    test('a writer holding a row across the pass adds to its rewritten '
        'totals', () async {
      await addFood(DateTime(2026, 10, 4, 12));
      // The tracked-day increments read the row, yield, then add and save.
      final held = trackedDayBox.get('2026-10-04')!;
      held.caloriesTracked = 999;
      await held.save();

      await reconcileTrackedDays(db, offsetMinutes: 0);
      held.caloriesTracked += 100;
      await held.save();

      expect(trackedDayBox.get('2026-10-04')!.caloriesTracked, 300);
    });
  });
}
