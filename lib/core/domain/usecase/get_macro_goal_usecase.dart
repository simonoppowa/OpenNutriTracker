import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';

class GetMacroGoalUsecase {
  final ConfigRepository _configRepository;

  GetMacroGoalUsecase(this._configRepository);

  /// The carbs goal for [totalCalorieGoal]: the user's gram goal when one is
  /// in effect (#642), which does not depend on the calorie goal, otherwise
  /// the split's share of it.
  Future<double> getCarbsGoal(double totalCalorieGoal) async {
    final config = await _configRepository.getConfig();
    final grams = config.macroGramGoals;
    if (grams != null) return grams.carbs;

    return MacroCalc.getTotalCarbsGoal(
      totalCalorieGoal,
      userCarbsGoal: config.userCarbGoalPct,
    );
  }

  Future<double> getFatsGoal(double totalCalorieGoal) async {
    final config = await _configRepository.getConfig();
    final grams = config.macroGramGoals;
    if (grams != null) return grams.fat;

    return MacroCalc.getTotalFatsGoal(
      totalCalorieGoal,
      userFatsGoal: config.userFatGoalPct,
    );
  }

  Future<double> getProteinsGoal(double totalCalorieGoal) async {
    final config = await _configRepository.getConfig();
    final grams = config.macroGramGoals;
    if (grams != null) return grams.protein;

    return MacroCalc.getTotalProteinsGoal(
      totalCalorieGoal,
      userProteinsGoal: config.userProteinGoalPct,
    );
  }

  /// What an activity that burned [burnedKcal] adds to a day's macro goals
  /// (negative to take it off again): nothing while gram goals are in
  /// effect (#642), see [MacroGramGoals.activityShare].
  Future<MacroGrams> getActivityMacroShare(double burnedKcal) async {
    final config = await _configRepository.getConfig();
    return MacroGramGoals.activityShare(
      burnedKcal,
      gramGoals: config.macroGramGoals != null,
    );
  }
}
