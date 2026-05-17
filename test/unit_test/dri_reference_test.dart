import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/dri_reference.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';

/// #245: the IOM Dietary Reference Intakes table should return the
/// canonical adult RDA / AI / UL for a known life-stage, and should
/// return null for nutrients the IOM does not publish a reference for
/// (saturated fat, added sugar). The widget treats null as "no DRI
/// bar to show" — a guard against silently substituting a guess.
void main() {
  UserEntity user({
    required int age,
    required UserGenderEntity gender,
    CaloriesProfileEntity? caloriesProfile,
  }) {
    final now = DateTime(2026, 5, 16);
    return UserEntity(
      birthday: DateTime(now.year - age, now.month, now.day),
      heightCM: 170,
      weightKG: 70,
      gender: gender,
      goal: UserWeightGoalEntity.maintainWeight,
      pal: UserPALEntity.sedentary,
      caloriesProfile: caloriesProfile,
    );
  }

  group('getReferenceFor', () {
    test('male 25 — calcium matches the IOM 1000 mg RDA', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.calcium,
        user: user(age: 25, gender: UserGenderEntity.male),
      );
      expect(ref, isNotNull);
      expect(ref!.amount, 1000);
      expect(ref.unit, 'mg');
      expect(ref.basis, 'RDA');
    });

    test('male 25 — iron is 8 mg (IOM RDA for adult men)', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.iron,
        user: user(age: 25, gender: UserGenderEntity.male),
      );
      expect(ref!.amount, 8);
    });

    test('female 25 — iron is 18 mg (IOM RDA for menstruating women)', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.iron,
        user: user(age: 25, gender: UserGenderEntity.female),
      );
      expect(ref!.amount, 18);
    });

    test('female 60 — iron drops to 8 mg post-menopause', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.iron,
        user: user(age: 60, gender: UserGenderEntity.female),
      );
      expect(ref!.amount, 8);
    });

    test('male 75 — vitamin D climbs to 20 µg in the 71+ band', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.vitaminD,
        user: user(age: 75, gender: UserGenderEntity.male),
      );
      expect(ref!.amount, 20);
      expect(ref.unit, 'µg');
    });

    test('nutrient with no IOM RDA returns null (saturated fat)', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.saturatedFat,
        user: user(age: 25, gender: UserGenderEntity.male),
      );
      expect(ref, isNull);
    });

    test('nutrient with no IOM RDA returns null (sugar)', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.sugar,
        user: user(age: 25, gender: UserGenderEntity.female),
      );
      expect(ref, isNull);
    });

    test('non-binary estrogen-typical at 25 — iron uses the female row', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.iron,
        user: user(
          age: 25,
          gender: UserGenderEntity.nonBinary,
          caloriesProfile: CaloriesProfileEntity.estrogenTypical,
        ),
      );
      expect(ref!.amount, 18);
    });

    test('non-binary testosterone-typical at 25 — iron uses the male row', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.iron,
        user: user(
          age: 25,
          gender: UserGenderEntity.nonBinary,
          caloriesProfile: CaloriesProfileEntity.testosteroneTypical,
        ),
      );
      expect(ref!.amount, 8);
    });

    test('non-binary averaged at 25 — iron sits at the female / male midpoint', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.iron,
        user: user(
          age: 25,
          gender: UserGenderEntity.nonBinary,
          caloriesProfile: CaloriesProfileEntity.averaged,
        ),
      );
      // female 18 mg + male 8 mg averaged = 13 mg.
      expect(ref!.amount, 13);
    });

    test('non-binary with no profile picked defaults to averaged', () {
      final ref = getReferenceFor(
        nutrient: NutrientPanelKeys.magnesium,
        user: user(age: 25, gender: UserGenderEntity.nonBinary),
      );
      // female 310 mg + male 400 mg averaged = 355 mg.
      expect(ref!.amount, 355);
    });
  });
}
