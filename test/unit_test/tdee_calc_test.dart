import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/tdee_calc.dart';

import '../fixture/user_entity_fixtures.dart';

void main() {
  test('IOM TDEE calculation for a male user', () {
    // Mock a male user
    UserEntity user = UserEntity(
        birthday: DateTime(DateTime.now().year - 25, DateTime.now().month,
            DateTime.now().day - 1),
        heightCM: 180.0,
        weightKG: 80.0,
        gender: UserGenderEntity.male,
        goal: UserWeightGoalEntity.maintainWeight,
        pal: UserPALEntity.sedentary);


    // Call the TDEE calculation method
    double userTdee = TDEECalc.getTDEEKcalIOM2005(user);

    // 864 – (9.72 × age [y]) + PA × (14.2 × weight [kg]
    // + 503 × height [m])

    // 864 - (9.72 * 25) + 1.0 *( 14,2 * 80) + 503 * 1.80 = 2662
    int expectedTdee = 2662;

    expect(userTdee.toInt(), expectedTdee);
  });

  test('IOM TDEE calculation for a female user', () {
    // Mock a female user
    UserEntity user = UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight;

    // Call the TDEE calculation method
    double userTdee = TDEECalc.getTDEEKcalIOM2005(user);

    // 387 – (7.31 × age [y]) + PA × (10.9 × weight [kg]
    // + 660.7 × height [m])

    // 387 - (7.31 * 54) + 1.27 * (10.9 * 75) + 660.7 * 1.60 = 2087
    int expectedTdee = 2087;

    expect(userTdee.toInt(), expectedTdee);
  });
}
