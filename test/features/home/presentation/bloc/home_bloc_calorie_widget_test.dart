import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
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
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_writer.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../fixture/user_entity_fixtures.dart';
import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';

/// Today's intake, read meal by meal. [duringLoad] runs at the first read,
/// standing in for whatever happens while the load is still reading.
class _Intake extends Fake implements GetIntakeUsecase {
  final void Function() duringLoad;
  final List<IntakeEntity> breakfast;
  final List<IntakeEntity> lunch;

  _Intake(this.duringLoad, {this.breakfast = const [], this.lunch = const []});

  @override
  Future<List<IntakeEntity>> getTodayBreakfastIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async {
    duringLoad();
    return breakfast;
  }

  @override
  Future<List<IntakeEntity>> getTodayLunchIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => lunch;

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

class _Water extends Fake implements GetWaterIntakeUsecase {
  final List<WaterIntakeEntity> entries;

  _Water([this.entries = const []]);

  @override
  Future<List<WaterIntakeEntity>> getTodayEntries({
    required int dayStartOffsetTotalMinutes,
  }) async => entries;
}

/// The day's own goals, as the nutrient panel reads them.
class _TrackedDay extends Fake implements GetTrackedDayUsecase {
  final TrackedDayEntity? day;
  final bool fails;
  final asked = <DateTime>[];

  _TrackedDay(this.day, {this.fails = false});

  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async {
    asked.add(day);
    if (fails) throw StateError('tracked day box is closed');
    return this.day;
  }
}

IntakeEntity _fibreRichIntake() => IntakeEntity(
  id: 'fibre-meal',
  unit: 'g',
  amount: 200,
  type: IntakeTypeEntity.breakfast,
  dateTime: DateTime(2026, 10, 5, 8),
  meal: MealEntity(
    code: 'test',
    name: 'test meal',
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    source: MealSourceEntity.custom,
    nutriments: MealNutrimentsEntity(
      energyKcal100: 100,
      carbohydrates100: 0,
      fat100: 0,
      proteins100: 0,
      sugars100: null,
      saturatedFat100: null,
      fiber100: 5,
      sodium100: 400,
    ),
  ),
);

class _User extends Fake implements GetUserUsecase {
  @override
  Future<UserEntity> getUserData() async =>
      UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
}

class _KcalGoal extends Fake implements GetKcalGoalUsecase {
  @override
  Future<double> getKcalGoal({
    UserEntity? userEntity,
    double? totalKcalActivitiesParam,
    double? kcalUserAdjustment,
  }) async => 2000;
}

class _MacroGoal extends Fake implements GetMacroGoalUsecase {
  final double carbs;
  final double fats;
  final double proteins;

  _MacroGoal({this.carbs = 0, this.fats = 0, this.proteins = 0});

  @override
  Future<double> getCarbsGoal(double totalCalorieGoal) async => carbs;

  @override
  Future<double> getFatsGoal(double totalCalorieGoal) async => fats;

  @override
  Future<double> getProteinsGoal(double totalCalorieGoal) async => proteins;
}

/// Drops a write from before a clear, as [HomeWidgetCalorieStore] does.
class _RecordingStore implements CalorieWidgetStore {
  final written = <CalorieWidgetSnapshot>[];

  @override
  int generation = 0;

  @override
  Future<void> write(
    CalorieWidgetSnapshot snapshot,
    CalorieWidgetLabels labels, {
    int? generation,
  }) async {
    if (generation != null && generation != this.generation) return;
    written.add(snapshot);
  }

  @override
  Future<void> clear() async => generation++;

