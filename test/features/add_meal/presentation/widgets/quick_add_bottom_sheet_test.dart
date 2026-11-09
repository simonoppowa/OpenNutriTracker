import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/presentation/log_tray.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/quick_add_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

// #705: Quick Add takes an optional weight. Without one the values are
// fixed totals; with one they are totals for that weight, stored per
// 100 g so the amount can be changed later from the real basis.

Finder _field(String id) => find.descendant(
  of: find.bySemanticsIdentifier(id),
  matching: find.byType(TextField),
);

Future<LogTray> _openSheet(WidgetTester tester, {bool kj = false}) async {
  final tray = LogTray();
  addTearDown(tray.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<EnergyUnitProvider>(
      create: (_) => EnergyUnitProvider(usesKilojoules: kj),
      child: MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => QuickAddBottomSheet(
                  intakeType: IntakeTypeEntity.lunch,
                  day: DateTime(2026, 11, 9),
                  logTray: tray,
                  addsToListOnly: true,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return tray;
}

Future<void> _fill(
  WidgetTester tester, {
  String title = 'Canteen lunch',
  String energy = '640',
  String? carbs,
  String? fat,
  String? protein,
  String? weight,
}) async {
  await tester.enterText(_field('quick-add-title'), title);
  await tester.enterText(_field('quick-add-energy'), energy);
  if (carbs != null) await tester.enterText(_field('quick-add-carbs'), carbs);
  if (fat != null) await tester.enterText(_field('quick-add-fat'), fat);
  if (protein != null) {
    await tester.enterText(_field('quick-add-protein'), protein);
  }
  if (weight != null) {
    await tester.enterText(_field('quick-add-weight'), weight);
  }
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.bySemanticsIdentifier('quick-add-submit'));
  await tester.pumpAndSettle();
}

bool _submitEnabled(WidgetTester tester) => tester
    .widget<FilledButton>(
      find.descendant(
        of: find.bySemanticsIdentifier('quick-add-submit'),
        matching: find.byType(FilledButton),
      ),
    )
    .enabled;

IntakeEntity _asIntake(LogTrayItem item, {double? amount}) => IntakeEntity(
  id: 'x',
  unit: item.unit,
  amount: amount ?? item.amount,
  type: IntakeTypeEntity.lunch,
  meal: item.meal,
  dateTime: DateTime(2026, 11, 9),
);

void main() {
  testWidgets('the weight field is there, optional and labelled', (
    tester,
  ) async {
    await _openSheet(tester);
    expect(_field('quick-add-weight'), findsOneWidget);
    expect(find.text(l10nEn.quickAddWeightHint), findsOneWidget);
  });

  group('without a weight', () {
    testWidgets('the values are fixed totals with no g/ml', (tester) async {
      final tray = await _openSheet(tester);
      await _fill(tester, carbs: '70', fat: '22', protein: '31');
      await _submit(tester);

      final item = tray.items.single;
      expect(item.amountLabel, l10nEn.quickAddCardLabel);
      expect(item.canChangeAmount, isFalse);
      final intake = _asIntake(item);
      expect(intake.hasFixedTotals, isTrue);
      expect(intake.totalKcal, closeTo(640, 1e-9));
      expect(intake.totalCarbsGram, closeTo(70, 1e-9));
      expect(intake.totalFatsGram, closeTo(22, 1e-9));
      expect(intake.totalProteinsGram, closeTo(31, 1e-9));
    });

    testWidgets('an empty weight (spaces only) counts as no weight', (
      tester,
    ) async {
      final tray = await _openSheet(tester);
      await _fill(tester, weight: '  ');
      expect(_submitEnabled(tester), isTrue);
      await _submit(tester);
      expect(_asIntake(tray.items.single).hasFixedTotals, isTrue);
    });
  });

  group('with a weight', () {
    testWidgets('the values are totals for that weight, rescalable', (
      tester,
    ) async {
      final tray = await _openSheet(tester);
      await _fill(tester, carbs: '70', fat: '22', protein: '31', weight: '320');
      await _submit(tester);

      final item = tray.items.single;
      expect(item.unit, 'g');
      expect(item.amount, 320);
      expect(item.amountLabel, '320 g');
      expect(item.meal.mealUnit, 'g');
      expect(item.meal.fixedTotals, isFalse);

      final logged = _asIntake(item);
      expect(logged.hasFixedTotals, isFalse);
      expect(logged.totalKcal, closeTo(640, 1e-9));
      expect(logged.totalCarbsGram, closeTo(70, 1e-9));
      expect(logged.totalFatsGram, closeTo(22, 1e-9));
      expect(logged.totalProteinsGram, closeTo(31, 1e-9));

      // Changing the amount scales from the real 320 g, not from 100 g.
      final half = _asIntake(item, amount: 160);
      expect(half.totalKcal, closeTo(320, 1e-9));
      expect(half.totalCarbsGram, closeTo(35, 1e-9));
      expect(half.totalFatsGram, closeTo(11, 1e-9));
      expect(half.totalProteinsGram, closeTo(15.5, 1e-9));
    });

    testWidgets('macros left out stay unknown', (tester) async {
      final tray = await _openSheet(tester);
      await _fill(tester, weight: '250');
      await _submit(tester);

      final n = tray.items.single.meal.nutriments;
      expect(n.energyKcal100, closeTo(256, 1e-9));
      expect(n.carbohydrates100, isNull);
      expect(n.fat100, isNull);
      expect(n.proteins100, isNull);
    });

    testWidgets('a decimal comma is read as a decimal point', (tester) async {
      final tray = await _openSheet(tester);
      await _fill(tester, weight: '312,5');
      await _submit(tester);
      expect(tray.items.single.amount, 312.5);
      expect(_asIntake(tray.items.single).totalKcal, closeTo(640, 1e-9));
    });

    testWidgets('energy typed in kJ is converted before scaling', (
      tester,
    ) async {
      final tray = await _openSheet(tester, kj: true);
      await _fill(tester, energy: '2000', weight: '200');
      await _submit(tester);
      // 2000 kJ is 478.01 kcal, for the whole 200 g.
      expect(_asIntake(tray.items.single).totalKcal, closeTo(478.01, 0.01));
    });
  });

  group('an invalid weight blocks the entry', () {
    for (final weight in ['0', '0.0', '-50', '.', 'NaN', 'Infinity']) {
      testWidgets('"$weight"', (tester) async {
        final tray = await _openSheet(tester);
        await _fill(tester, weight: weight);

        expect(_submitEnabled(tester), isFalse);
        expect(find.text(l10nEn.quickAddWeightInvalid), findsOneWidget);
        await _submit(tester);
        expect(tray.items, isEmpty);
      });
    }

    testWidgets('an energy of NaN or Infinity blocks the entry too', (
      tester,
    ) async {
      final tray = await _openSheet(tester);
      for (final energy in ['NaN', 'Infinity']) {
        await _fill(tester, energy: energy, weight: '200');
        expect(_submitEnabled(tester), isFalse, reason: energy);
      }
      await _submit(tester);
      expect(tray.items, isEmpty);
    });

    testWidgets('clearing it again allows a fixed total', (tester) async {
      final tray = await _openSheet(tester);
      await _fill(tester, weight: '0');
      expect(_submitEnabled(tester), isFalse);

      await tester.enterText(_field('quick-add-weight'), '');
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.quickAddWeightInvalid), findsNothing);
      await _submit(tester);
      expect(_asIntake(tray.items.single).hasFixedTotals, isTrue);
    });
  });
}
