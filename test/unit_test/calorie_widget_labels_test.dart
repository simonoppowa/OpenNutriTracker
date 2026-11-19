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
      // The names the nutrient picker offers, by stable id.
      'nutrients': {
        'calories': 'Calories',
        'protein': 'protein',
        'carbs': 'carbs',
        'fat': 'fat',
        'fiber': 'fiber',
        'sodium': 'sodium',
        'saturated_fat': 'saturated fat',
        'sugar': 'sugar',
        'calcium': 'calcium',
        'iron': 'iron',
        'potassium': 'potassium',
        'vitamin_d': 'vitamin D',
        'vitamin_b12': 'vitamin B12',
        'magnesium': 'magnesium',
      },
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
    });

    test('a nutrient sentence names it, its amount, its unit and its goal', () {
      final json = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        full,
      ).figureJson();

      expect(json['nutrients'], {
        'fiber': 'fiber: 12.5 g of 30 g',
        // No goal, so no "of": a missing figure is never spoken as zero.
        'sodium': 'sodium: 800 mg',
        'protein': 'protein: 9 g of 75 g',
        'carbs': 'carbs: 20 g of 300 g',
        'fat': 'fat: 4 g of 67 g',
      });
    });

    test('a figure the app did not write has no sentence', () {
      final json = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        snapshotWith(),
      ).figureJson();

      expect(json.containsKey('macrosAccessibility'), isFalse);
      expect(json.containsKey('waterAccessibility'), isFalse);
      expect(json.containsKey('nutrients'), isFalse);
      expect(json.keys, containsAll(['goal', 'accessibility']));
    });

    test('a hidden nutrient has no sentence, but keeps its name', () {
      final labels = CalorieWidgetLabels.of(
        lookupS(const Locale('en')),
        snapshotWith(macros: macros, nutrients: [fiber]),
      );

      final sentences = labels.figureJson()['nutrients']! as Map;
      expect(sentences.containsKey('sodium'), isFalse);
      // The picker still offers it. It shows a placeholder until shown again.
      expect(labels.nutrientNames['sodium'], 'sodium');
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
      expect(
        (german.figureJson()['nutrients']! as Map)['fiber'],
        de.nutrientWidgetAccessibilityLabel(de.fiberLabel, '12.5', 'g', '30'),
      );
      expect(german.macrosTitle, de.macrosSmallWidgetDisplayName);
      expect(german.encodeLanguage(), isNot(english.encodeLanguage()));
    });

    test('the names travel in the language-only JSON, as one value', () {
      final labels = CalorieWidgetLabels.of(lookupS(const Locale('en')), full);

      final decoded = jsonDecode(labels.encodeLanguage());

      expect(decoded['nutrients']['fiber'], 'fiber');
      expect(decoded['title'], 'Calories');
      // The figure sentences are not in it: a wipe must not keep them.
      expect(decoded.containsKey('macrosAccessibility'), isFalse);
      expect(decoded.containsKey('waterAccessibility'), isFalse);
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
        'iron': 'iron: 8 mg of 18 mg',
        'vitamin_b12': 'vitamin B12: 1.3 µg of 2.4 µg',
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
}
