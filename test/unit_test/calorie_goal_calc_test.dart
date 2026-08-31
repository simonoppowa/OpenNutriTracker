import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
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

        double resultCalorieGoal = CalorieGoalCalc.getTotalKcalGoal(
          user,
          200.0,
        );

        // TDEE: 2662, Activities: 200, Adjustment: + 0
        // 2662 + 200 + 0 = 2862
        int expectedKcal = 2862;

        expect(resultCalorieGoal.toInt(), expectedKcal);
      },
    );

    test(
      'Total Kcal Goal calculation for a middle aged sedentary female wanting to maintain weight',
      () {
        final user = middleAgedActiveFemaleWantingToLoseWeight;

        double resultCalorieGoal = CalorieGoalCalc.getTotalKcalGoal(
          user,
          550.0,
        );

        // TDEE: 2373, Activities: 550, Adjustment: -500
        // 2373 + 550 - 500 = 2423
        int expectedKcal = 2423;

        expect(resultCalorieGoal.toInt(), expectedKcal);
      },
    );

    test('user kcal adjustment is added on top of goal adjustment', () {
      final user = youngSedentaryMaleWantingToMaintainWeight;

      final result = CalorieGoalCalc.getTotalKcalGoal(
        user,
        0,
        kcalUserAdjustment: 250,
      );
      final baseline = CalorieGoalCalc.getTotalKcalGoal(user, 0);

      expect(result, equals(baseline + 250));
    });

    test('negative user kcal adjustment subtracts from total', () {
      final user = youngSedentaryMaleWantingToMaintainWeight;

      final result = CalorieGoalCalc.getTotalKcalGoal(
        user,
        0,
        kcalUserAdjustment: -300,
      );
      final baseline = CalorieGoalCalc.getTotalKcalGoal(user, 0);

      expect(result, equals(baseline - 300));
    });

    test(
        'weekly weight goal in kg overrides the lose/gain default adjustment',
        () {
      // -0.5 kg/week → -550 kcal/day (vs -500 default for loseWeight)
      final base = UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight;
      final user = UserEntity(
        birthday: base.birthday,
        heightCM: base.heightCM,
        weightKG: base.weightKG,
        gender: base.gender,
        goal: base.goal,
        pal: base.pal,
        weeklyWeightGoalKg: -0.5,
      );

      final adjustment = CalorieGoalCalc.getKcalGoalAdjustment(
        user.goal,
        weeklyWeightGoalKg: user.weeklyWeightGoalKg,
      );
      expect(adjustment, equals(-550));
    });

    test('positive weekly weight goal yields a positive adjustment', () {
      final adjustment = CalorieGoalCalc.getKcalGoalAdjustment(
        UserWeightGoalEntity.gainWeight,
        weeklyWeightGoalKg: 0.5,
      );
      expect(adjustment, equals(550));
    });

    test('default lose/maintain/gain adjustments are -500/0/+500', () {
      expect(
        CalorieGoalCalc.getKcalGoalAdjustment(UserWeightGoalEntity.loseWeight),
        equals(-500),
      );
      expect(
        CalorieGoalCalc.getKcalGoalAdjustment(
            UserWeightGoalEntity.maintainWeight),
        equals(0),
      );
      expect(
        CalorieGoalCalc.getKcalGoalAdjustment(UserWeightGoalEntity.gainWeight),
        equals(500),
      );
    });

    test('getDailyKcalLeft is goal minus intake', () {
      expect(CalorieGoalCalc.getDailyKcalLeft(2000, 800), equals(1200));
      expect(CalorieGoalCalc.getDailyKcalLeft(2000, 2200), equals(-200));
    });
  });
}
