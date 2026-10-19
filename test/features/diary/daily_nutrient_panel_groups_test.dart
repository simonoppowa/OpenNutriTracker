import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_l10n.dart';

final _intake = IntakeEntity(
  id: 'a',
  unit: 'g',
  amount: 100,
  type: IntakeTypeEntity.breakfast,
  dateTime: DateTime(2026, 10, 19),
  meal: MealEntity(
    code: 'a',
    name: 'a',
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    source: MealSourceEntity.custom,
    nutriments: const MealNutrimentsEntity(
      energyKcal100: 150,
      carbohydrates100: 20,
      fat100: 6,
      proteins100: 3,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
      monounsaturatedFat100: 5,
      cholesterol100: 40,
      zinc100: 2,
    ),
  ),
);

Future<void> _openPanel(
  WidgetTester tester, {
  bool kilojoules = false,
  TrackedDayEntity? trackedDay,
}) async {
  await tester.binding.setSurfaceSize(const Size(500, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(usesKilojoules: kilojoules),
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: SingleChildScrollView(
            child: DailyNutrientPanel(
              intakes: [_intake],
              trackedDay: trackedDay,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ExpansionTile));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every nutrient in four groups', (tester) async {
    await _openPanel(tester);

    for (final label in [
      l10nEn.nutrientGroupMacrosLabel,
      l10nEn.nutrientGroupFattyAcidsLabel,
      l10nEn.nutrientGroupMineralsLabel,
      l10nEn.nutrientGroupVitaminsLabel,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    for (final label in [
      l10nEn.energyLabel,
      l10nEn.proteinLabel,
      l10nEn.monounsaturatedFatLabel,
      l10nEn.cholesterolLabel,
      l10nEn.zincLabel,
      l10nEn.phosphorusLabel,
      l10nEn.vitaminALabel,
      l10nEn.niacinLabel,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(LinearProgressIndicator), findsNWidgets(32));
  });

  testWidgets('energy is measured against a goal in the chosen unit', (
    tester,
  ) async {
    await _openPanel(tester);

    expect(find.text('150 / 2000 ${l10nEn.kcalLabel}'), findsOneWidget);
  });

  testWidgets('energy follows the kilojoule setting', (tester) async {
    await _openPanel(tester, kilojoules: true);

    expect(find.text('628 / 8368 ${l10nEn.kjLabel}'), findsOneWidget);
  });

  testWidgets('a nutrient without a reference shows just its amount', (
    tester,
  ) async {
    await _openPanel(tester);

    expect(find.text('5.0g'), findsOneWidget);
    expect(find.text('2.0 / 9.5mg'), findsOneWidget);
  });

  testWidgets('a group folds in and out', (tester) async {
    await _openPanel(tester);

    await tester.tap(find.text(l10nEn.nutrientGroupFattyAcidsLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.monounsaturatedFatLabel), findsNothing);
    expect(find.text(l10nEn.zincLabel), findsOneWidget);

    await tester.tap(find.text(l10nEn.nutrientGroupFattyAcidsLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.monounsaturatedFatLabel), findsOneWidget);
  });

  testWidgets('any intake goes over a limit of zero', (tester) async {
    await _openPanel(
      tester,
      trackedDay: TrackedDayEntity(
        day: DateTime(2026, 10, 19),
        calorieGoal: 2000,
        caloriesTracked: 150,
        extraNutrientGoals: const {NutrientPanelKeys.cholesterol: 0},
      ),
    );

    final row = find.ancestor(
      of: find.text(l10nEn.cholesterolLabel),
      matching: find.byType(Column),
    );
    final bar = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: row.first,
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(find.text('40 / 0.0mg'), findsOneWidget);
    expect(bar.value, 1.0);
  });
}
