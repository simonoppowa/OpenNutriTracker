import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

// #1361: the "Show Micronutrients" switch must hide the section when it
// is off, including for a food that carries micronutrient data.

const _withMicros = MealNutrimentsEntity(
  energyKcal100: 539,
  carbohydrates100: 57.5,
  fat100: 30.9,
  proteins100: 6.3,
  sugars100: 56.3,
  saturatedFat100: 10.6,
  fiber100: 0,
  sodium100: 0.041,
  calcium100: 0.108,
);

const _withoutMicros = MealNutrimentsEntity(
  energyKcal100: 100,
  carbohydrates100: 10,
  fat100: 5,
  proteins100: 5,
  sugars100: 2,
  saturatedFat100: 1,
  fiber100: 1,
);

MealEntity _meal(MealNutrimentsEntity nutriments) => MealEntity(
  code: 'nutriments-table-test',
  name: 'Test product',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: nutriments,
  source: MealSourceEntity.off,
);

Future<void> _pump(
  WidgetTester tester, {
  required MealNutrimentsEntity nutriments,
  required bool showMicronutrients,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(),
      child: MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MealDetailNutrimentsTable(
              product: _meal(nutriments),
              usesImperialUnits: false,
              showMicronutrients: showMicronutrients,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MealDetailNutrimentsTable micronutrient section (#1361)', () {
    testWidgets('off hides the section for a food with micronutrient data', (
      tester,
    ) async {
      await _pump(tester, nutriments: _withMicros, showMicronutrients: false);

      expect(find.text(l10nEn.micronutrientsLabel), findsNothing);
      expect(find.textContaining(l10nEn.sodiumLabel), findsNothing);
    });

    testWidgets('off hides the section for a food without data', (
      tester,
    ) async {
      await _pump(
        tester,
        nutriments: _withoutMicros,
        showMicronutrients: false,
      );

      expect(find.text(l10nEn.micronutrientsLabel), findsNothing);
    });

    testWidgets('on shows the section expanded when the food has data', (
      tester,
    ) async {
      await _pump(tester, nutriments: _withMicros, showMicronutrients: true);

      expect(find.text(l10nEn.micronutrientsLabel), findsOneWidget);
      expect(find.textContaining(l10nEn.sodiumLabel), findsOneWidget);
    });

    testWidgets('on shows the section collapsed when the food has none', (
      tester,
    ) async {
      await _pump(tester, nutriments: _withoutMicros, showMicronutrients: true);

      expect(find.text(l10nEn.micronutrientsLabel), findsOneWidget);
      expect(find.textContaining(l10nEn.sodiumLabel), findsNothing);
    });
  });
}
