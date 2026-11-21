import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_writer.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';

/// #1441: with "Day starts at" moved past the current hour, Home and the
/// Diary showed different macro targets for the same logical day.
///
/// Home computes today's targets from the live goal settings. The Diary
/// shows the stored tracked-day row of the day it lists. The two agree
/// because every goal edit (and an import, #1394) rewrites the row of the
/// logical day from the live settings. A boundary move changes which day
/// is the logical day without that refresh, so the new day kept the split
/// it was stored with while Home showed the live one.
///
/// "Home" below is the real [HomeBloc]; "the Diary" reads the row the way
/// `CalendarDayBloc` and `DayInfoWidget` do.
final _toast = MealEntity(
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

typedef _Targets = ({double kcal, double carbs, double fat, double protein});

/// Hours in the local calendar day that starts at [day]'s midnight.
int _hoursIn(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1).difference(day).inHours;

String? _skipUnless(DateTime day, int hours, String what) =>
    _hoursIn(day) == hours
    ? null
    : 'no $what on $day in zone ${day.timeZoneName}; '
          'run `just test_dst` (TZ=Europe/Berlin)';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Box<dynamic>> boxes;
  late Box<TrackedDayDBO> trackedDayBox;
  late FakeHiveDBProvider db;
  late ConfigDataSource config;
  late IntakeRepository intakes;
  late GetKcalGoalUsecase kcalGoal;
  late GetMacroGoalUsecase macroGoal;
  late GetTrackedDayUsecase getTrackedDay;
  late SettingsBloc settings;
  late HomeBloc home;

  /// Settings wired to [setDayBoundary], the real move unless a test needs
  /// something to happen around it.
  SettingsBloc settingsWith(SetDayBoundaryUsecase setDayBoundary) {
    final configRepository = ConfigRepository(config);
    final trackedDays = TrackedDayRepository(TrackedDayDataSource(db));
    return SettingsBloc(
      GetConfigUsecase(configRepository),
      AddConfigUsecase(configRepository),
      AddTrackedDayUsecase(trackedDays),
      kcalGoal,
      macroGoal,
      _UnusedSearchCache(),
      GetTrackedDayUsecase(trackedDays),
      setDayBoundary,
    );
  }

  setUpAll(() {
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    final tag = DateTime.now().microsecondsSinceEpoch;
    Future<Box<T>> open<T>(String name) =>
        Hive.openBox<T>('i1441_${name}_$tag');
    final configBox = await open<ConfigDBO>('config');
    final intakeBox = await open<IntakeDBO>('intake');
    trackedDayBox = await open<TrackedDayDBO>('day');
    final activityBox = await open<UserActivityDBO>('activity');
    final userBox = await open<UserDBO>('user');
    boxes = [configBox, intakeBox, trackedDayBox, activityBox, userBox];
    db = FakeHiveDBProvider(
      configBox: configBox,
      intakeBox: intakeBox,
      trackedDayBox: trackedDayBox,
      userActivityBox: activityBox,
      userBox: userBox,
    );
    config = ConfigDataSource(db);
    await config.initializeConfig();
    await UserDataSource(db).saveUserData(
      UserDBO(
        birthday: DateTime(1990, 6, 15),
        heightCM: 180,
        weightKG: 80,
        gender: UserGenderDBO.male,
        goal: UserWeightGoalDBO.maintainWeight,
        pal: UserPALDBO.active,
      ),
    );

    final configRepository = ConfigRepository(config);
    final users = UserRepository(UserDataSource(db));
    final activities = UserActivityRepository(UserActivityDataSource(db));
    intakes = IntakeRepository(IntakeDataSource(db));
    kcalGoal = GetKcalGoalUsecase(users, configRepository, activities);
    macroGoal = GetMacroGoalUsecase(configRepository);
    getTrackedDay = GetTrackedDayUsecase(
      TrackedDayRepository(TrackedDayDataSource(db)),
    );
    settings = settingsWith(SetDayBoundaryUsecase(db, config));
    home = HomeBloc(
      GetConfigUsecase(configRepository),
      AddConfigUsecase(configRepository),
      _NoIntake(),
      _UnusedDeleteIntake(),
      _UnusedUpdateIntake(),
      _NoActivities(),
      _UnusedDeleteActivity(),
      _UnusedAddTrackedDay(),
      kcalGoal,
      macroGoal,
      _UnusedUpdateActivity(),
      GetUserUsecase(users),
      _NoWater(),
      _UnusedAddWater(),
      _UnusedDeleteWater(),
      calorieWidgetStore: _NoWidget(),
    );
  });

  tearDown(() async {
    DayBoundaryCalc.clock = DateTime.now;
    await home.close();
    await settings.close();
    for (final box in boxes) {
      await box.deleteFromDisk();
    }
  });

  void clockAt(DateTime now) => DayBoundaryCalc.clock = () => now;

  /// The targets Home shows for its logical today.
  Future<_Targets> homeTargets() async {
    home.add(const LoadItemsEvent());
    final state =
        await home.stream.firstWhere((s) => s is HomeLoadedState)
            as HomeLoadedState;
    return (
      kcal: state.totalKcalDaily,
      carbs: state.totalCarbsGoal,
      fat: state.totalFatsGoal,
      protein: state.totalProteinsGoal,
    );
  }

  /// The targets the Diary shows for [day]: its stored row.
  Future<_Targets> diaryTargets(DateTime day) async {
    final row = await getTrackedDay.getTrackedDay(day);
    expect(row, isNotNull, reason: 'no tracked-day row for $day');
    return (
      kcal: row!.calorieGoal,
      carbs: row.carbsGoal!,
      fat: row.fatGoal!,
      protein: row.proteinGoal!,
    );
  }

  /// What the live settings give: Home's figures when nothing is logged.
  Future<_Targets> liveTargets() async {
    final kcal = await kcalGoal.getKcalGoal();
    return (
      kcal: kcal,
      carbs: await macroGoal.getCarbsGoal(kcal),
      fat: await macroGoal.getFatsGoal(kcal),
      protein: await macroGoal.getProteinsGoal(kcal),
    );
  }

  /// Settings → Macro split → Save, as `MacroSplitDialog` does it.
  Future<void> saveSplit(int carbs, int protein, int fat) async {
    await settings.setMacroGoals(
      carbs.toDouble(),
      protein.toDouble(),
      fat.toDouble(),
    );
    await settings.updateTrackedDay(await settings.getCurrentLogicalDay());
  }

  /// A day with one toast logged at [loggedAt] and a row holding the
  /// goals of the split saved at the time.
  Future<void> seedDay(DateTime loggedAt) async {
    await intakes.addIntake(
      IntakeEntity(
        id: 'toast-${loggedAt.toIso8601String()}',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.breakfast,
        meal: _toast,
        dateTime: loggedAt,
      ),
    );
    final goals = await liveTargets();
    await trackedDayBox.put(
      _key(loggedAt),
      TrackedDayDBO(
        day: DateTime(loggedAt.year, loggedAt.month, loggedAt.day),
        calorieGoal: goals.kcal,
        caloriesTracked: 200,
        carbsGoal: goals.carbs,
        carbsTracked: 40,
        fatGoal: goals.fat,
        fatTracked: 2,
        proteinGoal: goals.protein,
        proteinTracked: 6,
      ),
    );
  }

  /// The release run's history: three days logged under 50/19/31, then
  /// the split changed to 45/21/34 at 22:15 on the 22nd.
  Future<void> seedReleaseRun() async {
    await settings.setMacroGoals(50, 19, 31);
    for (final day in [20, 21, 22]) {
      await seedDay(DateTime(2026, 10, day, 18));
    }
    clockAt(DateTime(2026, 10, 22, 22, 15));
    await saveSplit(45, 21, 34);
  }

  void expectSame(_Targets actual, _Targets expected, {String? reason}) {
    expect(actual.kcal, closeTo(expected.kcal, 1e-9), reason: reason);
    expect(actual.carbs, closeTo(expected.carbs, 1e-9), reason: reason);
    expect(actual.fat, closeTo(expected.fat, 1e-9), reason: reason);
    expect(actual.protein, closeTo(expected.protein, 1e-9), reason: reason);
  }

  test('without a moved boundary, Home and the Diary show the same '
      'targets for today', () async {
    await seedReleaseRun();
    final today = DateTime(2026, 10, 22);

    expectSame(await homeTargets(), await diaryTargets(today));
    expectSame(await diaryTargets(today), await liveTargets());
  });

  test('after moving the boundary past now, Home and the Diary show the '
      'same targets for the logical today (#1441)', () async {
    await seedReleaseRun();
    final oldSplit = await diaryTargets(DateTime(2026, 10, 21));

    await settings.setDayStartOffset(23, 0);
    final logicalToday = await settings.getCurrentLogicalDay();
    expect(logicalToday, DateTime(2026, 10, 21));

    final diary = await diaryTargets(logicalToday);
    expectSame(await homeTargets(), diary);
    expectSame(diary, await liveTargets());
    expect(diary.carbs, isNot(closeTo(oldSplit.carbs, 1e-9)));
  });

  test(
    'the move leaves the logged totals of the logical today alone',
    () async {
      await seedReleaseRun();

      await settings.setDayStartOffset(23, 0);

      final row = trackedDayBox.get('2026-10-21')!;
      // The 21st now lists the 22nd's toast, logged before 23:00; its own
      // moved on to the 20th.
      expect(row.caloriesTracked, 200);
      expect(row.carbsTracked, 40);
    },
  );

  test('a past day keeps the split it was stored with', () async {
    await seedReleaseRun();
    final the20th = await diaryTargets(DateTime(2026, 10, 20));

    await settings.setDayStartOffset(23, 0);

    expectSame(await diaryTargets(DateTime(2026, 10, 20)), the20th);
  });

  test('a move that keeps today on the same date leaves the day '
      'before alone', () async {
    await seedReleaseRun();
    final the21st = await diaryTargets(DateTime(2026, 10, 21));
    final the22nd = await diaryTargets(DateTime(2026, 10, 22));

    // At 22:15, a 17:00 boundary still makes it the 22nd, and the 18:00
    // entries stay on their dates.
    await settings.setDayStartOffset(17, 0);

    expect(await settings.getCurrentLogicalDay(), DateTime(2026, 10, 22));
    expectSame(await diaryTargets(DateTime(2026, 10, 21)), the21st);
    expectSame(await diaryTargets(DateTime(2026, 10, 22)), the22nd);
    expectSame(await homeTargets(), await diaryTargets(DateTime(2026, 10, 22)));
  });

  test('a move onto a logical day with no row creates none', () async {
    await settings.setMacroGoals(50, 19, 31);
    clockAt(DateTime(2026, 10, 22, 22, 15));

    await settings.setDayStartOffset(23, 0);

    expect(trackedDayBox.isEmpty, isTrue);
  });

  group('a split change at the boundary', () {
    setUp(() async {
      await settings.setMacroGoals(50, 19, 31);
      for (final day in [21, 22]) {
        await seedDay(DateTime(2026, 10, day, 23, 30));
      }
      await settings.setDayStartOffset(23, 0);
    });

    test('a second before 23:00 lands on the day that is ending', () async {
      final the22nd = await diaryTargets(DateTime(2026, 10, 22));
      clockAt(DateTime(2026, 10, 22, 22, 59, 59));

      await saveSplit(45, 21, 34);

      expectSame(
        await homeTargets(),
        await diaryTargets(DateTime(2026, 10, 21)),
      );
      expectSame(await diaryTargets(DateTime(2026, 10, 22)), the22nd);
    });

    test('23:00 itself lands on the day that starts', () async {
      final the21st = await diaryTargets(DateTime(2026, 10, 21));
      clockAt(DateTime(2026, 10, 22, 23));

      await saveSplit(45, 21, 34);

      expectSame(
        await homeTargets(),
        await diaryTargets(DateTime(2026, 10, 22)),
      );
      expectSame(await diaryTargets(DateTime(2026, 10, 21)), the21st);
    });
  });

  test('a profile switch between the move and the refresh drops the '
      'refresh', () async {
    await seedReleaseRun();
    final the21st = await diaryTargets(DateTime(2026, 10, 21));
    await settings.close();
    settings = settingsWith(_SwitchProfileAfterMove(db, config));

    await settings.setDayStartOffset(23, 0);

    // The refresh would land on the profile switched to; it must not run.
    expectSame(await diaryTargets(DateTime(2026, 10, 21)), the21st);
  });

  group('across a DST change (Europe/Berlin)', () {
    // 01:30, before the clocks go back: after it, DayBoundaryCalc subtracts
    // the offset as a Duration and lands an hour late on this 25-hour day.
    test('autumn: at 01:30 on the fall-back day, a 04:00 boundary refreshes '
        'the 24th', () async {
      await settings.setMacroGoals(50, 19, 31);
      await seedDay(DateTime(2026, 10, 23, 12));
      await seedDay(DateTime(2026, 10, 24, 12));
      clockAt(DateTime(2026, 10, 25, 1, 30));
      await settings.setMacroGoals(45, 21, 34);
      final the23rd = await diaryTargets(DateTime(2026, 10, 23));

      await settings.setDayStartOffset(4, 0);

      final logicalToday = await settings.getCurrentLogicalDay();
      expect(logicalToday, DateTime(2026, 10, 24));
      expectSame(await homeTargets(), await diaryTargets(logicalToday));
      expectSame(await diaryTargets(DateTime(2026, 10, 23)), the23rd);
    }, skip: _skipUnless(DateTime(2026, 10, 25), 25, 'autumn fall-back'));

    test('spring: at 03:30 on the spring-forward day, a 04:00 boundary '
        'refreshes the 28th', () async {
      await settings.setMacroGoals(50, 19, 31);
      await seedDay(DateTime(2026, 3, 27, 12));
      await seedDay(DateTime(2026, 3, 28, 12));
      clockAt(DateTime(2026, 3, 29, 3, 30));
      await settings.setMacroGoals(45, 21, 34);
      final the27th = await diaryTargets(DateTime(2026, 3, 27));

      await settings.setDayStartOffset(4, 0);

      final logicalToday = await settings.getCurrentLogicalDay();
      expect(logicalToday, DateTime(2026, 3, 28));
      expectSame(await homeTargets(), await diaryTargets(logicalToday));
      expectSame(await diaryTargets(DateTime(2026, 3, 27)), the27th);
    }, skip: _skipUnless(DateTime(2026, 3, 29), 23, 'spring-forward'));
  });
}

