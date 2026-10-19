import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
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
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_writer.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../fixture/user_entity_fixtures.dart';
import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';

/// Today's intake, read meal by meal. [duringLoad] runs at the first read,
/// standing in for whatever happens while the load is still reading.
class _Intake extends Fake implements GetIntakeUsecase {
  final void Function() duringLoad;

  _Intake(this.duringLoad);

  @override
  Future<List<IntakeEntity>> getTodayBreakfastIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async {
    duringLoad();
    return [];
  }

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
  @override
  Future<double> getCarbsGoal(double totalCalorieGoal) async => 0;

  @override
  Future<double> getFatsGoal(double totalCalorieGoal) async => 0;

  @override
  Future<double> getProteinsGoal(double totalCalorieGoal) async => 0;
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
    final configRepository = ConfigRepository(configs);

    final bloc = HomeBloc(
      GetConfigUsecase(configRepository),
      AddConfigUsecase(configRepository),
      _Intake(duringLoad ?? () {}),
      _UnusedDeleteIntakeUsecase(),
      _UnusedUpdateIntakeUsecase(),
      _NoActivities(),
      _UnusedDeleteUserActivityUsecase(),
      _UnusedAddTrackedDayUsecase(),
      _KcalGoal(),
      _MacroGoal(),
      _UnusedUpdateUserActivityUsecase(),
      _User(),
      _NoWater(),
      _UnusedAddWaterIntakeUsecase(),
      _UnusedDeleteWaterIntakeUsecase(),
      calorieWidgetStore: store,
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
