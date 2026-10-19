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
    });
    expect(labels.figureJson(), {
      'goal': 'of 2001',
      'accessibility': '180 of 2001 kilocalories',
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
