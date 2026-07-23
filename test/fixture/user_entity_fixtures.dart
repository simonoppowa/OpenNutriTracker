import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';

class UserEntityFixtures {
  // Yesterday (not `day - 1`) so fixtures stay valid on the 1st of the
  // month; captured once so components can't straddle a midnight rollover.
  static final DateTime _yesterday = DateTime.now().subtract(
    const Duration(days: 1),
  );

  /// Mocked user entity
  /// 25 years, 180 cm, 80 kg, male, maintain weight, sedentary
  static final youngSedentaryMaleWantingToMaintainWeight = UserEntity(
    birthday: DateTime(_yesterday.year - 25, _yesterday.month, _yesterday.day),
    heightCM: 180.0,
    weightKG: 80.0,
    gender: UserGenderEntity.male,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.sedentary,
  );

  /// Mocked user entity
  /// 54 years, 160 cm, 75 kg, female, lose weight, active
  static final UserEntity middleAgedActiveFemaleWantingToLoseWeight =
      UserEntity(
        birthday: DateTime(
          _yesterday.year - 54,
          _yesterday.month,
          _yesterday.day,
        ),
        heightCM: 160.0,
        weightKG: 75.0,
        gender: UserGenderEntity.female,
        goal: UserWeightGoalEntity.loseWeight,
        pal: UserPALEntity.active,
      );

  /// Mocked user entity
  /// 76 years, 164 cm, 55 kg, male, gain weight, low active
  static final UserEntity elderlyLowActiveMaleWantingToGainWeight = UserEntity(
    birthday: DateTime(_yesterday.year - 76, _yesterday.month, _yesterday.day),
    heightCM: 164.0,
    weightKG: 55.0,
    gender: UserGenderEntity.male,
    goal: UserWeightGoalEntity.gainWeight,
    pal: UserPALEntity.lowActive,
  );

  /// Mocked user entity
  /// 19 years, 190 cm, 105 kg, female, lose weight, very active
  static final UserEntity youngVeryActiveOverweightFemaleWantingToLoseWeight =
      UserEntity(
        birthday: DateTime(
          _yesterday.year - 19,
          _yesterday.month,
          _yesterday.day,
        ),
        heightCM: 190.0,
        weightKG: 105.0,
        gender: UserGenderEntity.female,
        goal: UserWeightGoalEntity.loseWeight,
        pal: UserPALEntity.veryActive,
      );
}
