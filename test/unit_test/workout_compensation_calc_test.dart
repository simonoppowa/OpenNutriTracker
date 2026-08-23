import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/workout_compensation_calc.dart';

/// A user whose BMI is exactly [bmi] — 200 cm makes height² a clean 4 m², so
/// the weight the tests read is the BMI times four.
UserEntity _user({
  required UserGenderEntity gender,
  double bmi = 25,
  double heightCM = 200,
  CaloriesProfileEntity? caloriesProfile,
}) => UserEntity(
  birthday: DateTime(1990, 1, 1),
  heightCM: heightCM,
  weightKG: heightCM <= 0 ? 80 : bmi * (heightCM / 100) * (heightCM / 100),
  gender: gender,
  goal: UserWeightGoalEntity.maintainWeight,
  pal: UserPALEntity.sedentary,
  caloriesProfile: caloriesProfile,
);

void main() {
  group('WorkoutCompensationCalc anchors', () {
    test('a body fat reading at the 10th percentile credits 70%', () {
      // Male 10th percentile is 19.5% fat, so compensation is the lean
      // anchor: 1 - 29.7/100 = 0.703, rounded to 0.70.
      final result = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: WorkoutCompensationCalc.maleBodyFatP10,
        user: _user(gender: UserGenderEntity.male),
      );

      expect(result, equals(0.70));
    });

    test('a body fat reading at the 90th percentile credits 54%', () {
      // 1 - 45.7/100 = 0.543, rounded to 0.54.
      final result = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: WorkoutCompensationCalc.maleBodyFatP90,
        user: _user(gender: UserGenderEntity.male),
      );

      expect(result, equals(0.54));
    });

    test('the female anchors land on the same two multipliers', () {
      final lean = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: WorkoutCompensationCalc.femaleBodyFatP10,
        user: _user(gender: UserGenderEntity.female),
      );
      final heavy = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: WorkoutCompensationCalc.femaleBodyFatP90,
        user: _user(gender: UserGenderEntity.female),
      );

      expect(lean, equals(0.70));
      expect(heavy, equals(0.54));
    });

    test(
      'the same body fat reading is read against the right distribution',
      () {
        // 30.5% fat is the female 10th percentile but sits well up the male
        // distribution: 10 + (30.5-19.5)/(35.9-19.5)*80 = 63.66th percentile,
        // so compensation is 29.7 + 16*(53.66/80) = 40.4% and the credit 0.60.
        final asFemale = WorkoutCompensationCalc.suggestedMultiplier(
          bodyFatPercent: 30.5,
          user: _user(gender: UserGenderEntity.female),
        );
        final asMale = WorkoutCompensationCalc.suggestedMultiplier(
          bodyFatPercent: 30.5,
          user: _user(gender: UserGenderEntity.male),
        );

        expect(asFemale, equals(0.70));
        expect(asMale, equals(0.60));
      },
    );

    test('a non-binary user reads against their calorie-reference profile', () {
      final testosteroneTypical = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: WorkoutCompensationCalc.maleBodyFatP10,
        user: _user(
          gender: UserGenderEntity.nonBinary,
          caloriesProfile: CaloriesProfileEntity.testosteroneTypical,
        ),
      );
      final estrogenTypical = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: WorkoutCompensationCalc.femaleBodyFatP10,
        user: _user(
          gender: UserGenderEntity.nonBinary,
          caloriesProfile: CaloriesProfileEntity.estrogenTypical,
        ),
      );
      // Averaged sits midway between the two distributions: the 10th
      // percentile anchor is (19.5 + 30.5) / 2 = 25.0% fat.
      final averaged = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: 25.0,
        user: _user(gender: UserGenderEntity.nonBinary),
      );

      expect(testosteroneTypical, equals(0.70));
      expect(estrogenTypical, equals(0.70));
      expect(averaged, equals(0.70));
    });
  });

  group('WorkoutCompensationCalc clamping', () {
    test('an extreme body fat reading cannot push past either anchor', () {
      final veryLean = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: 4,
        user: _user(gender: UserGenderEntity.male),
      );
      final veryHeavy = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: 65,
        user: _user(gender: UserGenderEntity.male),
      );

      expect(veryLean, equals(0.70));
      expect(veryHeavy, equals(0.54));
    });

    test('every result stays inside the configurable multiplier range', () {
      for (final bodyFat in [1.5, 10.0, 25.0, 45.0, 99.0]) {
        final result = WorkoutCompensationCalc.suggestedMultiplier(
          bodyFatPercent: bodyFat,
          user: _user(gender: UserGenderEntity.female),
        );

        expect(
          result,
          inInclusiveRange(
            ConfigEntity.minHealthWorkoutKcalMultiplier,
            ConfigEntity.maxHealthWorkoutKcalMultiplier,
          ),
        );
      }
    });
  });

  group('WorkoutCompensationCalc input ladder', () {
    test('BMI is used when there is no body fat reading', () {
      // BMI 20 is the 10th-percentile anchor, BMI 33 the 90th.
      final lean = WorkoutCompensationCalc.suggestedMultiplier(
        user: _user(gender: UserGenderEntity.male, bmi: 20),
      );
      final heavy = WorkoutCompensationCalc.suggestedMultiplier(
        user: _user(gender: UserGenderEntity.male, bmi: 33),
      );

      expect(lean, equals(0.70));
      expect(heavy, equals(0.54));
    });

    test('an impossible body fat reading falls through to BMI', () {
      final zero = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: 0,
        user: _user(gender: UserGenderEntity.male, bmi: 20),
      );
      final overHundred = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: 140,
        user: _user(gender: UserGenderEntity.male, bmi: 20),
      );

      expect(zero, equals(0.70));
      expect(overHundred, equals(0.70));
    });

    test('with neither input usable the sample mean is suggested', () {
      // 1 - 27.7/100 rounds to 0.72 — what a user we know nothing about gets.
      final result = WorkoutCompensationCalc.suggestedMultiplier(
        user: _user(gender: UserGenderEntity.male, heightCM: 0),
      );

      expect(result, equals(WorkoutCompensationCalc.fallbackMultiplier));
      expect(result, equals(0.72));
    });
  });
}
