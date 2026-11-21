import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/nutrient_goal_keys.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';

import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {
  @override
  Future<double> getKcalGoal({
    UserEntity? userEntity,
    double? totalKcalActivitiesParam,
    double? kcalUserAdjustment,
  }) async => 2000;
}

class _FakeGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {
  @override
  Future<double> getCarbsGoal(double totalCalorieGoal) async => 250;

  @override
  Future<double> getFatsGoal(double totalCalorieGoal) async => 67;

  @override
  Future<double> getProteinsGoal(double totalCalorieGoal) async => 100;
}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {}

class _FakeSetDayBoundaryUsecase extends Fake
    implements SetDayBoundaryUsecase {}

/// One profile's stack, wired the way `initLocator` wires it, over real
/// Hive boxes: the per-profile config and tracked-day boxes, plus the app
/// config box every profile shares.
class _Profile {
  final SettingsBloc bloc;
  final AddTrackedDayUsecase addTrackedDay;
  final GetTrackedDayUsecase getTrackedDay;

  _Profile._(this.bloc, this.addTrackedDay, this.getTrackedDay);

  factory _Profile(FakeHiveDBProvider db) {
    final configRepository = ConfigRepository(ConfigDataSource(db));
    final trackedDayRepository = TrackedDayRepository(TrackedDayDataSource(db));
    final addTrackedDay = AddTrackedDayUsecase(trackedDayRepository);
    final getTrackedDay = GetTrackedDayUsecase(trackedDayRepository);
    final bloc = SettingsBloc(
      GetConfigUsecase(configRepository),
      AddConfigUsecase(configRepository),
      addTrackedDay,
      _FakeGetKcalGoalUsecase(),
      _FakeGetMacroGoalUsecase(),
      _FakeRemoteSearchCacheDataSource(),
      getTrackedDay,
      _FakeSetDayBoundaryUsecase(),
    );
    return _Profile._(bloc, addTrackedDay, getTrackedDay);
  }

  /// Saves goals the way the Nutrient goals screen does: make sure the
  /// day's row exists, then write the screen's full snapshot.
  Future<void> saveGoals(
    DateTime day, {
    double? fibreGoal,
    double? sugarsGoal,
    double? ironGoal,
  }) async {
    await bloc.updateTrackedDay(day);
    await bloc.setTodayNutrientGoals(
      day,
      fibreGoal: fibreGoal,
      sugarsGoal: sugarsGoal,
      ironGoal: ironGoal,
      clearAll: true,
    );
  }

  /// Creates [day] the way logging a meal does (`MealDetailBloc`).
  Future<TrackedDayEntity> logOn(DateTime day) async {
    await addTrackedDay.addNewTrackedDayIfAbsent(day, 2000, 250, 67, 100);
    return (await getTrackedDay.getTrackedDay(day))!;
  }
}

