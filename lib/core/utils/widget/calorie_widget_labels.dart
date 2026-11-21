import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:intl/intl.dart' show NumberFormat;
import 'package:opennutritracker/core/l10n/app_locales.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_nutrients.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart'
    show NutrientPanelKeys;
import 'package:opennutritracker/generated/l10n.dart';

/// The stable ids of the widget background styles. The extension offers
/// them in the Edit Widget sheet and reads the same strings.
class CalorieWidgetStyleIds {
  static const system = 'system';
  static const paper = 'paper';
  static const dark = 'dark';
  static const highContrast = 'highContrast';
}

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

  /// What the small widgets say instead of "Open the app" when the app is
  /// up to date but has no figure to show: the chosen nutrient is not
  /// shown in the app, or there is no water goal. Language-only.
  final String nutrientNotShown;
  final String waterNoGoal;

  /// The nutrient widget's names by stable id: calories, the three macros
  /// and the panel nutrients. The Edit Widget picker offers exactly these.
  /// Language-only, so the picker works before the first Home write and
  /// after a wipe, and every id is offered even while its nutrient is
  /// hidden.
  final Map<String, String> nutrientNames;

  /// The names of the widget background styles by stable id, in the order
  /// the Edit Widget sheet offers them. Language-only, like the nutrient
  /// names. The ids are `system`, `paper`, `dark` and `highContrast`.
  final Map<String, String> styleNames;

  /// The small widgets' text that describes figures. Each is empty or
  /// absent when its figure was not written, so the reader never speaks a
  /// figure it lacks: the VoiceOver sentences of the macros and water
  /// widgets, and the water goal phrase, e.g. 'of 1900'.
  final String macrosAccessibility;
  final String waterAccessibility;
  final String waterGoal;

  /// What the nutrient widget says about each nutrient it can show, by id:
  /// its goal phrase, e.g. 'of 30', when it has a goal, and its VoiceOver
  /// sentence. Calories keep [goal] and [accessibility].
  final Map<String, Map<String, String>> nutrientFigures;

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
    this.nutrientNotShown = '',
    this.waterNoGoal = '',
    this.nutrientNames = const {},
    this.styleNames = const {},
    this.macrosAccessibility = '',
    this.waterAccessibility = '',
    this.waterGoal = '',
    this.nutrientFigures = const {},
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
    final caloriesOver = _isOver(consumedKcal, goalKcal);
    final macrosOver = [
      if (macros != null && _isOver(macros.proteinIntakeG, macros.proteinGoalG))
        s.proteinLabel,
      if (macros != null && _isOver(macros.fatsIntakeG, macros.fatsGoalG))
        s.fatLabel,
      if (macros != null && _isOver(macros.carbsIntakeG, macros.carbsGoalG))
        s.carbsLabel,
    ];
    final waterOver = water != null && _isOver(water.intakeMl, water.goalMl);
    return CalorieWidgetLabels(
      title: s.trendsCaloriesLabel,
      unit: s.kcalLabel,
      goal: s.calorieWidgetGoalLabel(goal),
      accessibility: _withOver(
        s,
        s.calorieWidgetAccessibilityLabel(consumed, goal),
        [if (caloriesOver) s.trendsCaloriesLabel],
      ),
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
          : _withOver(
              s,
              s.nutritionRowWidgetAccessibilityLabel(
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
              [
                if (caloriesOver) s.trendsCaloriesLabel,
                ...macrosOver,
                if (waterOver) s.trendsWaterLabel,
              ],
            ),
      macrosTitle: s.macrosSmallWidgetDisplayName,
      macrosDescription: s.macrosSmallWidgetDescription,
      waterDescription: s.waterSmallWidgetDescription,
      nutrientNotShown: s.nutrientWidgetNotShownLabel,
      waterNoGoal: s.waterSmallWidgetNoGoalLabel,
      nutrientNames: _nutrientNames(s),
      styleNames: _styleNames(s),
      macrosAccessibility: macros == null
          ? ''
          : _withOver(
              s,
              s.macrosSmallWidgetAccessibilityLabel(
                '${macros.proteinIntakeG}',
                '${macros.proteinGoalG}',
                '${macros.fatsIntakeG}',
                '${macros.fatsGoalG}',
                '${macros.carbsIntakeG}',
                '${macros.carbsGoalG}',
              ),
              macrosOver,
            ),
      waterAccessibility: water == null
          ? ''
          : _withOver(
              s,
              s.waterSmallWidgetAccessibilityLabel(
                '${water.intakeMl}',
                '${water.goalMl}',
              ),
              [if (waterOver) s.trendsWaterLabel],
            ),
      waterGoal: water == null
          ? ''
          : s.calorieWidgetGoalLabel(_figure(water.goalMl.toDouble())),
      nutrientFigures: _nutrientFigures(s, macros, nutrients),
    );
  }

  /// A figure above a goal. A goal of zero or less is no goal.
  static bool _isOver(num value, num goal) => goal > 0 && value > goal;

  /// [sentence] followed by one over-the-goal sentence for each name in
  /// [over]. The cue has words so that no state depends on colour or on a
  /// symbol. The sentence is returned as it is when nothing is over.
  static String _withOver(S s, String sentence, List<String> over) {
    if (over.isEmpty) return sentence;
    final joiner = sentence.endsWith('.') ? ' ' : '. ';
    return '$sentence$joiner${over.map(s.widgetOverGoalLabel).join(' ')}';
  }

  /// The widget background styles' names, in the order the Edit Widget
  /// sheet offers them.
  static Map<String, String> _styleNames(S s) => {
    CalorieWidgetStyleIds.system: s.widgetStyleSystem,
    CalorieWidgetStyleIds.paper: s.widgetStylePaper,
    CalorieWidgetStyleIds.dark: s.widgetStyleDark,
    CalorieWidgetStyleIds.highContrast: s.widgetStyleHighContrast,
  };

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

  /// The goal phrase and the sentence for each macro and panel nutrient
  /// the snapshot holds. Calories keep their own. A nutrient without a goal
  /// gets no goal phrase and the sentence without "of", never a goal of
  /// zero.
  static Map<String, Map<String, String>> _nutrientFigures(
    S s,
    CalorieWidgetMacros? macros,
    List<CalorieWidgetNutrient> nutrients,
  ) {
    final names = _nutrientNames(s);
    // The panel nutrients carry fractions, so their amounts are written
    // here in the app's language and the widget prints them as given. The
    // macros are whole grams and the widget prints those itself.
    Map<String, String> figure(
      CalorieWidgetNutrient nutrient, {
      bool writesValue = true,
    }) {
      final name = names[nutrient.id] ?? nutrient.id;
      final amount = writesValue
          ? _amount(s, nutrient.consumed)
          : _figure(nutrient.consumed);
      final goal = nutrient.goal;
      if (goal == null) {
        return {
          if (writesValue) 'value': amount,
          'accessibility': s.nutrientWidgetAccessibilityNoGoalLabel(
            name,
            amount,
            nutrient.unit,
          ),
        };
      }
      final goalText = writesValue ? _amount(s, goal) : _figure(goal);
      return {
        if (writesValue) 'value': amount,
        'goal': s.calorieWidgetGoalLabel(goalText),
        'accessibility': _withOver(
          s,
          s.nutrientWidgetAccessibilityLabel(
            name,
            amount,
            nutrient.unit,
            goalText,
          ),
          [if (_isOver(nutrient.consumed, goal)) name],
        ),
      };
    }

    CalorieWidgetNutrient gram(String id, int consumed, int goal) =>
        CalorieWidgetNutrient.normalised(
          id: id,
          consumed: consumed,
          goal: goal,
          unit: s.gramUnit,
        );

    return {
      for (final nutrient in nutrients) nutrient.id: figure(nutrient),
      if (macros != null) ...{
        CalorieWidgetNutrientIds.protein: figure(
          gram(
            CalorieWidgetNutrientIds.protein,
            macros.proteinIntakeG,
            macros.proteinGoalG,
          ),
          writesValue: false,
        ),
        CalorieWidgetNutrientIds.carbs: figure(
          gram(
            CalorieWidgetNutrientIds.carbs,
            macros.carbsIntakeG,
            macros.carbsGoalG,
          ),
          writesValue: false,
        ),
        CalorieWidgetNutrientIds.fat: figure(
          gram(
            CalorieWidgetNutrientIds.fat,
            macros.fatsIntakeG,
            macros.fatsGoalG,
          ),
          writesValue: false,
        ),
      },
    };
  }

  /// An amount in the app's language, with up to one decimal and no digit
  /// grouping. The value and its goal both use it, so a cell never reads
  /// "3,456.7" over "of 3500".
  static String _amount(S s, double value) =>
      NumberFormat('0.#', s.localeName).format(value);

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
    'nutrientNotShown': nutrientNotShown,
    'waterNoGoal': waterNoGoal,
    // A list, not a map, so the picker keeps this order.
    'nutrients': [
      for (final entry in nutrientNames.entries)
        {'id': entry.key, 'name': entry.value},
    ],
    // A list too, in the order the Edit Widget sheet offers the styles.
    'styles': [
      for (final entry in styleNames.entries)
        {'id': entry.key, 'name': entry.value},
    ],
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
    if (waterGoal.isNotEmpty) 'waterGoal': waterGoal,
    if (nutrientFigures.isNotEmpty) 'nutrients': nutrientFigures,
  };

  String encodeLanguage() => jsonEncode(languageJson());
}
