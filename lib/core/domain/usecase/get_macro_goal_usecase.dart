import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/calc/macro_goal_resolver.dart';

/// The day's macro goals in grams for a kcal goal: the user's split of it,
/// or their gram goals when they set them (#32, [MacroGoalResolver]).
class GetMacroGoalUsecase {
  final ConfigRepository _configRepository;

  GetMacroGoalUsecase(this._configRepository);

  Future<double> getCarbsGoal(double totalCalorieGoal) async =>
      (await _goals(totalCalorieGoal)).carbsG;

  Future<double> getFatsGoal(double totalCalorieGoal) async =>
      (await _goals(totalCalorieGoal)).fatG;

  Future<double> getProteinsGoal(double totalCalorieGoal) async =>
      (await _goals(totalCalorieGoal)).proteinG;

  Future<MacroGoals> _goals(double totalCalorieGoal) async {
    final config = await _configRepository.getConfig();
    return MacroGoalResolver.macros(
      config.goalTargets,
      kcalGoal: totalCalorieGoal,
      carbsPct: config.userCarbGoalPct,
      fatPct: config.userFatGoalPct,
      proteinPct: config.userProteinGoalPct,
    );
  }
}
