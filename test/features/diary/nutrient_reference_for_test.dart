import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/dri_reference.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/settings/domain/nutrient_reference_setting.dart';

void main() {
  final woman = UserEntity(
    birthday: DateTime(1996, 5, 1),
    heightCM: 168,
    weightKG: 62,
    gender: UserGenderEntity.female,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.active,
  );

  double? amount(
    String key, {
    TrackedDayEntity? day,
    UserEntity? user,
    NutrientReferenceStandard standard = NutrientReferenceStandard.iom,
  }) => DailyNutrientPanel.referenceFor(
    key,
    trackedDay: day,
    user: user,
    standard: standard,
  ).amount;

  test('without a user the gender-neutral defaults apply', () {
    expect(amount(NutrientPanelKeys.iron), 14);
    expect(amount(NutrientPanelKeys.magnesium), 355);
    expect(amount(NutrientPanelKeys.saturatedFat), 20);
    expect(amount(NutrientPanelKeys.zinc), 9.5);
  });

  test('a user gets the IOM value for age and sex', () {
    expect(
      amount(NutrientPanelKeys.iron, user: woman),
      getReferenceFor(nutrient: NutrientPanelKeys.iron, user: woman)!.amount,
    );
  });

  test("the day's own goal comes first", () {
    final day = TrackedDayEntity(
      day: DateTime(2026, 10, 21),
      calorieGoal: 2000,
      caloriesTracked: 0,
      ironGoal: 20,
      extraNutrientGoals: const {NutrientPanelKeys.zinc: 12},
    );

    expect(amount(NutrientPanelKeys.iron, day: day, user: woman), 20);
    expect(amount(NutrientPanelKeys.zinc, day: day), 12);
  });

  test('with DGE the DGE value applies, IOM/FDA marked as fallback', () {
    final iron = DailyNutrientPanel.referenceFor(
      NutrientPanelKeys.iron,
      user: woman,
      standard: NutrientReferenceStandard.dge,
    );
    expect(
      iron.amount,
      getDgeReferenceFor(nutrient: NutrientPanelKeys.iron, user: woman)!.amount,
    );
    expect(iron.fallback, isFalse);

    final satFat = DailyNutrientPanel.referenceFor(
      NutrientPanelKeys.saturatedFat,
      user: woman,
      standard: NutrientReferenceStandard.dge,
    );
    expect(satFat.amount, 20);
    expect(satFat.fallback, isTrue);
  });

  test('a nutrient without any reference has none', () {
    expect(amount(NutrientPanelKeys.monounsaturatedFat), isNull);
  });
}
