import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';

import '../fixture/user_entity_fixtures.dart';

void main() {
  group('Calorie Goal Calc Test', () {
    late UserEntity youngSedentaryMaleWantingToMaintainWeight;
    late UserEntity middleAgedActiveFemaleWantingToLoseWeight;

    setUp(() {
      youngSedentaryMaleWantingToMaintainWeight =
          UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
      middleAgedActiveFemaleWantingToLoseWeight =
          UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight;
    });

    test(
        'Total Kcal Goal calculation for a young sedentary male wanting to maintain weight',
        () {
      final user = youngSedentaryMaleWantingToMaintainWeight;

      double resultCalorieGoal = CalorieGoalCalc.getTotalKcalGoal(user, 200.0);

      // TDEE: 2662, Activities: 200, Adjustment: + 0
      // 2662 + 200 + 0 = 2862
      int expectedKcal = 2862;

      expect(resultCalorieGoal.toInt(), expectedKcal);
    });

    test(
        'Total Kcal Goal calculation for a middle aged sedentary female wanting to maintain weight',
        () {
      final user = middleAgedActiveFemaleWantingToLoseWeight;

      double resultCalorieGoal = CalorieGoalCalc.getTotalKcalGoal(user, 550.0);

      // TDEE: 2087, Activities: 550, Adjustment: -500
      // 2087 + 550 - 500 = 2137
      int expectedKcal = 2137;

      expect(resultCalorieGoal.toInt(), expectedKcal);
    });
  });
}
