import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';

/// Writes an activity and raises the day's budget by what it burned — the
/// two halves that always have to happen together.
///
/// Logging an activity is never just a box insert: burned calories raise the
/// day's goal ceiling 1:1 (see `CalorieGoalCalc.getDailyKcalGoal`) and the
/// macro goals along with it, and a day that has never been tracked has to be
/// created first or there is nothing to raise. Every caller that writes an
/// activity outside the activity-detail screen goes through here rather than
/// re-deriving that sequence.
class LogUserActivityUsecase {
  final AddUserActivityUsecase _addUserActivityUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;

  LogUserActivityUsecase(
    this._addUserActivityUsecase,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
  );

  /// Persists [activity] and credits its burned energy to [day].
  ///
  /// [day] is a logical day label, not a moment — an activity's own timestamp
  /// can fall on the other side of a configured day boundary, so the caller
  /// resolves which diary column it belongs to. The budget is raised by
  /// [UserActivityEntity.burnedKcal], which is the figure the aggregation
  /// layer sums; entities that carry a user-entered kcal mirror it there.
  Future<void> logActivity(
    UserActivityEntity activity, {
    required DateTime day,
  }) async {
    await _addUserActivityUsecase.addUserActivity(activity);
    await _increaseDayGoals(day, activity.burnedKcal);
  }

  Future<void> _increaseDayGoals(DateTime day, double caloriesBurned) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (!hasTrackedDay) {
      final kcalGoal = await _getKcalGoalUsecase.getKcalGoal(
        totalKcalActivitiesParam: 0,
      );
      await _addTrackedDayUsecase.addNewTrackedDay(
        day,
        kcalGoal,
        await _getMacroGoalUsecase.getCarbsGoal(kcalGoal),
        await _getMacroGoalUsecase.getFatsGoal(kcalGoal),
        await _getMacroGoalUsecase.getProteinsGoal(kcalGoal),
      );
    }
    await _addTrackedDayUsecase.increaseDayCalorieGoal(day, caloriesBurned);
    await _addTrackedDayUsecase.increaseDayMacroGoals(
      day,
      carbsAmount: MacroCalc.getTotalCarbsGoal(caloriesBurned),
      fatAmount: MacroCalc.getTotalFatsGoal(caloriesBurned),
      proteinAmount: MacroCalc.getTotalProteinsGoal(caloriesBurned),
    );
  }
}
