import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';

part 'user_dbo.g.dart';

@HiveType(typeId: 5)
class UserDBO extends HiveObject {
  @HiveField(0)
  DateTime birthday;
  @HiveField(1)
  double heightCM;
  @HiveField(2)
  double weightKG;
  @HiveField(3)
  UserGenderDBO gender;
  @HiveField(4)
  UserWeightGoalDBO goal;
  @HiveField(5)
  UserPALDBO pal;

  UserDBO(
      {required this.birthday,
      required this.heightCM,
      required this.weightKG,
      required this.gender,
      required this.goal,
      required this.pal});

  factory UserDBO.fromUserEntity(UserEntity entity) {
    return UserDBO(
        birthday: entity.birthday,
        heightCM: entity.heightCM,
        weightKG: entity.weightKG,
        gender: UserGenderDBO.fromUserGenderEntity(entity.gender),
        goal: UserWeightGoalDBO.fromUserWeightGoalEntity(entity.goal),
        pal: UserPALDBO.fromUserPALEntity(entity.pal));
  }
}
