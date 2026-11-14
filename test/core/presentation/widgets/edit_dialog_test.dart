import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_l10n.dart';

// The edit dialog for a logged food shows its energy and macros for the
// amount being typed, and updates them live (#1330).

/// 250 kcal, 50 g carbs, 10 g fat, 8 g protein per 100 g, unless a value
/// is passed as null (a Quick Add entry without macros, #1295).
IntakeEntity _intake({
  double amount = 40,
  String? mealUnit = 'g',
  double? kcal = 250,
  double? carbs = 50,
  double? fat = 10,
  double? protein = 8,
  MealSourceEntity source = MealSourceEntity.off,
}) => IntakeEntity(
  id: 'intake-1',
  unit: mealUnit ?? 'g',
  amount: amount,
  type: IntakeTypeEntity.lunch,
  dateTime: DateTime(2026, 11, 9, 12),
  meal: MealEntity(
    code: 'food-1',
    name: 'Oats',
    url: null,
    mealQuantity: null,
    mealUnit: mealUnit,
    servingQuantity: null,
    servingUnit: mealUnit,
    servingSize: null,
    nutriments: MealNutrimentsEntity(
      energyKcal100: kcal,
      carbohydrates100: carbs,
      fat100: fat,
      proteins100: protein,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: source,
  ),
);

/// Opens the dialog the way the home and diary pages do, and returns a
/// future for the amount it pops.
Future<Future<double?>> _open(
  WidgetTester tester,
  IntakeEntity intake, {
  bool imperial = false,
  bool kilojoules = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  late Future<double?> result;
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(usesKilojoules: kilojoules),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  result = showDialog<double>(
                    context: context,
                    builder: (_) => EditDialog(
                      intakeEntity: intake,
                      usesImperialUnits: imperial,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

Finder get _field => find.byKey(EditDialog.amountFieldKey);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_field, text);
  await tester.pump();
}

void _expectValues(String energy, String carbs, String fat, String protein) {
  expect(find.text(energy), findsOneWidget, reason: 'energy');
  expect(find.text(carbs), findsOneWidget, reason: 'carbs');
  expect(find.text(fat), findsOneWidget, reason: 'fat');
  expect(find.text(protein), findsOneWidget, reason: 'protein');
}

void _expectAllUnknown() {
  expect(find.text(missingNutrientPlaceholder), findsNWidgets(4));
  expect(find.textContaining('kcal'), findsNothing);
}

void main() {
  testWidgets('opens with the logged amount\'s energy and macros', (
    tester,
  ) async {
    await _open(tester, _intake());

    _expectValues('100 kcal', '20.0 g', '4.0 g', '3.2 g');
    expect(find.text(l10nEn.carbsLabel), findsOneWidget);
    expect(find.text(l10nEn.fatLabel), findsOneWidget);
    expect(find.text(l10nEn.proteinLabel), findsOneWidget);
  });

  testWidgets('a new amount updates the values as it is typed', (tester) async {
    await _open(tester, _intake());

    await _type(tester, '60');
    _expectValues('150 kcal', '30.0 g', '6.0 g', '4.8 g');

    await _type(tester, '6');
    _expectValues('15 kcal', '3.0 g', '0.6 g', '0.5 g');
  });

  testWidgets('a comma decimal separator is read as a decimal point', (
    tester,
  ) async {
    await _open(tester, _intake());

    await _type(tester, '60,5');

    // 60.5 g, not 605 g.
    _expectValues('151 kcal', '30.3 g', '6.1 g', '4.8 g');
  });

  testWidgets('0 shows zero, not unknown', (tester) async {
    await _open(tester, _intake());

    await _type(tester, '0');

    expect(find.text('0 kcal'), findsOneWidget);
    expect(find.text('0.0 g'), findsNWidgets(3));
    expect(find.text(missingNutrientPlaceholder), findsNothing);
  });

  testWidgets('an empty field shows every value as unknown', (tester) async {
    await _open(tester, _intake());

    await _type(tester, '');

    _expectAllUnknown();
  });

  testWidgets('a value that is not a number shows every value as unknown', (
    tester,
  ) async {
    await _open(tester, _intake());

    for (final text in ['abc', '.', '1.2.3', '-5']) {
      await _type(tester, text);
      _expectAllUnknown();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('an amount too large for a double shows unknown, no crash', (
    tester,
  ) async {
    await _open(tester, _intake());

    await _type(tester, '1e999');

    _expectAllUnknown();
    expect(tester.takeException(), isNull);
  });

  testWidgets('kJ mode shows the energy in kJ', (tester) async {
    await _open(tester, _intake(), kilojoules: true);

    _expectValues('418 kJ', '20.0 g', '4.0 g', '3.2 g');

    await _type(tester, '60');
    // 150 kcal × 4.184 = 627.6 kJ.
    _expectValues('628 kJ', '30.0 g', '6.0 g', '4.8 g');
    expect(find.textContaining('kcal'), findsNothing);
  });

  testWidgets('imperial units: the typed ounces are converted to grams', (
    tester,
  ) async {
    await _open(tester, _intake(), imperial: true);

    _expectValues('100 kcal', '20.0 g', '4.0 g', '3.2 g');

    await _type(tester, '2');
    final grams = UnitCalc.ozToG(2);
    expect(find.text('${(grams * 2.5).round()} kcal'), findsOneWidget);
    expect(find.text('${(grams * 0.5 * 10).round() / 10} g'), findsOneWidget);
  });

  testWidgets('missing macros show as unknown, not 0 g', (tester) async {
    await _open(
      tester,
      _intake(
        kcal: 300,
        carbs: null,
        fat: null,
        protein: null,
        source: MealSourceEntity.custom,
      ),
    );

    expect(find.text('120 kcal'), findsOneWidget);
    expect(find.text(missingNutrientPlaceholder), findsNWidgets(3));
    expect(find.text('0.0 g'), findsNothing);

    await _type(tester, '100');
    expect(find.text('300 kcal'), findsOneWidget);
    expect(find.text(missingNutrientPlaceholder), findsNWidgets(3));
  });

  testWidgets('a missing energy value shows as unknown, not 0 kcal', (
    tester,
  ) async {
    await _open(tester, _intake(kcal: null, fat: null));

    expect(find.text(missingNutrientPlaceholder), findsNWidgets(2));
    expect(find.textContaining('kcal'), findsNothing);
    expect(find.text('20.0 g'), findsOneWidget);
    expect(find.text('3.2 g'), findsOneWidget);
  });

  testWidgets('OK still returns the typed amount in grams', (tester) async {
    final result = await _open(tester, _intake(), imperial: true);

    await _type(tester, '2,5');
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(await result, closeTo(UnitCalc.ozToG(2.5), 1e-9));
  });

  testWidgets('Cancel returns nothing', (tester) async {
    final result = await _open(tester, _intake());

    await _type(tester, '60');
    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });

  for (final (textScale, stacked) in [(1.3, false), (1.31, true)]) {
    testWidgets(
      'the macros ${stacked ? 'stack' : 'sit side by side'} at ${textScale}x',
      (tester) async {
        await _open(tester, _intake(), textScale: textScale);

        final carbs = tester.getCenter(find.text(l10nEn.carbsLabel));
        final fat = tester.getCenter(find.text(l10nEn.fatLabel));
        expect(fat.dy > carbs.dy, stacked);
        expect(tester.takeException(), isNull);
      },
    );
  }

  // German has the longest macro label ("Kohlenhydrate"); at a large font
  // it must neither overflow nor wrap to a second line.
  for (final textScale in [1.0, 2.0]) {
    for (final size in [const Size(320, 568), const Size(411, 891)]) {
      testWidgets(
        'German at ${textScale}x text stays on one line on ${size.width} dp',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await _open(
            tester,
            _intake(amount: 1234.5),
            locale: const Locale('de'),
            textScale: textScale,
            kilojoules: true,
          );

          expect(tester.takeException(), isNull);
          // "Fett" is one line; the longer labels must be as tall as it.
          final oneLine = tester.getSize(find.text('Fett')).height;
          for (final label in ['Kohlenhydrate', 'Protein', '12913 kJ']) {
            expect(
              tester.getSize(find.text(label)).height,
              label == '12913 kJ' ? greaterThanOrEqualTo(oneLine) : oneLine,
              reason: label,
            );
          }
          expect(
            tester.getSize(find.text('12913 kJ')).height,
            lessThan(oneLine * 2),
          );
        },
      );
    }
  }
}
