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

  static double getTotalCarbsGoal(double totalCalorieGoal) =>
      (totalCalorieGoal * _defaultCarbsPercentageGoal) / _carbsKcalPerGram;

  static double getTotalFatsGoal(double totalCalorieGoal) =>
      (totalCalorieGoal * _defaultFatsPercentageGoal) / _fatKcalPerGram;

  static double getTotalProteinsGoal(double totalCalorieGoal) =>
      (totalCalorieGoal * _defaultProteinsPercentageGoal) / _proteinKcalPerGram;
}
