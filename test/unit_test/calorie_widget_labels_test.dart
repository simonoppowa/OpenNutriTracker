import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
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
