import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_goal_resolver.dart';

/// Today's goals when they are the user's own rather than the calculated
/// ones (#119): what the kcal explanation shows above the calculation.
class OwnGoalsSummary {
  final bool isTrainingDay;

  /// The fixed kcal goal before activity; null for a calculated goal.
  final double? fixedKcal;

  /// Today's kcal goal, as Home shows it.
  final double kcalGoal;

  /// Today's macro goals when they are set in grams.
  final MacroGoals? gramGoals;

  const OwnGoalsSummary({
    required this.isTrainingDay,
    required this.fixedKcal,
    required this.kcalGoal,
    required this.gramGoals,
  });

  /// Today's own goals, or null while the calculated goal and the split
  /// apply.
  static Future<OwnGoalsSummary?> load({
    required ConfigRepository configRepository,
    required GetKcalGoalUsecase getKcalGoalUsecase,
    required GetMacroGoalUsecase getMacroGoalUsecase,
  }) async {
    final config = await configRepository.getConfig();
    final today = DayBoundaryCalc.currentLogicalDayLabel(
      config.dayStartOffsetHours,
      config.dayStartOffsetMinutes,
    );
    final targets = config.goalTargetsFor(today);
    final fixed = targets.kcalMode == KcalGoalMode.fixed
        ? targets.fixedKcal
        : null;
    final grams =
        targets.macroMode == MacroGoalMode.grams &&
        targets.carbsG != null &&
        targets.fatG != null &&
        targets.proteinG != null;
    if (fixed == null && !grams) return null;
    final kcalGoal = await getKcalGoalUsecase.getKcalGoal();
    return OwnGoalsSummary(
      isTrainingDay:
          config.trainingPlan.isEnabled &&
          config.trainingPlan.dayTypeOf(today) == DayType.training,
      fixedKcal: fixed,
      kcalGoal: kcalGoal,
      gramGoals: grams
          ? await getMacroGoalUsecase.getMacroGoalsForDay(kcalGoal, today)
          : null,
    );
  }
}
