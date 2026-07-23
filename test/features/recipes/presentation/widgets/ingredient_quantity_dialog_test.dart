import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/ingredient_quantity_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

MealEntity _solidMeal() => MealEntity(
      code: 'flour',
      name: 'Flour',
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.off,
    );

Widget _wrap({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('returns selection on confirm', (tester) async {
    IngredientQuantitySelection? captured;

    await tester.pumpWidget(_wrap(
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                captured = await showIngredientQuantityDialog(
                  context,
                  meal: _solidMeal(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Default amount is 0; type 150 and confirm with the Add button.
    await tester.enterText(find.byType(TextFormField).first, '150');
    // The confirm button label is the localized addLabel ("Add").
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.amount, 150);
    // Default unit for a solid meal without serving values is 'g'.
    expect(captured!.unit, 'g');
  });

  testWidgets('returns null when amount is invalid', (tester) async {
    IngredientQuantitySelection? captured = const IngredientQuantitySelection(
      amount: -1,
      unit: 'sentinel',
    );

    await tester.pumpWidget(_wrap(
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                captured = await showIngredientQuantityDialog(
                  context,
                  meal: _solidMeal(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Don't enter anything; just tap Add.
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(captured, isNull);
  });
}