String _key(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// The real move, followed by a profile switch before anything else can
/// take the tracked-day lock.
class _SwitchProfileAfterMove extends SetDayBoundaryUsecase {
  _SwitchProfileAfterMove(super.hiveDBProvider, super.configDataSource);

  @override
  Future<void> setDayBoundary(int hours, int minutes) async {
    await super.setDayBoundary(hours, minutes);
    await withProfileSwitchLock(() async {});
  }
}

class _NoIntake extends Fake implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getTodayBreakfastIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

  @override
  Future<List<IntakeEntity>> getTodayLunchIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

  @override
  Future<List<IntakeEntity>> getTodayDinnerIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

  @override
  Future<List<IntakeEntity>> getTodaySnackIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];
}

class _NoActivities extends Fake implements GetUserActivityUsecase {
  @override
  Future<List<UserActivityEntity>> getTodayUserActivity({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];
}

class _NoWater extends Fake implements GetWaterIntakeUsecase {
  @override
  Future<List<WaterIntakeEntity>> getTodayEntries({
    required int dayStartOffsetTotalMinutes,
  }) async => [];
}

class _NoWidget implements CalorieWidgetStore {
  @override
  int generation = 0;

  @override
  Future<void> write(
    CalorieWidgetSnapshot snapshot,
    CalorieWidgetLabels labels, {
    int? generation,
  }) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> relabel(S s) async {}
}

class _UnusedSearchCache extends Fake implements RemoteSearchCacheDataSource {}

class _UnusedDeleteIntake extends Fake implements DeleteIntakeUsecase {}

class _UnusedUpdateIntake extends Fake implements UpdateIntakeUsecase {}

class _UnusedDeleteActivity extends Fake implements DeleteUserActivityUsecase {}

class _UnusedAddTrackedDay extends Fake implements AddTrackedDayUsecase {}

class _UnusedUpdateActivity extends Fake implements UpdateUserActivityUsecase {}

class _UnusedAddWater extends Fake implements AddWaterIntakeUsecase {}

class _UnusedDeleteWater extends Fake implements DeleteWaterIntakeUsecase {}
