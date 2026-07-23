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
