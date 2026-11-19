import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:opennutritracker/core/l10n/app_locales.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_nutrients.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart'
    show NutrientPanelKeys;
import 'package:opennutritracker/generated/l10n.dart';

/// The iOS widget's text, translated on the Dart side.
///
/// The extension cannot read the generated Dart strings, and copy written
/// in Swift would sit outside the ARB/Weblate pipeline. So the app writes
/// the already-localized labels into the App Group next to the numbers,
/// and the extension falls back to English only until the first write.
class CalorieWidgetLabels {
  /// The App Group key of the labels that depend only on the language, as
  /// one JSON string. They hold nothing about the profile, so a wipe keeps
  /// them and the placeholder stays translated. The labels that carry the
  /// figures travel inside the snapshot instead
  /// ([CalorieWidgetSnapshot.encode]), so they always describe it.
  static const storageKey = 'ont_calorie_labels';

  final String title;
  final String unit;
  final String goal;
  final String accessibility;
  final String openApp;
  final String description;

  /// Macro-row names and the gram unit, so an Android widget composes
  /// its rows without a shader of its own Dart. Language-only like
  /// everything else here.
  final String protein;
  final String carbs;
  final String fat;
  final String gram;

  /// The one-row widget: the water name and its unit, and the name and
  /// text the widget gallery shows. Language-only as well.
  final String water;
  final String milliliter;
  final String rowTitle;
  final String rowDescription;

  /// One VoiceOver sentence for the one-row widget, with every figure.
  /// Empty when the snapshot has no macros or no water, so the reader
  /// falls back to [accessibility] rather than speak a figure it lacks.
  final String rowAccessibility;

  /// The small macros widget's gallery text, and the small water widget's
  /// description (its name is [water]). Language-only.
  final String macrosTitle;
  final String macrosDescription;
  final String waterDescription;

  /// The nutrient widget's names by stable id: calories, the three macros
  /// and the panel nutrients. The Edit Widget picker offers exactly these.
  /// Language-only, so the picker works before the first Home write and
  /// after a wipe, and every id is offered even while its nutrient is
  /// hidden.
  final Map<String, String> nutrientNames;

  /// VoiceOver sentences for the small widgets. Each is empty or absent
  /// when its figure was not written, so the reader never speaks a
  /// figure it lacks.
  final String macrosAccessibility;
  final String waterAccessibility;

  /// One sentence per nutrient the widget can show, by id.
  final Map<String, String> nutrientAccessibility;

  const CalorieWidgetLabels({
    required this.title,
    required this.unit,
    required this.goal,
    required this.accessibility,
    required this.openApp,
    required this.description,
    this.protein = '',
    this.carbs = '',
    this.fat = '',
    this.gram = '',
    this.water = '',
    this.milliliter = '',
    this.rowTitle = '',
    this.rowDescription = '',
    this.rowAccessibility = '',
    this.macrosTitle = '',
    this.macrosDescription = '',
    this.waterDescription = '',
    this.nutrientNames = const {},
    this.macrosAccessibility = '',
    this.waterAccessibility = '',
    this.nutrientAccessibility = const {},
  });

  /// The labels for [snapshot] in the language of [s]. The goal and the
  /// VoiceOver line carry the snapshot's figures, so they are written
  /// together with it.
  factory CalorieWidgetLabels.of(S s, CalorieWidgetSnapshot snapshot) =>
      CalorieWidgetLabels.forFigures(
        s,
        consumedKcal: snapshot.consumedKcal,
        goalKcal: snapshot.goalKcal,
        macros: snapshot.macros,
        water: snapshot.water,
        nutrients: snapshot.nutrients,
      );

  /// The labels for figures already stored, for when only the language
  /// changed.
  factory CalorieWidgetLabels.forFigures(
    S s, {
    required int consumedKcal,
    required int goalKcal,
    CalorieWidgetMacros? macros,
    CalorieWidgetWater? water,
    List<CalorieWidgetNutrient> nutrients = const [],
  }) {
    final consumed = '$consumedKcal';
    final goal = '$goalKcal';
    return CalorieWidgetLabels(
      title: s.trendsCaloriesLabel,
      unit: s.kcalLabel,
      goal: s.calorieWidgetGoalLabel(goal),
      accessibility: s.calorieWidgetAccessibilityLabel(consumed, goal),
      openApp: s.calorieWidgetOpenAppHint,
      description: s.calorieWidgetDescription,
      protein: s.proteinLabel,
      carbs: s.carbsLabel,
      fat: s.fatLabel,
      gram: s.gramUnit,
      water: s.trendsWaterLabel,
      milliliter: s.mlLabel,
      rowTitle: s.nutritionRowWidgetDisplayName,
      rowDescription: s.nutritionRowWidgetDescription,
      rowAccessibility: macros == null || water == null
          ? ''
          : s.nutritionRowWidgetAccessibilityLabel(
              consumed,
              goal,
              '${macros.carbsIntakeG}',
              '${macros.carbsGoalG}',
              '${macros.fatsIntakeG}',
              '${macros.fatsGoalG}',
              '${macros.proteinIntakeG}',
              '${macros.proteinGoalG}',
              '${water.intakeMl}',
              '${water.goalMl}',
            ),
      macrosTitle: s.macrosSmallWidgetDisplayName,
      macrosDescription: s.macrosSmallWidgetDescription,
      waterDescription: s.waterSmallWidgetDescription,
      nutrientNames: _nutrientNames(s),
      macrosAccessibility: macros == null
          ? ''
          : s.macrosSmallWidgetAccessibilityLabel(
              '${macros.proteinIntakeG}',
              '${macros.proteinGoalG}',
              '${macros.fatsIntakeG}',
              '${macros.fatsGoalG}',
              '${macros.carbsIntakeG}',
              '${macros.carbsGoalG}',
            ),
      waterAccessibility: water == null
          ? ''
          : s.waterSmallWidgetAccessibilityLabel(
              '${water.intakeMl}',
              '${water.goalMl}',
            ),
      nutrientAccessibility: _nutrientSentences(s, macros, nutrients),
    );
  }

