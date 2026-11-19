import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:opennutritracker/core/l10n/app_locales.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
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
      );

  /// The labels for figures already stored, for when only the language
  /// changed.
  factory CalorieWidgetLabels.forFigures(
    S s, {
    required int consumedKcal,
    required int goalKcal,
    CalorieWidgetMacros? macros,
    CalorieWidgetWater? water,
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
    );
  }

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

  Map<String, String> languageJson() => {
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
  };

  Map<String, String> figureJson() => {
    'goal': goal,
    'accessibility': accessibility,
    // Left out, not empty, so a reader falls back to `accessibility`.
    if (rowAccessibility.isNotEmpty) 'rowAccessibility': rowAccessibility,
  };

  String encodeLanguage() => jsonEncode(languageJson());
}
