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
/// tests pin that the row follows it.
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

    final intakeRepository = IntakeRepository(IntakeDataSource(db));
    final trackedDayRepository = TrackedDayRepository(TrackedDayDataSource(db));
    final activityRepository = UserActivityRepository(
      UserActivityDataSource(db),
    );
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

      final nextDay = await diaryDay(DateTime.utc(2026, 10, 5), boundaryHours: 4);
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
}
