import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/tdee_calc.dart';

import '../fixture/user_entity_fixtures.dart';

void main() {
  // Yesterday (not `day - 1`) so the date stays valid on the 1st of the
  // month; captured once so components can't straddle a midnight rollover.
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  test('IOM TDEE calculation for a male user', () {
    // Mock a male user
    UserEntity user = UserEntity(
      birthday: DateTime(yesterday.year - 25, yesterday.month, yesterday.day),
      heightCM: 180.0,
      weightKG: 80.0,
      gender: UserGenderEntity.male,
      goal: UserWeightGoalEntity.maintainWeight,
      pal: UserPALEntity.sedentary,
    );

    // Call the TDEE calculation method
    double userTdee = TDEECalc.getTDEEKcalIOM2005(user);

    // IOM 2005 p. 204:
    //   TEE = 864 – (9.72 × age [y]) + PA × (14.2 × weight [kg]
    //         + 503 × height [m])
    //
    // 864 - (9.72 * 25) + 1.0 * (14.2 * 80 + 503 * 1.80)
    //   = 621 + 2041.4 = 2662.4
    //
    // Sedentary is the one category this is invariant for: PA = 1.0, so the
    // #987 bracket bug did not move it. That is exactly why a sedentary-only
    // pin could never have caught the bug — see the non-sedentary pins below.
    int expectedTdee = 2662;

    expect(userTdee.toInt(), expectedTdee);
  });

  test('IOM TDEE calculation for a female user', () {
    // Mock a female user
    UserEntity user =
        UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight;

    // Call the TDEE calculation method
    double userTdee = TDEECalc.getTDEEKcalIOM2005(user);

    // IOM 2005 p. 204:
    //   TEE = 387 – (7.31 × age [y]) + PA × (10.9 × weight [kg]
    //         + 660.7 × height [m])
    //
    // 387 - (7.31 * 54) + 1.27 * (10.9 * 75 + 660.7 * 1.60)
    //   = -7.74 + 1.27 * 1874.62 = 2373.03
    //
    // Was pinned at 2087 before #987: the old code left the height term
    // outside the PA multiplier, costing this user 286 kcal/day.
    int expectedTdee = 2373;

    expect(userTdee.toInt(), expectedTdee);
  });

  group('IOM TDEE non-binary calculations', () {
    UserEntity baseUser({
      required UserGenderEntity gender,
      CaloriesProfileEntity? profile,
    }) {
      return UserEntity(
        birthday: DateTime(yesterday.year - 25, yesterday.month, yesterday.day),
        heightCM: 180.0,
        weightKG: 80.0,
        gender: gender,
        goal: UserWeightGoalEntity.maintainWeight,
        pal: UserPALEntity.sedentary,
        caloriesProfile: profile,
      );
    }

    test('non-binary defaults to the mean of male and female outputs', () {
      final maleTdee = TDEECalc.getTDEEKcalIOM2005(
        baseUser(gender: UserGenderEntity.male),
      );
      final femaleTdee = TDEECalc.getTDEEKcalIOM2005(
        baseUser(gender: UserGenderEntity.female),
      );
      final nonBinaryDefault = TDEECalc.getTDEEKcalIOM2005(
        baseUser(gender: UserGenderEntity.nonBinary),
      );

      expect(nonBinaryDefault, closeTo((maleTdee + femaleTdee) / 2, 0.001));
    });

    test('non-binary with averaged profile equals the default', () {
      final averaged = TDEECalc.getTDEEKcalIOM2005(
        baseUser(
          gender: UserGenderEntity.nonBinary,
          profile: CaloriesProfileEntity.averaged,
        ),
      );
      final defaulted = TDEECalc.getTDEEKcalIOM2005(
        baseUser(gender: UserGenderEntity.nonBinary),
      );
      expect(averaged, closeTo(defaulted, 0.001));
    });

    test('non-binary with estrogen-typical profile matches female formula', () {
      final estrogen = TDEECalc.getTDEEKcalIOM2005(
        baseUser(
          gender: UserGenderEntity.nonBinary,
          profile: CaloriesProfileEntity.estrogenTypical,
        ),
      );
      final female = TDEECalc.getTDEEKcalIOM2005(
        baseUser(gender: UserGenderEntity.female),
      );
      expect(estrogen, closeTo(female, 0.001));
    });

    test(
      'non-binary with testosterone-typical profile matches male formula',
      () {
        final testosterone = TDEECalc.getTDEEKcalIOM2005(
          baseUser(
            gender: UserGenderEntity.nonBinary,
            profile: CaloriesProfileEntity.testosteroneTypical,
          ),
        );
        final male = TDEECalc.getTDEEKcalIOM2005(
          baseUser(gender: UserGenderEntity.male),
        );
        expect(testosterone, closeTo(male, 0.001));
      },
    );
  });

  group('IOM TDEE non-binary at non-sedentary PALs (PA gender regression)', () {
    // Regression for the PA-gender bug: getPAValueFromPALValue used to read
    // userEntity.gender directly, so for a non-binary user the male half of
    // the averaged TDEE was computed with the female PA constant. The fix
    // routes each half through getPAValueForFormula with an explicit flag,
    // so the male half uses 1.12 / 1.54 and the female half uses 1.14 / 1.45
    // regardless of the user's stored gender enum.
    UserEntity buildUser(
      UserPALEntity pal, {
      CaloriesProfileEntity? profile,
      UserGenderEntity? gender,
    }) {
      return UserEntity(
        birthday: DateTime(yesterday.year - 25, yesterday.month, yesterday.day),
        heightCM: 180.0,
        weightKG: 80.0,
        gender: gender ?? UserGenderEntity.nonBinary,
        goal: UserWeightGoalEntity.maintainWeight,
        pal: pal,
        caloriesProfile: profile,
      );
    }

    test('lowActive averaged equals (binary male + binary female) / 2', () {
      final maleTdee = TDEECalc.getTDEEKcalIOM2005(
        buildUser(UserPALEntity.lowActive, gender: UserGenderEntity.male),
      );
      final femaleTdee = TDEECalc.getTDEEKcalIOM2005(
        buildUser(UserPALEntity.lowActive, gender: UserGenderEntity.female),
      );
      final averaged = TDEECalc.getTDEEKcalIOM2005(
        buildUser(
          UserPALEntity.lowActive,
          profile: CaloriesProfileEntity.averaged,
        ),
      );
      expect(averaged, closeTo((maleTdee + femaleTdee) / 2, 0.001));
    });

    test('veryActive averaged equals (binary male + binary female) / 2', () {
      final maleTdee = TDEECalc.getTDEEKcalIOM2005(
        buildUser(UserPALEntity.veryActive, gender: UserGenderEntity.male),
      );
      final femaleTdee = TDEECalc.getTDEEKcalIOM2005(
        buildUser(UserPALEntity.veryActive, gender: UserGenderEntity.female),
      );
      final averaged = TDEECalc.getTDEEKcalIOM2005(
        buildUser(
          UserPALEntity.veryActive,
          profile: CaloriesProfileEntity.averaged,
        ),
      );
      expect(averaged, closeTo((maleTdee + femaleTdee) / 2, 0.001));
    });

    test('lowActive averaged uses both PA constants — '
        'numerical pin (would fail with shared female PA = 1.14)', () {
      // Hand-computed expected for 80 kg / 180 cm / age 25 / lowActive (PAL 1.5):
      //   male half  = 864 - 9.72*25 + 1.12*(14.2*80 + 503*1.80)
      //              = 621 + 1.12*2041.4
      //              = 2907.37
      //   female half= 387 - 7.31*25 + 1.14*(10.9*80 + 660.7*1.80)
      //              = 204.25 + 1.14*2061.26
      //              = 2554.09
      //   averaged   = (2907.37 + 2554.09) / 2 ≈ 2730.73
      // The PA-gender bug this test was written for used PA=1.14 in the male
      // half too:
      //   buggy male = 621 + 1.14*2041.4 = 2948.20
      //   buggy avg  = (2948.20 + 2554.09) / 2 ≈ 2751.14
      // 20 kcal/day delta — small but always upward and systematic.
      final averaged = TDEECalc.getTDEEKcalIOM2005(
        buildUser(
          UserPALEntity.lowActive,
          profile: CaloriesProfileEntity.averaged,
        ),
      );
      expect(averaged, closeTo(2730.73, 0.5));
    });

    test('estrogenTypical at lowActive uses female PA (1.14)', () {
      final estrogen = TDEECalc.getTDEEKcalIOM2005(
        buildUser(
          UserPALEntity.lowActive,
          profile: CaloriesProfileEntity.estrogenTypical,
        ),
      );
      // 387 - 7.31*25 + 1.14*(10.9*80 + 660.7*1.80) ≈ 2554.09
      expect(estrogen, closeTo(2554.09, 0.5));
    });

    test('testosteroneTypical at veryActive uses male PA (1.54)', () {
      final testosterone = TDEECalc.getTDEEKcalIOM2005(
        buildUser(
          UserPALEntity.veryActive,
          profile: CaloriesProfileEntity.testosteroneTypical,
        ),
      );
      // 864 - 9.72*25 + 1.54*(14.2*80 + 503*1.80)
      //   = 621 + 1.54*2041.4 = 3764.76
      expect(testosterone, closeTo(3764.76, 0.5));
    });
  });

  group('Real-user kcal goal must differ from the old dummy fallback', () {
    // Regression for the onboarding race: when getUserData() returned the
    // hardcoded 80 kg / 180 cm / male / age 26 / active / maintain dummy,
    // the home screen showed ≈ 2959 kcal regardless of who the user was.
    // For a generic sedentary female with a lose-weight goal, the budget
    // must land far below that — otherwise we have regressed back to
    // pulling the dummy.
    test('female / sedentary / lose-weight produces a budget well below the '
        'old male / active / maintain dummy', () {
      final user = UserEntity(
        birthday: DateTime(yesterday.year - 35, yesterday.month, yesterday.day),
        heightCM: 165.0,
        weightKG: 70.0,
        gender: UserGenderEntity.female,
        goal: UserWeightGoalEntity.loseWeight,
        pal: UserPALEntity.sedentary,
      );

      final totalGoal = CalorieGoalCalc.getTotalKcalGoal(user, 0);
      // TEE = 387 - 7.31*35 + 1.0*(10.9*70 + 660.7*1.65)
      //     = 131.15 + 1853.155 ≈ 1984.3
      // Total goal = 1984.3 - 500 ≈ 1484.3 — well below the dummy's 2959.
      expect(totalGoal, lessThan(1700));
      expect(totalGoal, greaterThan(1300));
    });
  });
}
