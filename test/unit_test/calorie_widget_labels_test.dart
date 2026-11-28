import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_nutrients.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  final snapshot = CalorieWidgetSnapshot.fromHome(
    consumedKcal: 180.4,
    goalKcal: 2000.6,
    offsetMinutes: 0,
    now: DateTime(2026, 9, 23, 13, 0),
  );

  tearDown(AppLocale.reset);

  test('carries the snapshot figures into the goal and VoiceOver lines', () {
    final labels = CalorieWidgetLabels.of(
      lookupS(const Locale('en')),
      snapshot,
    );

    expect(labels.languageJson(), {
      'title': 'Calories',
      'unit': 'kcal',
      'openApp': 'Open the app',
      'description': "Today's calories eaten and your goal.",
      // The macro-row names and the gram unit, for an Android widget that
      // composes its rows without any Swift-side or Kotlin-side strings.
      'protein': 'protein',
      'carbs': 'carbs',
      'fat': 'fat',
      'gram': 'g',
      // The one-row widget: water name, its unit, and the gallery text.
      'water': 'Water',
      'milliliter': 'ml',
      'rowTitle': 'Nutrition',
      'rowDescription': "Today's calories, macros and water in one row.",
      // The small macros and water widgets: gallery text.
      'macrosTitle': 'Macros',
      'macrosDescription': "Today's protein, fat and carbs against your goals.",
      'waterDescription': "Today's water against your goal.",
      // What a small widget says when the app has no figure to show.
      'nutrientNotShown': 'Not shown in the app',
      'waterNoGoal': 'No water goal set',
      // The names the nutrient picker offers, by stable id, in the order
      // the picker lists them.
      'nutrients': [
        {'id': 'calories', 'name': 'Calories'},
        {'id': 'protein', 'name': 'protein'},
        {'id': 'carbs', 'name': 'carbs'},
        {'id': 'fat', 'name': 'fat'},
        {'id': 'fiber', 'name': 'fiber'},
        {'id': 'sodium', 'name': 'sodium'},
        {'id': 'saturated_fat', 'name': 'saturated fat'},
        {'id': 'sugar', 'name': 'sugar'},
        {'id': 'calcium', 'name': 'calcium'},
        {'id': 'iron', 'name': 'iron'},
        {'id': 'potassium', 'name': 'potassium'},
        {'id': 'vitamin_d', 'name': 'vitamin D'},
        {'id': 'vitamin_b12', 'name': 'vitamin B12'},
        {'id': 'magnesium', 'name': 'magnesium'},
      ],
      // The background styles the Edit Widget sheet offers, in order.
      'styles': [
        {'id': 'system', 'name': 'System'},
        {'id': 'paper', 'name': 'Paper'},
        {'id': 'dark', 'name': 'Dark'},
        {'id': 'highContrast', 'name': 'High contrast'},
      ],
    });
    expect(labels.figureJson(), {
      'goal': 'of 2001',
      'accessibility': '180 of 2001 kilocalories',
    });
  });

  group('the one-row widget sentence', () {
    const macros = CalorieWidgetMacros(
      proteinIntakeG: 9,
      proteinGoalG: 75,
      carbsIntakeG: 20,
      carbsGoalG: 300,
      fatsIntakeG: 4,
      fatsGoalG: 67,
    );
    const water = CalorieWidgetWater(intakeMl: 750, goalMl: 1900);

    CalorieWidgetSnapshot snapshotWith({
      CalorieWidgetMacros? macros,
      CalorieWidgetWater? water,
    }) => CalorieWidgetSnapshot.fromHome(
      consumedKcal: 180,
      goalKcal: 2000,
      offsetMinutes: 0,
      now: DateTime(2026, 9, 23, 13, 0),
      macros: macros,
      water: water,
    );

    test('one sentence carries every figure', () {
      final labels = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        snapshotWith(macros: macros, water: water),
      );

      expect(
        labels.figureJson()['rowAccessibility'],
        '180 of 2000 kilocalories. Carbs 20 of 300 grams. '
        'Fat 4 of 67 grams. Protein 9 of 75 grams. '
        'Water 750 of 1900 millilitres.',
      );
      // The ring keys are the same strings as before.
      expect(labels.figureJson()['goal'], 'of 2000');
      expect(labels.figureJson()['accessibility'], '180 of 2000 kilocalories');
    });

    test('without macros or without water there is no row sentence', () {
      // The reader falls back to the calorie sentence, so a figure that
      // was not written is never spoken as zero.
      for (final snapshot in [
        snapshotWith(),
        snapshotWith(macros: macros),
        snapshotWith(water: water),
      ]) {
        final labels = CalorieWidgetLabels.of(
          lookupS(const Locale('en')),
          snapshot,
        );

        expect(labels.figureJson().containsKey('rowAccessibility'), isFalse);
      }
    });

    test('is translated through the app strings', () {
      final english = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        snapshotWith(macros: macros, water: water),
      );
      final german = CalorieWidgetLabels.of(
        lookupS(const Locale('de')),
        snapshotWith(macros: macros, water: water),
      );

      expect(german.water, lookupS(const Locale('de')).trendsWaterLabel);
      expect(german.rowTitle, isNotEmpty);
      expect(german.rowAccessibility, isNotEmpty);
      expect(german.figureJson().keys, contains('rowAccessibility'));
      expect(english.rowAccessibility, contains('750'));
    });
  });

  group('the small widgets', () {
    const macros = CalorieWidgetMacros(
      proteinIntakeG: 9,
      proteinGoalG: 75,
      carbsIntakeG: 20,
      carbsGoalG: 300,
      fatsIntakeG: 4,
      fatsGoalG: 67,
    );
    const water = CalorieWidgetWater(intakeMl: 750, goalMl: 1900);
    const fiber = CalorieWidgetNutrient(
      id: 'fiber',
      consumed: 12.5,
      goal: 30,
      unit: 'g',
    );
    const sodium = CalorieWidgetNutrient(
      id: 'sodium',
      consumed: 800,
      unit: 'mg',
    );

    CalorieWidgetSnapshot snapshotWith({
      CalorieWidgetMacros? macros,
      CalorieWidgetWater? water,
      List<CalorieWidgetNutrient> nutrients = const [],
    }) => CalorieWidgetSnapshot.fromHome(
      consumedKcal: 180,
      goalKcal: 2000,
      offsetMinutes: 0,
      now: DateTime(2026, 9, 23, 13, 0),
      macros: macros,
      water: water,
      nutrients: nutrients,
    );

    final full = snapshotWith(
      macros: macros,
      water: water,
      nutrients: [fiber, sodium],
    );

    test('the macros and water sentences carry every figure', () {
      final json = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        full,
      ).figureJson();

      expect(
        json['macrosAccessibility'],
        'Protein 9 of 75 grams. Fat 4 of 67 grams. Carbs 20 of 300 grams.',
      );
      expect(json['waterAccessibility'], 'Water 750 of 1900 millilitres.');
      expect(json['waterGoal'], 'of 1900');
    });

    test('a nutrient gets its goal phrase and a sentence with its figures', () {
      final json = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        full,
      ).figureJson();

      expect(json['nutrients'], {
        'fiber': {
          'value': '12.5',
          'goal': 'of 30',
          'accessibility': 'fiber: 12.5 g of 30 g',
        },
        // No goal, so no phrase and no "of": a missing figure is never
        // spoken or shown as zero.
        'sodium': {'value': '800', 'accessibility': 'sodium: 800 mg'},
        'protein': {'goal': 'of 75', 'accessibility': 'protein: 9 g of 75 g'},
        'carbs': {'goal': 'of 300', 'accessibility': 'carbs: 20 g of 300 g'},
        'fat': {'goal': 'of 67', 'accessibility': 'fat: 4 g of 67 g'},
      });
    });

    test('a figure the app did not write has no sentence', () {
      final json = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        snapshotWith(),
      ).figureJson();

      expect(json.containsKey('macrosAccessibility'), isFalse);
      expect(json.containsKey('waterAccessibility'), isFalse);
      expect(json.containsKey('waterGoal'), isFalse);
      expect(json.containsKey('nutrients'), isFalse);
      expect(json.keys, containsAll(['goal', 'accessibility']));
    });

    test('a hidden nutrient has no sentence, but keeps its name', () {
      final labels = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        snapshotWith(macros: macros, nutrients: [fiber]),
      );

      final figures = labels.figureJson()['nutrients']! as Map;
      expect(figures.containsKey('sodium'), isFalse);
      // The picker still offers it. It shows a placeholder until shown again.
      expect(labels.nutrientNames['sodium'], 'sodium');
    });

    test('a figure and its goal share one format, never grouped', () {
      const big = CalorieWidgetNutrient(
        id: 'potassium',
        consumed: 3456.7,
        goal: 3500,
        unit: 'mg',
      );
      final snapshot = snapshotWith(nutrients: const [big]);
      final de = lookupS(const Locale('de'));
      Map<Object?, Object?> figureOf(S strings) =>
          CalorieWidgetLabels.of(strings, snapshot).figureJson()['nutrients']!
              as Map<Object?, Object?>;
      final english = figureOf(lookupS(const Locale('en')));
      final german = figureOf(de);

      // The value and the goal text are both ungrouped, never "3,456.7"
      // over "of 3500".
      final englishFigure = english['potassium']! as Map;
      final germanFigure = german['potassium']! as Map;
      expect(englishFigure['value'], '3456.7');
      expect(englishFigure['goal'], 'of 3500');
      expect(germanFigure['value'], '3456,7');
      expect(germanFigure['goal'], de.calorieWidgetGoalLabel('3500'));
    });

    test('the no-figure lines are language-only and translated', () {
      final de = lookupS(const Locale('de'));
      final withFigures = CalorieWidgetLabels.of(de, full);
      final without = CalorieWidgetLabels.of(de, snapshotWith());

      expect(withFigures.nutrientNotShown, de.nutrientWidgetNotShownLabel);
      expect(withFigures.waterNoGoal, de.waterSmallWidgetNoGoalLabel);
      expect(without.languageJson()['nutrientNotShown'], isNotEmpty);
      expect(without.languageJson()['waterNoGoal'], isNotEmpty);
      // They are not figure text, so a wipe keeps them with the language.
      expect(without.figureJson().containsKey('nutrientNotShown'), isFalse);
    });

    test('the nutrient names do not depend on the figures', () {
      final withFigures = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        full,
      );
      final without = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        snapshotWith(),
      );

      expect(without.nutrientNames, withFigures.nutrientNames);
      expect(without.nutrientNames, hasLength(14));
      expect(
        without.nutrientNames.values.every((name) => name.isNotEmpty),
        isTrue,
      );
    });

    test('a language change translates the names and the sentences', () {
      final de = lookupS(const Locale('de'));
      final english = CalorieWidgetLabels.of(lookupS(const Locale('en')), full);
      final german = CalorieWidgetLabels.of(de, full);

      expect(german.nutrientNames['fiber'], de.fiberLabel);
      expect(german.nutrientNames['calories'], de.trendsCaloriesLabel);
      expect(german.nutrientNames['vitamin_b12'], de.vitaminB12Label);
      expect(german.nutrientNames['protein'], de.proteinLabel);
      // The amounts are written in the app's language, so a German
      // decimal comma comes with the German words.
      expect((german.figureJson()['nutrients']! as Map)['fiber'], {
        'value': '12,5',
        'goal': de.calorieWidgetGoalLabel('30'),
        'accessibility': de.nutrientWidgetAccessibilityLabel(
          de.fiberLabel,
          '12,5',
          'g',
          '30',
        ),
      });
      expect(german.macrosTitle, de.macrosSmallWidgetDisplayName);
      expect(german.encodeLanguage(), isNot(english.encodeLanguage()));
    });

    test('the names travel in the language-only JSON, as one value', () {
      final labels = CalorieWidgetLabels.of(lookupS(const Locale('en')), full);

      final decoded = jsonDecode(labels.encodeLanguage());

      expect(decoded['nutrients'].first, {
        'id': 'calories',
        'name': 'Calories',
      });
      expect(decoded['nutrients'][4], {'id': 'fiber', 'name': 'fiber'});
      expect(decoded['title'], 'Calories');
      // The figure sentences are not in it: a wipe must not keep them.
      expect(decoded.containsKey('macrosAccessibility'), isFalse);
      expect(decoded.containsKey('waterAccessibility'), isFalse);
      expect(decoded.containsKey('waterGoal'), isFalse);
    });

    test('whole amounts print without a decimal and others with one', () {
      final labels = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        snapshotWith(
          nutrients: const [
            CalorieWidgetNutrient(
              id: 'iron',
              consumed: 8.0,
              goal: 18,
              unit: 'mg',
            ),
            CalorieWidgetNutrient(
              id: 'vitamin_b12',
              consumed: 1.3,
              goal: 2.4,
              unit: 'µg',
            ),
          ],
        ),
      );

      expect(labels.figureJson()['nutrients'], {
        'iron': {
          'value': '8',
          'goal': 'of 18',
          'accessibility': 'iron: 8 mg of 18 mg',
        },
        'vitamin_b12': {
          'value': '1.3',
          'goal': 'of 2.4',
          'accessibility': 'vitamin B12: 1.3 µg of 2.4 µg',
        },
      });
    });
  });

  test('reuses the app\'s existing Calories string, so it is translated', () {
    final labels = CalorieWidgetLabels.of(
      lookupS(const Locale('de')),
      snapshot,
    );

    expect(labels.title, lookupS(const Locale('de')).trendsCaloriesLabel);
    expect(labels.title, isNot('Calories'));
  });

  test('follows the language chosen in the app', () {
    AppLocale.select('de');

    final labels = CalorieWidgetLabels.forAppLocale(snapshot);

    expect(labels.title, lookupS(const Locale('de')).trendsCaloriesLabel);
  });

  test('falls back to English for a language the app does not ship', () {
    AppLocale.select('xx_YY');

    final labels = CalorieWidgetLabels.forAppLocale(snapshot);

    expect(labels.title, 'Calories');
  });

  group('the widget background styles', () {
    test('are written with stable ids in the app\'s language', () {
      final german = CalorieWidgetLabels.of(
        lookupS(const Locale('de')),
        snapshot,
      );
      final de = lookupS(const Locale('de'));

      expect(german.styleNames.keys, [
        CalorieWidgetStyleIds.system,
        CalorieWidgetStyleIds.paper,
        CalorieWidgetStyleIds.dark,
        CalorieWidgetStyleIds.highContrast,
      ]);
      expect(
        german.styleNames[CalorieWidgetStyleIds.paper],
        de.widgetStylePaper,
      );
      expect(
        german.styleNames[CalorieWidgetStyleIds.highContrast],
        de.widgetStyleHighContrast,
      );
    });

    test('travel in the language-only JSON as an ordered list', () {
      final labels = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        snapshot,
      );

      final decoded = jsonDecode(labels.encodeLanguage());

      expect(decoded['styles'], [
        {'id': 'system', 'name': 'System'},
        {'id': 'paper', 'name': 'Paper'},
        {'id': 'dark', 'name': 'Dark'},
        {'id': 'highContrast', 'name': 'High contrast'},
      ]);
    });

    test('an older write without them still decodes as the other labels', () {
      final labels = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        snapshot,
      );
      final json = Map<String, Object?>.from(labels.languageJson())
        ..remove('styles');

      final decoded = jsonDecode(jsonEncode(json)) as Map<String, Object?>;

      expect(decoded.containsKey('styles'), isFalse);
      expect(decoded['title'], 'Calories');
      expect(decoded['nutrients'], isNotEmpty);
    });
  });

  group('the over-the-goal wording', () {
    final en = lookupS(const Locale('en'));
    const macros = CalorieWidgetMacros(
      proteinIntakeG: 102,
      proteinGoalG: 116,
      carbsIntakeG: 413,
      carbsGoalG: 465,
      fatsIntakeG: 96,
      fatsGoalG: 86,
    );
    const water = CalorieWidgetWater(intakeMl: 2500, goalMl: 1900);

    test('is added to each sentence for a figure above its goal only', () {
      final labels = CalorieWidgetLabels.forFigures(
        en,
        consumedKcal: 2898,
        goalKcal: 2000,
        macros: macros,
        water: water,
      );

      expect(
        labels.accessibility,
        '2898 of 2000 kilocalories. Calories is over the goal.',
      );
      expect(labels.macrosAccessibility, endsWith('fat is over the goal.'));
      expect(labels.macrosAccessibility, isNot(contains('protein is over')));
      expect(labels.waterAccessibility, endsWith('Water is over the goal.'));
      expect(labels.rowAccessibility, contains('Calories is over the goal.'));
      expect(labels.rowAccessibility, contains('fat is over the goal.'));
      expect(labels.rowAccessibility, contains('Water is over the goal.'));
      expect(labels.rowAccessibility, isNot(contains('carbs is over')));
    });

    test('is left out when every figure is at or under its goal', () {
      final labels = CalorieWidgetLabels.forFigures(
        en,
        consumedKcal: 2000,
        goalKcal: 2000,
        macros: const CalorieWidgetMacros(
          proteinIntakeG: 116,
          proteinGoalG: 116,
          carbsIntakeG: 1,
          carbsGoalG: 465,
          fatsIntakeG: 0,
          fatsGoalG: 86,
        ),
        water: const CalorieWidgetWater(intakeMl: 1900, goalMl: 1900),
      );

      expect(labels.accessibility, '2000 of 2000 kilocalories');
      expect(labels.macrosAccessibility, isNot(contains('over the goal')));
      expect(labels.waterAccessibility, isNot(contains('over the goal')));
      expect(labels.rowAccessibility, isNot(contains('over the goal')));
    });

    test('is never added for a goal of zero', () {
      final labels = CalorieWidgetLabels.forFigures(
        en,
        consumedKcal: 500,
        goalKcal: 0,
        water: const CalorieWidgetWater(intakeMl: 500, goalMl: 0),
      );

      expect(labels.accessibility, isNot(contains('over the goal')));
      expect(labels.waterAccessibility, isNot(contains('over the goal')));
    });

    test('is added to a panel nutrient above its goal', () {
      final labels = CalorieWidgetLabels.forFigures(
        en,
        consumedKcal: 100,
        goalKcal: 2000,
        nutrients: const [
          CalorieWidgetNutrient(id: 'fiber', consumed: 35, goal: 30, unit: 'g'),
        ],
      );

      final fiber = (labels.figureJson()['nutrients']! as Map)['fiber'] as Map;
      expect(fiber['accessibility'], endsWith('fiber is over the goal.'));
    });
  });
}
