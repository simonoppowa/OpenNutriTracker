import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/calc/dri_reference.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';
import 'package:opennutritracker/features/add_meal/presentation/nutrient_field_label.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The groups the daily nutrient panel and its settings list the
/// nutrients in (#47).
enum NutrientPanelGroup {
  macros,
  fattyAcids,
  minerals,
  vitamins;

  String label(S s) => switch (this) {
    macros => s.nutrientGroupMacrosLabel,
    fattyAcids => s.nutrientGroupFattyAcidsLabel,
    minerals => s.nutrientGroupMineralsLabel,
    vitamins => s.nutrientGroupVitaminsLabel,
  };
}

/// One row of the daily nutrient panel.
class NutrientPanelRow {
  /// The [NutrientPanelKeys] entry, also the visibility and goal key.
  final String key;
  final NutrientPanelGroup group;

  /// Whether the reference is a limit to stay under rather than a target.
  final bool excessMatters;

  const NutrientPanelRow(this.key, this.group, {this.excessMatters = false});

  NutrientField get field => NutrientPanelTotals.panelFields[key]!;

  String label(S s) => field.label(s);

  /// Every row of the panel, grouped and in display order.
  static const all = <NutrientPanelRow>[
    NutrientPanelRow(
      NutrientPanelKeys.energy,
      NutrientPanelGroup.macros,
      excessMatters: true,
    ),
    NutrientPanelRow(
      NutrientPanelKeys.carbohydrates,
      NutrientPanelGroup.macros,
    ),
    NutrientPanelRow(
      NutrientPanelKeys.sugar,
      NutrientPanelGroup.macros,
      excessMatters: true,
    ),
    NutrientPanelRow(NutrientPanelKeys.fiber, NutrientPanelGroup.macros),
    NutrientPanelRow(NutrientPanelKeys.fat, NutrientPanelGroup.macros),
    NutrientPanelRow(NutrientPanelKeys.protein, NutrientPanelGroup.macros),
    NutrientPanelRow(
      NutrientPanelKeys.saturatedFat,
      NutrientPanelGroup.fattyAcids,
      excessMatters: true,
    ),
    NutrientPanelRow(
      NutrientPanelKeys.monounsaturatedFat,
      NutrientPanelGroup.fattyAcids,
    ),
    NutrientPanelRow(
      NutrientPanelKeys.polyunsaturatedFat,
      NutrientPanelGroup.fattyAcids,
    ),
    NutrientPanelRow(
      NutrientPanelKeys.transFat,
      NutrientPanelGroup.fattyAcids,
      excessMatters: true,
    ),
    NutrientPanelRow(
      NutrientPanelKeys.cholesterol,
      NutrientPanelGroup.fattyAcids,
      excessMatters: true,
    ),
    NutrientPanelRow(
      NutrientPanelKeys.sodium,
      NutrientPanelGroup.minerals,
      excessMatters: true,
    ),
    NutrientPanelRow(NutrientPanelKeys.potassium, NutrientPanelGroup.minerals),
    NutrientPanelRow(NutrientPanelKeys.calcium, NutrientPanelGroup.minerals),
    NutrientPanelRow(NutrientPanelKeys.magnesium, NutrientPanelGroup.minerals),
    NutrientPanelRow(NutrientPanelKeys.iron, NutrientPanelGroup.minerals),
    NutrientPanelRow(NutrientPanelKeys.zinc, NutrientPanelGroup.minerals),
    NutrientPanelRow(NutrientPanelKeys.phosphorus, NutrientPanelGroup.minerals),
    NutrientPanelRow(NutrientPanelKeys.vitaminA, NutrientPanelGroup.vitamins),
    NutrientPanelRow(NutrientPanelKeys.vitaminC, NutrientPanelGroup.vitamins),
    NutrientPanelRow(NutrientPanelKeys.vitaminD, NutrientPanelGroup.vitamins),
    NutrientPanelRow(NutrientPanelKeys.vitaminB6, NutrientPanelGroup.vitamins),
    NutrientPanelRow(NutrientPanelKeys.vitaminB12, NutrientPanelGroup.vitamins),
    NutrientPanelRow(NutrientPanelKeys.niacin, NutrientPanelGroup.vitamins),
  ];

  /// The goal [trackedDay] sets for [key] itself, or null: the user's own
  /// nutrient goals and, for energy and the macros, the day's calorie and
  /// macro goals.
  static double? ownGoal(String key, TrackedDayEntity? trackedDay) {
    if (trackedDay == null) return null;
    return trackedDay.extraNutrientGoals[key] ??
        switch (key) {
          NutrientPanelKeys.fiber => trackedDay.fibreGoal,
          NutrientPanelKeys.sodium => trackedDay.sodiumGoal,
          NutrientPanelKeys.saturatedFat => trackedDay.satFatGoal,
          NutrientPanelKeys.sugar => trackedDay.sugarsGoal,
          NutrientPanelKeys.calcium => trackedDay.calciumGoal,
          NutrientPanelKeys.iron => trackedDay.ironGoal,
          NutrientPanelKeys.potassium => trackedDay.potassiumGoal,
          NutrientPanelKeys.vitaminD => trackedDay.vitaminDGoal,
          NutrientPanelKeys.vitaminB12 => trackedDay.vitaminB12Goal,
          NutrientPanelKeys.magnesium => trackedDay.magnesiumGoal,
          NutrientPanelKeys.energy => trackedDay.calorieGoal,
          NutrientPanelKeys.carbohydrates => trackedDay.carbsGoal,
          NutrientPanelKeys.fat => trackedDay.fatGoal,
          NutrientPanelKeys.protein => trackedDay.proteinGoal,
          _ => null,
        };
  }

  /// References for the nutrients added in #47 when neither the user nor
  /// the IOM table gives one: FDA Daily Values for energy, the macros and
  /// cholesterol, the midpoint of the female and male IOM RDAs for the
  /// rest. Mono- and polyunsaturated and trans fat have none.
  static const extraDefaults = <String, double>{
    NutrientPanelKeys.energy: 2000,
    NutrientPanelKeys.carbohydrates: 275,
    NutrientPanelKeys.fat: 78,
    NutrientPanelKeys.protein: 50,
    NutrientPanelKeys.cholesterol: 300,
    NutrientPanelKeys.zinc: 9.5,
    NutrientPanelKeys.phosphorus: 700,
    NutrientPanelKeys.vitaminA: 800,
    NutrientPanelKeys.vitaminC: 82.5,
    NutrientPanelKeys.vitaminB6: 1.3,
    NutrientPanelKeys.niacin: 15,
  };

  /// The reference of a nutrient added in #47, or null when there is
  /// none: the user's own goal for the day, for energy and the macros the
  /// day's calorie and macro goals, then the IOM value for [user], then
  /// [extraDefaults].
  static double? extraReference(
    String key, {
    TrackedDayEntity? trackedDay,
    UserEntity? user,
  }) {
    final own = ownGoal(key, trackedDay);
    if (own != null) return own;
    if (user != null) {
      final dri = getReferenceFor(nutrient: key, user: user);
      if (dri != null) return dri.amount;
    }
    return extraDefaults[key];
  }
}
