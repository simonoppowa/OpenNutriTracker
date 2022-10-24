import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';

class UserEntity {
  DateTime birthday;
  double heightCM;
  double weightKG;
  UserGenderEntity gender;
  UserWeightGoalEntity goal;
  UserPALEntity pal;

  UserEntity(
      {required this.birthday,
      required this.heightCM,
      required this.weightKG,
      required this.gender,
      required this.goal,
      required this.pal});
}
