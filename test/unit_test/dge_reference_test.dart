import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/dri_reference.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';

UserEntity _user(
  int age,
  UserGenderEntity gender, {
  CaloriesProfileEntity? caloriesProfile,
}) {
  final now = DateTime.now();
  return UserEntity(
    birthday: DateTime(now.year - age, now.month, now.day - 1),
    heightCM: 170,
    weightKG: 70,
    gender: gender,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.sedentary,
    caloriesProfile: caloriesProfile,
  );
}

double? _dge(String key, UserEntity? user) =>
    getDgeReferenceFor(nutrient: key, user: user)?.amount;

void main() {
  const male = UserGenderEntity.male;
  const female = UserGenderEntity.female;

  test('values that depend on sex', () {
    expect(_dge(NutrientPanelKeys.magnesium, _user(30, male)), 350);
    expect(_dge(NutrientPanelKeys.magnesium, _user(30, female)), 300);
    expect(_dge(NutrientPanelKeys.vitaminC, _user(30, male)), 110);
    expect(_dge(NutrientPanelKeys.vitaminC, _user(30, female)), 95);
    expect(_dge(NutrientPanelKeys.zinc, _user(30, male)), 14);
    expect(_dge(NutrientPanelKeys.zinc, _user(30, female)), 8);
    expect(_dge(NutrientPanelKeys.vitaminB6, _user(30, female)), 1.4);
  });

  test('values that depend on age', () {
    expect(_dge(NutrientPanelKeys.niacin, _user(20, male)), 16);
    expect(_dge(NutrientPanelKeys.niacin, _user(40, male)), 15);
    expect(_dge(NutrientPanelKeys.niacin, _user(55, female)), 11);
    expect(_dge(NutrientPanelKeys.niacin, _user(70, male)), 14);
    expect(_dge(NutrientPanelKeys.vitaminA, _user(64, male)), 850);
    expect(_dge(NutrientPanelKeys.vitaminA, _user(65, male)), 800);
    expect(_dge(NutrientPanelKeys.iron, _user(50, female)), 16);
    expect(_dge(NutrientPanelKeys.iron, _user(51, female)), 14);
    expect(_dge(NutrientPanelKeys.iron, _user(70, male)), 11);
  });

  test('values the same for every adult', () {
    final user = _user(45, female);
    expect(_dge(NutrientPanelKeys.vitaminB12, user), 4);
    expect(_dge(NutrientPanelKeys.vitaminD, user), 20);
    expect(_dge(NutrientPanelKeys.potassium, user), 4000);
    expect(_dge(NutrientPanelKeys.calcium, user), 1000);
    expect(_dge(NutrientPanelKeys.phosphorus, user), 550);
    expect(_dge(NutrientPanelKeys.fiber, user), 30);
    expect(_dge(NutrientPanelKeys.sodium, user), 2400);
  });

  test('non-binary users are routed like the IOM lookup', () {
    expect(
      _dge(
        NutrientPanelKeys.magnesium,
        _user(
          30,
          UserGenderEntity.nonBinary,
          caloriesProfile: CaloriesProfileEntity.testosteroneTypical,
        ),
      ),
      350,
    );
    expect(
      _dge(NutrientPanelKeys.magnesium, _user(30, UserGenderEntity.nonBinary)),
      325,
    );
  });

  test('without a user the adult midpoint', () {
    expect(_dge(NutrientPanelKeys.vitaminC, null), 102.5);
  });

  test('nutrients without a DGE value give null', () {
    for (final key in [
      NutrientPanelKeys.saturatedFat,
      NutrientPanelKeys.sugar,
      NutrientPanelKeys.cholesterol,
      NutrientPanelKeys.transFat,
      NutrientPanelKeys.monounsaturatedFat,
      NutrientPanelKeys.energy,
    ]) {
      expect(_dge(key, _user(30, male)), isNull, reason: key);
    }
  });

  test('units match the panel', () {
    final user = _user(30, male);
    expect(
      getDgeReferenceFor(
        nutrient: NutrientPanelKeys.vitaminA,
        user: user,
      )!.unit,
      'µg',
    );
    expect(
      getDgeReferenceFor(nutrient: NutrientPanelKeys.iron, user: user)!.unit,
      'mg',
    );
  });

  test('protein follows body weight, more from 65', () {
    expect(_dge(NutrientPanelKeys.protein, _user(40, male)), closeTo(56, 1e-9));
    expect(_dge(NutrientPanelKeys.protein, _user(70, female)), 70);
    expect(_dge(NutrientPanelKeys.protein, null), 52.5);
  });
}
