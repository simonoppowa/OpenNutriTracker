import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';

enum UserWeightGoalEntity {
  loseWeight,
  maintainWeight,
  gainWeight;

  factory UserWeightGoalEntity.fromUserWeightGoalDBO(
      UserWeightGoalDBO weightGoalDBO) {
    UserWeightGoalEntity weightGoalEntity;
    switch (weightGoalDBO) {
      case UserWeightGoalDBO.gainWeight:
        weightGoalEntity = UserWeightGoalEntity.gainWeight;
        break;
      case UserWeightGoalDBO.maintainWeight:
        weightGoalEntity = UserWeightGoalEntity.maintainWeight;
        break;
      case UserWeightGoalDBO.loseWeight:
        weightGoalEntity = UserWeightGoalEntity.loseWeight;
        break;
    }
    return weightGoalEntity;
  }
}