  @override
  Future<void> relabel(S s) async {}
}

void main() {
  setUpAll(registerHiveAdaptersOnce);

  tearDown(() => DayBoundaryCalc.clock = DateTime.now);

  var boxTag = 0;

  /// A Home whose load runs [duringLoad] at its first intake read.
  Future<HomeBloc> home(
    CalorieWidgetStore store, {
    void Function()? duringLoad,
    GetWaterIntakeUsecase? water,
    GetMacroGoalUsecase? macroGoals,
    List<IntakeEntity> breakfast = const [],
    List<IntakeEntity> lunch = const [],
    GetTrackedDayUsecase? trackedDay,
    Map<String, bool>? nutrientVisibility,
  }) async {
    final db = FakeHiveDBProvider(
      configBox: await Hive.openBox<ConfigDBO>(
        'home_widget_config_${boxTag++}',
        bytes: Uint8List(0),
      ),
    );
    final configs = ConfigDataSource(db);
    await configs.initializeConfig();
    await configs.setConfigDayStartOffsetHours(4);
    if (nutrientVisibility != null) {
      await configs.setConfigNutrientPanelVisibility(nutrientVisibility);
    }
    final configRepository = ConfigRepository(configs);

    final bloc = HomeBloc(
      GetConfigUsecase(configRepository),
      AddConfigUsecase(configRepository),
      _Intake(duringLoad ?? () {}, breakfast: breakfast, lunch: lunch),
      _UnusedDeleteIntakeUsecase(),
      _UnusedUpdateIntakeUsecase(),
      _NoActivities(),
      _UnusedDeleteUserActivityUsecase(),
      _UnusedAddTrackedDayUsecase(),
      _KcalGoal(),
      macroGoals ?? _MacroGoal(),
      _UnusedUpdateUserActivityUsecase(),
      _User(),
      water ?? _Water(),
      _UnusedAddWaterIntakeUsecase(),
      _UnusedDeleteWaterIntakeUsecase(),
      calorieWidgetStore: store,
      getTrackedDayUsecase: trackedDay,
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<void> load(HomeBloc bloc) async {
    bloc.add(const LoadItemsEvent());
    await bloc.stream.firstWhere((state) => state is HomeLoadedState);
    await pumpEventQueue();
  }

  test('a load that crosses the day boundary stamps the widget with the day '
      'it read, not the one it finished in', () async {
    // Starts at 03:59:59 under a 04:00 boundary, still reading at 04:00.
    DayBoundaryCalc.clock = () => DateTime(2026, 10, 5, 3, 59, 59);
    final store = _RecordingStore();
    final bloc = await home(
      store,
      duringLoad: () =>
          DayBoundaryCalc.clock = () => DateTime(2026, 10, 5, 4, 0, 1),
    );

    await load(bloc);

    final snapshot = store.written.single;
    expect(snapshot.dayId, '2026-10-04');
    expect(
      snapshot.isCurrentAt(DayBoundaryCalc.clock()),
      isFalse,
      reason: 'the extension must expire it, not show it as the 5th',
    );
  });

  test(
    'a load publishes macro goals and today\'s water beside the ring',
    () async {
      final store = _RecordingStore();
      final bloc = await home(
        store,
        macroGoals: _MacroGoal(carbs: 300.4, fats: 66.6, proteins: 75),
        water: _Water([
          WaterIntakeEntity(
            id: 'a',
            dateTime: DateTime(2026, 10, 5, 9),
            amountMl: 250,
          ),
          WaterIntakeEntity(
            id: 'b',
            dateTime: DateTime(2026, 10, 5, 11),
            amountMl: 500,
          ),
        ]),
      );

      await load(bloc);

      final snapshot = store.written.single;
      expect(
        snapshot.macros,
        const CalorieWidgetMacros(
          proteinIntakeG: 0,
          proteinGoalG: 75,
          carbsIntakeG: 0,
          carbsGoalG: 300,
          fatsIntakeG: 0,
          fatsGoalG: 67,
        ),
      );
      // 750 ml drunk; the goal is the fixture user's own water goal.
      expect(
        snapshot.water,
        const CalorieWidgetWater(intakeMl: 750, goalMl: 1900),
      );
      expect(snapshot.toJson()['water'], {'ml': 750, 'goalMl': 1900});
    },
  );

  test(
    'a day with no water logged publishes zero millilitres, not none',
    () async {
      final store = _RecordingStore();
      final bloc = await home(store);

      await load(bloc);

      expect(
        store.written.single.water,
        const CalorieWidgetWater(intakeMl: 0, goalMl: 1900),
      );
    },
  );

  group('nutrients for the widget', () {
    test('a load publishes the panel nutrients it already summed', () async {
      final store = _RecordingStore();
      final tracked = _TrackedDay(
        TrackedDayEntity(
          day: DateTime(2026, 10, 5),
          calorieGoal: 2000,
          caloriesTracked: 0,
          fibreGoal: 28,
        ),
      );
      final bloc = await home(
        store,
        breakfast: [_fibreRichIntake()],
        lunch: [_fibreRichIntake()],
        trackedDay: tracked,
      );

      await load(bloc);

      final nutrients = store.written.single.nutrients;
      expect(nutrients.map((nutrient) => nutrient.id), NutrientPanelKeys.all);
      // Both meals count: 2 x (200 g x 5 / 100) = 20 g of fibre.
      final fibre = nutrients.firstWhere((n) => n.id == 'fiber');
      expect(fibre.consumed, 20);
      expect(fibre.unit, 'g');
      expect(fibre.goal, 28, reason: 'the day\'s own goal, as in the panel');
      final sodium = nutrients.firstWhere((n) => n.id == 'sodium');
      expect(sodium.consumed, 1600);
      expect(sodium.unit, 'mg');
    });

    test('the day it asks the goals of is the day the load read', () async {
      DayBoundaryCalc.clock = () => DateTime(2026, 10, 5, 3, 59, 59);
      final tracked = _TrackedDay(null);
      final store = _RecordingStore();
      final bloc = await home(store, trackedDay: tracked);

      await load(bloc);

      expect(tracked.asked, [DateTime(2026, 10, 4)]);
    });

    test('a nutrient the person hid is not published', () async {
      final store = _RecordingStore();
      final bloc = await home(
        store,
        nutrientVisibility: {'sodium': false},
        breakfast: [_fibreRichIntake()],
      );

      await load(bloc);

      final ids = store.written.single.nutrients.map((n) => n.id);
      expect(ids, isNot(contains('sodium')));
      expect(ids, contains('fiber'));
    });

    test('without a tracked-day source the published goals are the '
        'references', () async {
      final store = _RecordingStore();
      final bloc = await home(store);

      await load(bloc);

      final fibre = store.written.single.nutrients.firstWhere(
        (n) => n.id == 'fiber',
      );
      expect(fibre.goal, isNotNull);
      expect(fibre.consumed, 0);
    });

    test('a tracked-day read that fails costs the nutrients their own '
        'goals, not the write', () async {
      final store = _RecordingStore();
      final bloc = await home(
        store,
        trackedDay: _TrackedDay(null, fails: true),
        breakfast: [_fibreRichIntake()],
      );

      await load(bloc);

      final snapshot = store.written.single;
      expect(snapshot.hasData, isTrue);
      expect(snapshot.consumedKcal, 200, reason: 'the ring is untouched');
      expect(
        snapshot.nutrients.firstWhere((n) => n.id == 'fiber').consumed,
        10,
      );
    });

    test('a load read before a clear still drops its nutrients too', () async {
      final store = _RecordingStore();
      var cleared = false;
      final bloc = await home(
        store,
        breakfast: [_fibreRichIntake()],
        duringLoad: () {
          if (cleared) return;
          cleared = true;
          unawaited(store.clear());
        },
      );

      await load(bloc);

      expect(store.written, isEmpty);
    });
  });

  test('a load that read its figures before the widget was cleared does '
      'not write them back', () async {
    // An empty-profile switch or a delete-all clearing the widget while
    // Home is still reading the outgoing profile's totals.
    final store = _RecordingStore();
    var cleared = false;
    final bloc = await home(
      store,
      duringLoad: () {
        if (cleared) return;
        cleared = true;
        unawaited(store.clear());
      },
    );

    await load(bloc);
    expect(store.written, isEmpty);

    await load(bloc);
    expect(store.written, hasLength(1), reason: 'the next load still writes');
  });
}

class _UnusedDeleteIntakeUsecase extends Fake implements DeleteIntakeUsecase {}

class _UnusedUpdateIntakeUsecase extends Fake implements UpdateIntakeUsecase {}

class _UnusedDeleteUserActivityUsecase extends Fake implements DeleteUserActivityUsecase {}

class _UnusedAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {}

class _UnusedUpdateUserActivityUsecase extends Fake implements UpdateUserActivityUsecase {}

class _UnusedAddWaterIntakeUsecase extends Fake implements AddWaterIntakeUsecase {}

class _UnusedDeleteWaterIntakeUsecase extends Fake implements DeleteWaterIntakeUsecase {}
