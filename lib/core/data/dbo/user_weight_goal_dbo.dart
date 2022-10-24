import 'package:hive/hive.dart';

part 'user_weight_goal_dbo.g.dart';

@HiveType(typeId: 7)
enum UserWeightGoalDBO {
  @HiveField(0)
  loseWeight,
  @HiveField(1)
  maintainWeight,
  @HiveField(2)
  gainWeight;
}
