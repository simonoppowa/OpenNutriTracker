import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {
  final bool existing;
  final List<List<Object>> addedDays = [];
  final List<(DateTime, double)> calorieGoalUpdates = [];
  final List<(DateTime, double?, double?, double?)> macroGoalUpdates = [];

  _FakeAddTrackedDayUsecase({required this.existing});

  @override
  Future<bool> hasTrackedDay(DateTime day) async => existing;

  @override
  Future<void> addNewTrackedDay(
    DateTime day,
    double totalKcalGoal,
    double totalCarbsGoal,
    double totalFatGoal,
    double totalProteinGoal,
  ) async {
    addedDays.add([
      day,
      totalKcalGoal,
      totalCarbsGoal,
      totalFatGoal,
      totalProteinGoal,
    ]);
  }

  @override
  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async {
    calorieGoalUpdates.add((day, calorieGoal));
  }

  @override
  Future<void> updateDayMacroGoals(
    DateTime day, {
    double? carbsGoal,
    double? fatGoal,
    double? proteinGoal,
  }) async {
    macroGoalUpdates.add((day, carbsGoal, fatGoal, proteinGoal));
  }
}

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

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {}

class _FakeAddConfigUsecase extends Fake implements AddConfigUsecase {}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {}

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeSetDayBoundaryUsecase extends Fake
    implements SetDayBoundaryUsecase {}

SettingsBloc _bloc(AddTrackedDayUsecase addTrackedDayUsecase) => SettingsBloc(
  _FakeGetConfigUsecase(),
  _FakeAddConfigUsecase(),
  addTrackedDayUsecase,
  _FakeGetKcalGoalUsecase(),
  _FakeGetMacroGoalUsecase(),
  _FakeRemoteSearchCacheDataSource(),
  _FakeGetTrackedDayUsecase(),
  _FakeSetDayBoundaryUsecase(),
);

void main() {
  final day = DateTime(2026, 10, 14);

  // #1348: saving goals on a day without a diary entry used to write
  // nothing, so follow-up writes such as the nutrient goals had no row.
  test('updateTrackedDay creates the tracked day from the current goals '
      'when none exists', () async {
    final addTrackedDayUsecase = _FakeAddTrackedDayUsecase(existing: false);
    final bloc = _bloc(addTrackedDayUsecase);
    addTearDown(bloc.close);

    await bloc.updateTrackedDay(day);

    expect(addTrackedDayUsecase.addedDays, [
      [day, 2000.0, 250.0, 67.0, 100.0],
    ]);
    expect(addTrackedDayUsecase.calorieGoalUpdates, isEmpty);
    expect(addTrackedDayUsecase.macroGoalUpdates, isEmpty);
  });

  test('updateTrackedDay updates an existing tracked day in place', () async {
    final addTrackedDayUsecase = _FakeAddTrackedDayUsecase(existing: true);
    final bloc = _bloc(addTrackedDayUsecase);
    addTearDown(bloc.close);

    await bloc.updateTrackedDay(day);

    expect(addTrackedDayUsecase.addedDays, isEmpty);
    expect(addTrackedDayUsecase.calorieGoalUpdates, [(day, 2000.0)]);
    expect(addTrackedDayUsecase.macroGoalUpdates, [(day, 250.0, 67.0, 100.0)]);
  });
}
