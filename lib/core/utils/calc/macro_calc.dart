class MacroCalc {
  /// Information provided by
  /// 'OBESITY: PREVENTING AND MANAGING
  /// THE GLOBAL EPIDEMIC' by WHO page 104
  /// ISBN 92 4 120894 5
  /// ISSN 0512-3054
  static const _carbsKcalPerGram = 4.0;
  static const _fatKcalPerGram = 9.0;
  static const _proteinKcalPerGram = 4.0;

  static const _defaultCarbsPercentageGoal = 0.6;
  static const _defaultFatsPercentageGoal = 0.25;
  static const _defaultProteinsPercentageGoal = 0.15;

  /// Calculate the total carbs goal based on the total calorie goal
  /// Uses the default percentage if the user has not set a goal
  static double getTotalCarbsGoal(
          double totalCalorieGoal, {double? userCarbsGoal}) =>
      (totalCalorieGoal * (userCarbsGoal ?? _defaultCarbsPercentageGoal)) /
      _carbsKcalPerGram;

  /// Calculate the total fats goal based on the total calorie goal
  /// Uses the default percentage if the user has not set a goal
  static double getTotalFatsGoal(
          double totalCalorieGoal, {double? userFatsGoal}) =>
      (totalCalorieGoal * (userFatsGoal ?? _defaultFatsPercentageGoal)) /
      _fatKcalPerGram;

  /// Calculate the total proteins goal based on the total calorie goal
  /// Uses the default percentage if the user has not set a goal
  static double getTotalProteinsGoal(
          double totalCalorieGoal, {double? userProteinsGoal}) =>
      (totalCalorieGoal *
          (userProteinsGoal ?? _defaultProteinsPercentageGoal)) /
      _proteinKcalPerGram;
}