  /// The names the nutrient picker offers, from the strings the app
  /// already translates.
  static Map<String, String> _nutrientNames(S s) => {
    CalorieWidgetNutrientIds.calories: s.trendsCaloriesLabel,
    CalorieWidgetNutrientIds.protein: s.proteinLabel,
    CalorieWidgetNutrientIds.carbs: s.carbsLabel,
    CalorieWidgetNutrientIds.fat: s.fatLabel,
    NutrientPanelKeys.fiber: s.fiberLabel,
    NutrientPanelKeys.sodium: s.sodiumLabel,
    NutrientPanelKeys.saturatedFat: s.saturatedFatLabel,
    NutrientPanelKeys.sugar: s.sugarLabel,
    NutrientPanelKeys.calcium: s.calciumLabel,
    NutrientPanelKeys.iron: s.ironLabel,
    NutrientPanelKeys.potassium: s.potassiumLabel,
    NutrientPanelKeys.vitaminD: s.vitaminDLabel,
    NutrientPanelKeys.vitaminB12: s.vitaminB12Label,
    NutrientPanelKeys.magnesium: s.magnesiumLabel,
  };

  /// One sentence for each macro and panel nutrient the snapshot holds.
  /// Calories keep their own sentence. A nutrient without a goal gets the
  /// sentence without "of", never a goal of zero.
  static Map<String, String> _nutrientSentences(
    S s,
    CalorieWidgetMacros? macros,
    List<CalorieWidgetNutrient> nutrients,
  ) {
    final names = _nutrientNames(s);
    String sentence(CalorieWidgetNutrient nutrient) {
      final name = names[nutrient.id] ?? nutrient.id;
      final amount = _figure(nutrient.consumed);
      final goal = nutrient.goal;
      return goal == null
          ? s.nutrientWidgetAccessibilityNoGoalLabel(
              name,
              amount,
              nutrient.unit,
            )
          : s.nutrientWidgetAccessibilityLabel(
              name,
              amount,
              nutrient.unit,
              _figure(goal),
            );
    }

    CalorieWidgetNutrient gram(String id, int consumed, int goal) =>
        CalorieWidgetNutrient.normalised(
          id: id,
          consumed: consumed,
          goal: goal,
          unit: s.gramUnit,
        );

    return {
      for (final nutrient in nutrients) nutrient.id: sentence(nutrient),
      if (macros != null) ...{
        CalorieWidgetNutrientIds.protein: sentence(
          gram(
            CalorieWidgetNutrientIds.protein,
            macros.proteinIntakeG,
            macros.proteinGoalG,
          ),
        ),
        CalorieWidgetNutrientIds.carbs: sentence(
          gram(
            CalorieWidgetNutrientIds.carbs,
            macros.carbsIntakeG,
            macros.carbsGoalG,
          ),
        ),
        CalorieWidgetNutrientIds.fat: sentence(
          gram(
            CalorieWidgetNutrientIds.fat,
            macros.fatsIntakeG,
            macros.fatsGoalG,
          ),
        ),
      },
    };
  }

  /// A whole amount without a decimal, any other with one.
  static String _figure(double value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(1);

  /// The labels in the language the app is being read in.
  factory CalorieWidgetLabels.forAppLocale(CalorieWidgetSnapshot snapshot) =>
      CalorieWidgetLabels.of(appStrings(), snapshot);

  /// The strings for the language the app is being read in. Home publishes
  /// without a BuildContext, so this resolves [AppLocale] against the
  /// shipped locales the same way `main.dart` does for the reminder text;
  /// `lookupS` throws on a locale it does not know.
  static S appStrings() {
    final language = AppLocale.localeName.split(RegExp('[_-]')).first;
    final locale = basicLocaleListResolution([
      Locale(language),
    ], appLocales(S.supportedLocales));
    return lookupS(locale);
  }

  Map<String, Object> languageJson() => {
    'title': title,
    'unit': unit,
    'openApp': openApp,
    'description': description,
    // Empty strings rather than absent keys: a wipe keeps the labels
    // storage, so the reader must not branch on key presence for text
    // that the language, not the profile, decides.
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'gram': gram,
    'water': water,
    'milliliter': milliliter,
    'rowTitle': rowTitle,
    'rowDescription': rowDescription,
    'macrosTitle': macrosTitle,
    'macrosDescription': macrosDescription,
    'waterDescription': waterDescription,
    'nutrients': nutrientNames,
  };

  Map<String, Object> figureJson() => {
    'goal': goal,
    'accessibility': accessibility,
    // Left out, not empty, so a reader falls back to `accessibility`, or
    // to the placeholder, rather than speak a figure it lacks.
    if (rowAccessibility.isNotEmpty) 'rowAccessibility': rowAccessibility,
    if (macrosAccessibility.isNotEmpty)
      'macrosAccessibility': macrosAccessibility,
    if (waterAccessibility.isNotEmpty) 'waterAccessibility': waterAccessibility,
    if (nutrientAccessibility.isNotEmpty) 'nutrients': nutrientAccessibility,
  };

  String encodeLanguage() => jsonEncode(languageJson());
}
