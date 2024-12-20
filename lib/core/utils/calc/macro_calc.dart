import 'package:opennutritracker/core/domain/entity/user_entity.dart';

class MacroCalc {
  /// Information provided by
  /// 'OBESITY: PREVENTING AND MANAGING
  /// THE GLOBAL EPIDEMIC' by WHO page 104
  /// ISBN 92 4 120894 5
  /// ISSN 0512-3054
  static const _carbsKcalPerGram = 4.0;
  static const _fatKcalPerGram = 9.0;
  static const _proteinKcalPerGram = 4.0;

  static double getTotalCarbsGoal(UserEntity userEntity, double totalCalorieGoal) =>
      (totalCalorieGoal * userEntity.carbsPercentageGoal) / _carbsKcalPerGram;

  static double getTotalFatsGoal(UserEntity userEntity, double totalCalorieGoal) =>
      (totalCalorieGoal * userEntity.fatsPercentageGoal) / _fatKcalPerGram;

  static double getTotalProteinsGoal(UserEntity userEntity, double totalCalorieGoal) =>
      (totalCalorieGoal * userEntity.proteinsPercentageGoal) / _proteinKcalPerGram;
}
