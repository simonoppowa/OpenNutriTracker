import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';

/// Makes a day a training or a rest day by hand (#35) and moves that day's
/// stored goals to the goal set it now uses, so Home and the diary switch
/// at once.
class SetDayTypeUsecase {
  final ConfigRepository _configRepository;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;

  SetDayTypeUsecase(
    this._configRepository,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
    this._addTrackedDayUsecase,
  );

  Future<void> setDayType(DateTime day, DayType type) async {
    final plan = (await _configRepository.getConfig()).trainingPlan;
    await _configRepository.setTrainingPlan(plan.withDayType(day, type));
    if (!await _addTrackedDayUsecase.hasTrackedDay(day)) return;
    final kcalGoal = await _getKcalGoalUsecase.getKcalGoalForDay(day);
    final macros = await _getMacroGoalUsecase.getMacroGoalsForDay(
      kcalGoal,
      day,
    );
    await _addTrackedDayUsecase.updateDayCalorieGoal(day, kcalGoal);
    await _addTrackedDayUsecase.updateDayMacroGoals(
      day,
      carbsGoal: macros.carbsG,
      fatGoal: macros.fatG,
      proteinGoal: macros.proteinG,
    );
  }
}
