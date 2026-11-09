import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

// #705: how a logged Quick Add entry reads on its card, and whether
// tapping it lets the amount be changed.

/// A Quick Add entry as it is stored: per 100 g/ml, logged at [amount].
IntakeEntity _quickAdd({
  bool fixedTotals = false,
  double amount = 100,
  String unit = 'g',
  String mealUnit = 'gml',
  double kcal100 = 640,
}) => IntakeEntity(
  id: 'quick-add-card',
  unit: unit,
  amount: amount,
  type: IntakeTypeEntity.lunch,
  dateTime: DateTime(2026, 11, 9, 12),
  meal: MealEntity(
    code: 'quick-add-card-meal',
    name: 'Canteen lunch',
    url: null,
    mealQuantity: amount.toString(),
    mealUnit: mealUnit,
    servingQuantity: null,
    servingUnit: mealUnit,
    servingSize: '',
    nutriments: MealNutrimentsEntity(
      energyKcal100: kcal100,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: MealSourceEntity.custom,
    fixedTotals: fixedTotals,
  ),
);

/// Weighed at 320 g for 640 kcal: 200 kcal per 100 g.
IntakeEntity _weighed() => _quickAdd(amount: 320, mealUnit: 'g', kcal100: 200);

Future<List<IntakeEntity>> _pumpCard(
  WidgetTester tester,
  IntakeEntity intake,
) async {
  final tapped = <IntakeEntity>[];
  await tester.pumpWidget(
    ChangeNotifierProvider<EnergyUnitProvider>(
      create: (_) => EnergyUnitProvider(),
      child: MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: IntakeCard(
            key: const ValueKey('card'),
            intake: intake,
            onItemTapped: (_, intake, _) => tapped.add(intake),
            firstListElement: false,
            usesImperialUnits: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tapped;
}

void main() {
  group('a Quick Add without a weight', () {
    testWidgets('shows no g/ml, only that it is a Quick Add', (tester) async {
      await _pumpCard(tester, _quickAdd(fixedTotals: true));
      expect(find.text('640 kcal'), findsOneWidget);
      expect(find.textContaining('g/ml'), findsNothing);
      expect(find.textContaining('100'), findsNothing);
      expect(find.text(l10nEn.quickAddCardLabel), findsOneWidget);
    });

    testWidgets('tapping it says why instead of opening the amount', (
      tester,
    ) async {
      final tapped = await _pumpCard(tester, _quickAdd(fixedTotals: true));
      await tester.tap(find.text('Canteen lunch'));
      await tester.pump();

      expect(tapped, isEmpty);
      expect(find.text(l10nEn.quickAddFixedTotalsSnack), findsOneWidget);
    });
  });

  group('a Quick Add with a weight', () {
    testWidgets('shows the real weight', (tester) async {
      await _pumpCard(tester, _weighed());
      expect(find.text('320 g'), findsOneWidget);
      expect(find.text('640 kcal'), findsOneWidget);
    });

    testWidgets('tapping it opens the amount, as for any food', (tester) async {
      final tapped = await _pumpCard(tester, _weighed());
      await tester.tap(find.text('Canteen lunch'));
      await tester.pump();
      expect(tapped, hasLength(1));
      expect(find.text(l10nEn.quickAddFixedTotalsSnack), findsNothing);
    });

    testWidgets('the edit dialog starts from the real weight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: EditDialog(
              intakeEntity: _weighed(),
              usesImperialUnits: false,
            ),
          ),
        ),
      );
      expect(find.text('320.00'), findsOneWidget);
      expect(find.text('g'), findsOneWidget);
    });
  });

  group('an entry stored before #705', () {
    testWidgets('keeps its 100 g/ml and stays editable', (tester) async {
      final tapped = await _pumpCard(tester, _quickAdd());
      expect(find.text('100 ${l10nEn.gramMilliliterUnit}'), findsOneWidget);
      expect(find.text('640 kcal'), findsOneWidget);

      await tester.tap(find.text('Canteen lunch'));
      await tester.pump();
      expect(tapped, hasLength(1));
    });
  });

  testWidgets('a flagged meal logged at another amount shows that amount', (
    tester,
  ) async {
    // Re-logged from Recents at 250 g/ml: its totals are scaled, so the
    // amount stays visible and editable.
    final tapped = await _pumpCard(
      tester,
      _quickAdd(fixedTotals: true, amount: 250),
    );
    expect(find.text('250 ${l10nEn.gramMilliliterUnit}'), findsOneWidget);
    expect(find.text('1600 kcal'), findsOneWidget);
    await tester.tap(find.text('Canteen lunch'));
    await tester.pump();
    expect(tapped, hasLength(1));
  });
}
