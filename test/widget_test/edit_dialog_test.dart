import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../helpers/test_l10n.dart';

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

void main() {
  late Future<double?> result;
  late bool closed;

  /// Opens the dialog; [result] completes with what it pops with.
  Future<void> open(WidgetTester tester) async {
    closed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              result = showDialog<double>(
                context: context,
                builder: (_) =>
                    EditDialog(intakeEntity: _intake, usesImperialUnits: false),
              );
              result.whenComplete(() => closed = true);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Delete returns the delete result', (tester) async {
    await open(tester);

    await tester.tap(find.bySemanticsIdentifier('edit-item-delete'));
    await tester.pumpAndSettle();

    expect(await result, EditDialog.deleteResult);
  });

  testWidgets('Delete sits alone on the left, Cancel and OK on the right', (
    tester,
  ) async {
    await open(tester);

    final delete = tester.getCenter(find.text(l10nEn.dialogDeleteLabel));
    final cancel = tester.getCenter(find.text(l10nEn.dialogCancelLabel));
    final ok = tester.getCenter(find.text(l10nEn.dialogOKLabel));
    expect(delete.dx, lessThan(cancel.dx));
    expect(cancel.dx, lessThan(ok.dx));
    // The gap is between Delete and the pair, not inside the pair.
    expect(cancel.dx - delete.dx, greaterThan(ok.dx - cancel.dx));
  });

  testWidgets('OK returns the new amount', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextFormField), '150');
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(await result, 150);
  });

  for (final amount in ['0', '0.00']) {
    testWidgets('OK refuses an amount of $amount', (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextFormField), amount);
      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(closed, isFalse);
      expect(find.byType(EditDialog), findsOneWidget);
    });
  }

  testWidgets('Cancel returns nothing', (tester) async {
    await open(tester);

    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });
}
