import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';

/// What the goals screen (#33) shows and edits: the profile's own goals,
/// its training days (#35), the macro split and the calculated kcal goal
/// the split and the grams are converted with.
class GoalSettingsStore {
  final ConfigRepository _config;
  final UserRepository _user;
  final Future<void> Function() _onSaved;

  /// [onSaved] refreshes the screens and today's tracked day after a save.
  GoalSettingsStore(
    this._config,
    this._user, {
    required Future<void> Function() onSaved,
  }) : _onSaved = onSaved;

  Future<GoalTargets> loadTargets() async =>
      (await _config.getConfig()).goalTargets;

  Future<TrainingPlan> loadTrainingPlan() async =>
      (await _config.getConfig()).trainingPlan;

  /// The macro split in percent, the app's default where none is set.
  Future<({double carbs, double fat, double protein})> loadSplit() async {
    final config = await _config.getConfig();
    return (
      carbs:
          (config.userCarbGoalPct ?? MacroCalc.defaultCarbsPercentageGoal) *
          100,
      fat: (config.userFatGoalPct ?? MacroCalc.defaultFatsPercentageGoal) * 100,
      protein:
          (config.userProteinGoalPct ??
              MacroCalc.defaultProteinsPercentageGoal) *
          100,
    );
  }

  /// The calculated daily kcal goal before activity.
  Future<double> calculatedKcal() async {
    final user = await _user.getUserData();
    final config = await _config.getConfig();
    return CalorieGoalCalc.getTotalKcalGoal(
      user,
      0,
      kcalUserAdjustment: config.userKcalAdjustment,
      caloriesTaperEnabled: user.caloriesTaperEnabled,
    );
  }

  Future<void> save(GoalTargets targets, TrainingPlan plan) async {
    await _config.setGoalTargets(targets);
    await _config.setTrainingPlan(plan);
    await _onSaved();
  }
}
