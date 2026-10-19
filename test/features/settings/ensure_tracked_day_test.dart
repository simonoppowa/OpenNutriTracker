import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_goal_resolver.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';

class _TrackedDays extends Fake implements AddTrackedDayUsecase {
  final Set<DateTime> existing;
  final created = <(DateTime, double, double, double, double)>[];

  _TrackedDays(this.existing);

  @override
  Future<bool> hasTrackedDay(DateTime day) async => existing.contains(day);

  @override
  Future<void> addNewTrackedDay(
    DateTime day,
    double totalKcalGoal,
    double totalCarbsGoal,
    double totalFatGoal,
    double totalProteinGoal,
  ) async {
    created.add((
      day,
      totalKcalGoal,
      totalCarbsGoal,
      totalFatGoal,
      totalProteinGoal,
    ));
  }
}

class _KcalGoal extends Fake implements GetKcalGoalUsecase {
  @override
  Future<double> getKcalGoalForDay(DateTime day) async => 2300;
}

class _MacroGoal extends Fake implements GetMacroGoalUsecase {
  @override
  Future<MacroGoals> getMacroGoalsForDay(
    double totalCalorieGoal,
    DateTime day,
  ) async => (carbsG: 280.0, fatG: 70.0, proteinG: 140.0);
}

class _Unused extends Fake
    implements
        GetConfigUsecase,
        AddConfigUsecase,
        RemoteSearchCacheDataSource,
        GetTrackedDayUsecase {}

SettingsBloc _bloc(AddTrackedDayUsecase trackedDays) => SettingsBloc(
  _Unused(),
  _Unused(),
  trackedDays,
  _KcalGoal(),
  _MacroGoal(),
  _Unused(),
  _Unused(),
);

void main() {
  final day = DateTime(2026, 10, 19);

  test('creates a missing day with the goals of that day', () async {
    final trackedDays = _TrackedDays({});

    await _bloc(trackedDays).ensureTrackedDay(day);

    expect(trackedDays.created, [(day, 2300.0, 280.0, 70.0, 140.0)]);
  });

  test('leaves an existing day alone', () async {
    final trackedDays = _TrackedDays({day});

    await _bloc(trackedDays).ensureTrackedDay(day);

    expect(trackedDays.created, isEmpty);
  });
}
