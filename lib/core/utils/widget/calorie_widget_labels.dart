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
  static const titleKey = 'ont_calorie_label_title';
  static const unitKey = 'ont_calorie_label_unit';
  static const goalKey = 'ont_calorie_label_goal';
  static const accessibilityKey = 'ont_calorie_label_accessibility';
  static const openAppKey = 'ont_calorie_label_open_app';
  static const descriptionKey = 'ont_calorie_label_description';

  static const keys = [
    titleKey,
    unitKey,
    goalKey,
    accessibilityKey,
    openAppKey,
    descriptionKey,
  ];

  final String title;
  final String unit;
  final String goal;
  final String accessibility;
  final String openApp;
  final String description;

  const CalorieWidgetLabels({
    required this.title,
    required this.unit,
    required this.goal,
    required this.accessibility,
    required this.openApp,
    required this.description,
  });

  /// The labels for [snapshot] in the language of [s]. The goal and the
  /// VoiceOver line carry the snapshot's figures, so they are written
  /// together with it.
  factory CalorieWidgetLabels.of(S s, CalorieWidgetSnapshot snapshot) {
    final consumed = '${snapshot.consumedKcal}';
    final goal = '${snapshot.goalKcal}';
    return CalorieWidgetLabels(
      title: s.trendsCaloriesLabel,
      unit: s.kcalLabel,
      goal: s.calorieWidgetGoalLabel(goal),
      accessibility: s.calorieWidgetAccessibilityLabel(consumed, goal),
      openApp: s.calorieWidgetOpenAppHint,
      description: s.calorieWidgetDescription,
    );
  }

  /// The labels in the language the app is being read in. Home publishes
  /// without a BuildContext, so this resolves [AppLocale] against the
  /// shipped locales the same way `main.dart` does for the reminder text;
  /// `lookupS` throws on a locale it does not know.
  factory CalorieWidgetLabels.forAppLocale(CalorieWidgetSnapshot snapshot) {
    final language = AppLocale.localeName.split(RegExp('[_-]')).first;
    final locale = basicLocaleListResolution([
      Locale(language),
    ], appLocales(S.supportedLocales));
    return CalorieWidgetLabels.of(lookupS(locale), snapshot);
  }

  Map<String, String> toPayload() => {
    titleKey: title,
    unitKey: unit,
    goalKey: goal,
    accessibilityKey: accessibility,
    openAppKey: openApp,
    descriptionKey: description,
  };
}
