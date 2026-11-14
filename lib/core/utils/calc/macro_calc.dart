class MacroCalc {
  /// Information provided by
  /// 'OBESITY: PREVENTING AND MANAGING
  /// THE GLOBAL EPIDEMIC' by WHO page 104
  /// ISBN 92 4 120894 5
  /// ISSN 0512-3054
  ///
  /// Public (rather than private) so the calorie-goal transparency screen
  /// can display the exact densities and default split it computes with.
  static const carbsKcalPerGram = 4.0;
  static const fatKcalPerGram = 9.0;
  static const proteinKcalPerGram = 4.0;

  static const defaultCarbsPercentageGoal = 0.6;
  static const defaultFatsPercentageGoal = 0.25;
  static const defaultProteinsPercentageGoal = 0.15;

  /// Calculate the total carbs goal based on the total calorie goal
  /// Uses the default percentage if the user has not set a goal
  static double getTotalCarbsGoal(
    double totalCalorieGoal, {
    double? userCarbsGoal,
  }) =>
      (totalCalorieGoal * (userCarbsGoal ?? defaultCarbsPercentageGoal)) /
      carbsKcalPerGram;

  /// Calculate the total fats goal based on the total calorie goal
  /// Uses the default percentage if the user has not set a goal
  static double getTotalFatsGoal(
    double totalCalorieGoal, {
    double? userFatsGoal,
  }) =>
      (totalCalorieGoal * (userFatsGoal ?? defaultFatsPercentageGoal)) /
      fatKcalPerGram;

  /// Calculate the total proteins goal based on the total calorie goal
  /// Uses the default percentage if the user has not set a goal
  static double getTotalProteinsGoal(
    double totalCalorieGoal, {
    double? userProteinsGoal,
  }) =>
      (totalCalorieGoal *
          (userProteinsGoal ?? defaultProteinsPercentageGoal)) /
      proteinKcalPerGram;
}

/// Daily carbs, protein and fat in grams (#642).
typedef MacroGrams = ({double carbs, double protein, double fat});

/// Absolute macro goals (#642): the user sets each macro in grams instead
/// of as a share of the calorie goal.
///
/// Gram goals are exact numbers, often a coach's plan or a keto limit, so
/// they do not follow the calorie goal: not its changes, and not the
/// energy a logged activity adds to it.
class MacroGramGoals {
  /// Per macro. 0 is allowed (a carb-free day); the goal rings treat a
  /// zero goal as nothing to fill.
  static const double minGrams = 0;
  static const double maxGrams = 1000;

  static bool isValidGrams(double? grams) =>
      grams != null && grams.isFinite && grams >= minGrams && grams <= maxGrams;

  /// The gram goals in effect, or null when the percentage split applies.
  ///
  /// Null unless [inGrams] is set and all three values are valid and not
  /// all zero, so a corrupt stored value falls back to the split instead of
  /// a goal of NaN or 0 for every macro.
  static MacroGrams? effective({
    required bool? inGrams,
    required double? carbs,
    required double? protein,
    required double? fat,
  }) {
    if (inGrams != true) return null;
    if (!isValidGrams(carbs) || !isValidGrams(protein) || !isValidGrams(fat)) {
      return null;
    }
    if (carbs! + protein! + fat! <= 0) return null;
    return (carbs: carbs, protein: protein, fat: fat);
  }

  /// The energy in [grams], with the densities the split uses.
  static double kcalOf(MacroGrams grams) =>
      grams.carbs * MacroCalc.carbsKcalPerGram +
      grams.protein * MacroCalc.proteinKcalPerGram +
      grams.fat * MacroCalc.fatKcalPerGram;

  /// The split's goals for [kcalGoal] in whole grams: what the gram fields
  /// start at, so switching to grams first shows numbers the user knows.
  static MacroGrams fromSplit(
    double kcalGoal, {
    double? carbsPct,
    double? proteinPct,
    double? fatPct,
  }) {
    double whole(double g) =>
        g.isFinite ? g.round().clamp(minGrams, maxGrams).toDouble() : 0;
    return (
      carbs: whole(
        MacroCalc.getTotalCarbsGoal(kcalGoal, userCarbsGoal: carbsPct),
      ),
      protein: whole(
        MacroCalc.getTotalProteinsGoal(kcalGoal, userProteinsGoal: proteinPct),
      ),
      fat: whole(MacroCalc.getTotalFatsGoal(kcalGoal, userFatsGoal: fatPct)),
    );
  }

  /// What logging an activity that burned [burnedKcal] adds to a day's
  /// macro goals: the default split of the burned energy, or nothing while
  /// gram goals are in effect (a keto carb limit must not grow with a run).
  /// Negative [burnedKcal] gives the amounts to take off again.
  static MacroGrams activityShare(
    double burnedKcal, {
    required bool gramGoals,
  }) => gramGoals
      ? (carbs: 0, protein: 0, fat: 0)
      : (
          carbs: MacroCalc.getTotalCarbsGoal(burnedKcal),
          protein: MacroCalc.getTotalProteinsGoal(burnedKcal),
          fat: MacroCalc.getTotalFatsGoal(burnedKcal),
        );
}