void main() {
  // Day labels (midnight), so no day-boundary lookup moves them.
  final monday = DateTime(2026, 11, 2);
  final tuesday = DateTime(2026, 11, 3);
  final wednesday = DateTime(2026, 11, 4);

  late Directory dir;
  late Box<ConfigDBO> appConfigBox;
  late Box<ConfigDBO> configBoxA;
  late Box<TrackedDayDBO> trackedDayBoxA;
  late _Profile profileA;

  FakeHiveDBProvider providerA() => FakeHiveDBProvider(
    activeProfileId: 'a',
    configBox: configBoxA,
    appConfigBox: appConfigBox,
    trackedDayBox: trackedDayBoxA,
  );

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  Future<void> openBoxes() async {
    appConfigBox = await Hive.openBox<ConfigDBO>('app_config');
    configBoxA = await Hive.openBox<ConfigDBO>('config_a');
    trackedDayBoxA = await Hive.openBox<TrackedDayDBO>('tracked_day_a');
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nutrient_goals_1316_');
    Hive.init(dir.path);
    await openBoxes();
    profileA = _Profile(providerA());
  });

  tearDown(() async {
    await profileA.bloc.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  // #1316: the goal was written to the day it was set on only, so the next
  // day fell back to the defaults (iron 8 / 18 mg).
  test('a day created after the goal is set inherits it', () async {
    await profileA.saveGoals(monday, ironGoal: 30, fibreGoal: 40);

    final next = await profileA.logOn(tuesday);

    expect(next.ironGoal, 30);
    expect(next.fibreGoal, 40);
    // Goals the user never set stay unset, so they keep their defaults.
    expect(next.sugarsGoal, isNull);
    expect(next.sodiumGoal, isNull);
    expect(next.magnesiumGoal, isNull);
  });

  test('a day created through Settings inherits the goal too', () async {
    await profileA.saveGoals(monday, ironGoal: 30);

    // Saving any goal on a day without a row creates it (#1348).
    await profileA.bloc.updateTrackedDay(tuesday);

    final next = await profileA.getTrackedDay.getTrackedDay(tuesday);
    expect(next!.ironGoal, 30);
  });

  test('the day the goal is set on keeps it', () async {
    await profileA.saveGoals(monday, ironGoal: 30);

    final today = await profileA.getTrackedDay.getTrackedDay(monday);
    expect(today!.ironGoal, 30);
  });

  test(
    'a day created before the goal was set keeps the goals it had',
    () async {
      final before = await profileA.logOn(monday);
      expect(before.ironGoal, isNull);

      await profileA.saveGoals(tuesday, ironGoal: 30);

      final after = await profileA.getTrackedDay.getTrackedDay(monday);
      expect(after!.ironGoal, isNull);
      expect(after.calorieGoal, 2000);
    },
  );

  test('an existing day keeps its goals when the goal changes later', () async {
    await profileA.saveGoals(monday, ironGoal: 30);
    await profileA.logOn(tuesday);

    await profileA.saveGoals(wednesday, ironGoal: 12);

    expect((await profileA.getTrackedDay.getTrackedDay(tuesday))!.ironGoal, 30);
    expect(
      (await profileA.getTrackedDay.getTrackedDay(wednesday))!.ironGoal,
      12,
    );
  });

  test('an existing row is not touched by a later create', () async {
    await profileA.logOn(tuesday);
    await profileA.saveGoals(monday, ironGoal: 30);

    // Logging a second meal on Tuesday finds the row and leaves it be.
    final again = await profileA.logOn(tuesday);
    expect(again.ironGoal, isNull);
  });

  test('clearing a goal brings back the default for later days', () async {
    await profileA.saveGoals(monday, ironGoal: 30, fibreGoal: 40);

    // Reset + Save: the screen writes every field as null.
    await profileA.saveGoals(tuesday);

    final next = await profileA.logOn(wednesday);
    expect(next.ironGoal, isNull);
    expect(next.fibreGoal, isNull);
    expect(await profileA.bloc.getUserNutrientGoals(), isEmpty);
    // The day it was set on keeps the goal it was set with.
    expect((await profileA.getTrackedDay.getTrackedDay(monday))!.ironGoal, 30);
  });

  test('clearing one goal keeps the others', () async {
    await profileA.saveGoals(monday, ironGoal: 30, fibreGoal: 40);
    await profileA.saveGoals(tuesday, fibreGoal: 40);

    final next = await profileA.logOn(wednesday);
    expect(next.ironGoal, isNull);
    expect(next.fibreGoal, 40);
  });

  test('a goal of 0 is kept as 0, not read as unset', () async {
    await profileA.saveGoals(monday, sugarsGoal: 0);

    final next = await profileA.logOn(tuesday);
    expect(next.sugarsGoal, 0);
    expect(await profileA.bloc.getUserNutrientGoals(), {
      NutrientGoalKeys.sugars: 0,
    });
  });

  test('saving with no goals set leaves later days on the defaults', () async {
    await profileA.saveGoals(monday);

    final next = await profileA.logOn(tuesday);
    for (final goal in [
      next.fibreGoal,
      next.satFatGoal,
      next.sugarsGoal,
      next.sodiumGoal,
      next.calciumGoal,
      next.ironGoal,
      next.potassiumGoal,
      next.vitaminDGoal,
      next.vitaminB12Goal,
      next.magnesiumGoal,
    ]) {
      expect(goal, isNull);
    }
    expect(await profileA.bloc.getUserNutrientGoals(), isEmpty);
  });

  test('a partial update adds to the stored goals', () async {
    await profileA.saveGoals(monday, ironGoal: 30);
    await profileA.bloc.setTodayNutrientGoals(monday, fibreGoal: 40);

    expect(await profileA.bloc.getUserNutrientGoals(), {
      NutrientGoalKeys.iron: 30,
      NutrientGoalKeys.fibre: 40,
    });
    final next = await profileA.logOn(tuesday);
    expect(next.ironGoal, 30);
    expect(next.fibreGoal, 40);
  });

  test('a stored goal that is not a valid amount is ignored', () async {
    final db = providerA();
    await ConfigDataSource(db).initializeConfig();
    final stored = configBoxA.get('ConfigKey')!;
    stored.userNutrientGoals = {
      NutrientGoalKeys.iron: double.nan,
      NutrientGoalKeys.fibre: -5,
      'unknown': 3,
      NutrientGoalKeys.sodium: 1500,
    };
    await configBoxA.put('ConfigKey', stored);

    expect(await profileA.bloc.getUserNutrientGoals(), {
      NutrientGoalKeys.sodium: 1500,
    });
    final next = await profileA.logOn(tuesday);
    expect(next.ironGoal, isNull);
    expect(next.fibreGoal, isNull);
    expect(next.sodiumGoal, 1500);
  });

  test('a goal set on one profile does not reach another profile', () async {
    final configBoxB = await Hive.openBox<ConfigDBO>('config_b');
    final trackedDayBoxB = await Hive.openBox<TrackedDayDBO>('tracked_day_b');
    final profileB = _Profile(
      FakeHiveDBProvider(
        activeProfileId: 'b',
        configBox: configBoxB,
        appConfigBox: appConfigBox,
        trackedDayBox: trackedDayBoxB,
      ),
    );
    addTearDown(profileB.bloc.close);
    await ConfigDataSource(
      FakeHiveDBProvider(configBox: configBoxB, appConfigBox: appConfigBox),
    ).initializeConfig();

    await profileA.saveGoals(monday, ironGoal: 30);

    final onB = await profileB.logOn(tuesday);
    expect(onB.ironGoal, isNull);
    expect(await profileB.bloc.getUserNutrientGoals(), isEmpty);

    await profileB.saveGoals(tuesday, ironGoal: 12);
    final onA = await profileA.logOn(wednesday);
    expect(onA.ironGoal, 30);
  });

  test('the goal survives an app restart', () async {
    await profileA.saveGoals(monday, ironGoal: 30, sugarsGoal: 0);
    await profileA.bloc.close();

    await Hive.close();
    Hive.init(dir.path);
    await openBoxes();
    profileA = _Profile(providerA());

    expect(await profileA.bloc.getUserNutrientGoals(), {
      NutrientGoalKeys.iron: 30,
      NutrientGoalKeys.sugars: 0,
    });
    final next = await profileA.logOn(tuesday);
    expect(next.ironGoal, 30);
    expect(next.sugarsGoal, 0);
  });
}
