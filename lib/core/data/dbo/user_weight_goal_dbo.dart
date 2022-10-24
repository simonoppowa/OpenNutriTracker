import 'package:hive/hive.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';

part 'user_weight_goal_dbo.g.dart';

@HiveType(typeId: 7)
enum UserWeightGoalDBO {
  @HiveField(0)
  loseWeight,
  @HiveField(1)
  maintainWeight,
  @HiveField(2)
  gainWeight;

  factory UserWeightGoalDBO.fromUserWeightGoalEntity(
      UserWeightGoalEntity goalEntity) {
    UserWeightGoalDBO weightGoalDBO;
    switch (goalEntity) {
      case UserWeightGoalEntity.loseWeight:
        weightGoalDBO = UserWeightGoalDBO.loseWeight;
        break;
      case UserWeightGoalEntity.maintainWeight:
        weightGoalDBO = UserWeightGoalDBO.maintainWeight;
        break;
      case UserWeightGoalEntity.gainWeight:
        weightGoalDBO = UserWeightGoalDBO.gainWeight;
        break;
    }
    return weightGoalDBO;
  }
}
