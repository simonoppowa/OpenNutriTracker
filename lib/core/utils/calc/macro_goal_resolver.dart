import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';

/// The day's macro goals in grams.
typedef MacroGoals = ({double carbsG, double fatG, double proteinG});

/// Turns [GoalTargets] into the day's goals (#32).
///
/// A fixed kcal goal still gets the day's burned activity kcal added, like
/// the calculated one. Macro goals in grams stay as set; in percent mode
/// (or with a gram value missing) they are a split of the kcal goal with
/// 4 kcal per gram of carbohydrate and protein and 9 per gram of fat.
class MacroGoalResolver {
  static double kcalGoal(
    GoalTargets targets, {
    required double calculatedKcal,
    required double activityKcal,
  }) {
    final fixed = targets.fixedKcal;
    if (targets.kcalMode == KcalGoalMode.fixed && fixed != null) {
      return fixed + activityKcal;
    }
    return calculatedKcal;
  }

  static MacroGoals macros(
    GoalTargets targets, {
    required double kcalGoal,
    double? carbsPct,
    double? fatPct,
    double? proteinPct,
  }) {
    final (carbs, fat, protein) = (
      targets.carbsG,
      targets.fatG,
      targets.proteinG,
    );
    if (targets.macroMode == MacroGoalMode.grams &&
        carbs != null &&
        fat != null &&
        protein != null) {
      return (carbsG: carbs, fatG: fat, proteinG: protein);
    }
    return (
      carbsG: MacroCalc.getTotalCarbsGoal(kcalGoal, userCarbsGoal: carbsPct),
      fatG: MacroCalc.getTotalFatsGoal(kcalGoal, userFatsGoal: fatPct),
      proteinG: MacroCalc.getTotalProteinsGoal(
        kcalGoal,
        userProteinsGoal: proteinPct,
      ),
    );
  }

  static double kcalOfGrams({
    required double carbsG,
    required double fatG,
    required double proteinG,
  }) =>
      carbsG * MacroCalc.carbsKcalPerGram +
      fatG * MacroCalc.fatKcalPerGram +
      proteinG * MacroCalc.proteinKcalPerGram;

  /// The split of the kcal the grams stand for; null when they stand for
  /// none.
  static ({double carbs, double fat, double protein})? percentOfGrams({
    required double carbsG,
    required double fatG,
    required double proteinG,
  }) {
    final total = kcalOfGrams(carbsG: carbsG, fatG: fatG, proteinG: proteinG);
    if (total <= 0) return null;
    return (
      carbs: carbsG * MacroCalc.carbsKcalPerGram / total,
      fat: fatG * MacroCalc.fatKcalPerGram / total,
      protein: proteinG * MacroCalc.proteinKcalPerGram / total,
    );
  }
}
