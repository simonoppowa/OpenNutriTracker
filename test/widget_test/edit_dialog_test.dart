import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

final _intake = IntakeEntity(
  id: 'i-1',
  unit: 'g',
  amount: 300,
  type: IntakeTypeEntity.lunch,
  meal: MealEntity(
    code: 'pelmeni',
    name: 'Pelmeni',
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    nutriments: MealNutrimentsEntity.empty(),
    source: MealSourceEntity.custom,
  ),
  dateTime: DateTime.utc(2026, 10, 22),
);

/// Opens the dialog and returns what it pops with, once a test closes it.
Future<Future<double?>> _open(WidgetTester tester) async {
  late Future<double?> result;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => result = showDialog<double>(
            context: context,
            builder: (_) =>
                EditDialog(intakeEntity: _intake, usesImperialUnits: false),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

String _amountShown(WidgetTester tester) => tester
    .widget<TextFormField>(find.byType(TextFormField).first)
    .controller!
    .text;

void main() {
  testWidgets('a fraction left over takes that share off the amount', (
    tester,
  ) async {
    final result = await _open(tester);

    await tester.tap(find.text('⅓'));
    await tester.pump();

    expect(_amountShown(tester), '200.00');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await result, 200);
  });

  testWidgets('an amount left over is subtracted as it is typed', (
    tester,
  ) async {
    final result = await _open(tester);

    await tester.enterText(find.byType(TextFormField).last, '120');
    await tester.pump();

    expect(_amountShown(tester), '180.00');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await result, 180);
  });

  testWidgets('more left over than was logged changes nothing', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextFormField).last, '400');
    await tester.pump();

    expect(_amountShown(tester), '300.00');
  });
}
