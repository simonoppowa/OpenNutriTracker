import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_goal_resolver.dart';

/// The macro goals in grams for a kcal goal: the user's split of it, or
/// their gram goals when they set them (#32, [MacroGoalResolver]); on a
/// training day the training goals (#35).
class GetMacroGoalUsecase {
  final ConfigRepository _configRepository;

  GetMacroGoalUsecase(this._configRepository);

  Future<double> getCarbsGoal(double totalCalorieGoal) async =>
      (await _goals(totalCalorieGoal, null)).carbsG;

  Future<double> getFatsGoal(double totalCalorieGoal) async =>
      (await _goals(totalCalorieGoal, null)).fatG;

  Future<double> getProteinsGoal(double totalCalorieGoal) async =>
      (await _goals(totalCalorieGoal, null)).proteinG;

  /// The macro goals of the day labelled [day].
  Future<MacroGoals> getMacroGoalsForDay(
    double totalCalorieGoal,
    DateTime day,
  ) => _goals(totalCalorieGoal, day);

  /// For the logical today when [day] is null.
  Future<MacroGoals> _goals(double totalCalorieGoal, DateTime? day) async {
    final config = await _configRepository.getConfig();
    final dayLabel =
        day ??
        DayBoundaryCalc.currentLogicalDayLabel(
          config.dayStartOffsetHours,
          config.dayStartOffsetMinutes,
        );
    return MacroGoalResolver.macros(
      config.goalTargetsFor(dayLabel),
      kcalGoal: totalCalorieGoal,
      carbsPct: config.userCarbGoalPct,
      fatPct: config.userFatGoalPct,
      proteinPct: config.userProteinGoalPct,
    );
  }
}
