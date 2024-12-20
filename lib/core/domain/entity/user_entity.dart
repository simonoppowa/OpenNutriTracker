import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
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
  double carbsPercentageGoal;
  double fatsPercentageGoal;
  double proteinsPercentageGoal;

  UserEntity(
      {required this.birthday,
      required this.heightCM,
      required this.weightKG,
      required this.gender,
      required this.goal,
      required this.pal,
      required this.carbsPercentageGoal,
      required this.fatsPercentageGoal,
      required this.proteinsPercentageGoal});

  factory UserEntity.fromUserDBO(UserDBO userDBO) {
    return UserEntity(
        birthday: userDBO.birthday,
        heightCM: userDBO.heightCM,
        weightKG: userDBO.weightKG,
        gender: UserGenderEntity.fromUserGenderDBO(userDBO.gender),
        goal: UserWeightGoalEntity.fromUserWeightGoalDBO(userDBO.goal),
        pal: UserPALEntity.fromUserPALDBO(userDBO.pal),
        carbsPercentageGoal: userDBO.carbsPercentageGoal,
        fatsPercentageGoal: userDBO.fatsPercentageGoal,
        proteinsPercentageGoal: userDBO.proteinsPercentageGoal);
  }

  int get age => DateTime.now().difference(birthday).inDays~/365;
}
