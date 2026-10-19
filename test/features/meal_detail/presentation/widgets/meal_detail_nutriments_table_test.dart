import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

MealEntity _meal({String unit = 'g'}) => MealEntity(
  code: 'skyr',
  name: 'Skyr',
  url: null,
  mealQuantity: null,
  mealUnit: unit,
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 60,
    carbohydrates100: 4,
    fat100: null,
    proteins100: 11,
    sugars100: null,
    saturatedFat100: 0.1,
    fiber100: null,
    calcium100: 150,
  ),
  source: MealSourceEntity.off,
);

Future<void> _pump(
  WidgetTester tester,
  MealEntity meal, {
  bool showMicronutrients = false,
  double? selectedAmountG,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(),
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
            child: MealDetailNutrimentsTable(
              product: meal,
              usesImperialUnits: false,
              showMicronutrients: showMicronutrients,
              selectedAmountG: selectedAmountG,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a missing value shows as a dash, not as 0', (tester) async {
    await _pump(tester, _meal());

    expect(find.text(l10nEn.fatLabel), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('0.0g'), findsNothing);
    expect(find.text('11.0g'), findsOneWidget);
  });

  testWidgets('every value is also shown for the chosen amount', (
    tester,
  ) async {
    await _pump(tester, _meal(), selectedAmountG: 250);

    expect(
      find.text(l10nEn.nutritionForAmountLabel('250.0 g')),
      findsOneWidget,
    );
    expect(find.text('60 ${l10nEn.kcalLabel}'), findsOneWidget);
    expect(find.text('150 ${l10nEn.kcalLabel}'), findsOneWidget);
    expect(find.text('27.5g'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(6));
  });

  testWidgets('a liquid names the amount in ml', (tester) async {
    await _pump(tester, _meal(unit: 'ml'), selectedAmountG: 330);

    expect(
      find.text(l10nEn.nutritionForAmountLabel('330.0 ml')),
      findsOneWidget,
    );
  });

  testWidgets('100 g needs no second column', (tester) async {
    await _pump(tester, _meal(), selectedAmountG: 100);

    expect(find.text(l10nEn.nutritionForAmountLabel('100.0 g')), findsNothing);
  });

  testWidgets('micronutrients follow the setting', (tester) async {
    await _pump(tester, _meal());
    expect(find.text(l10nEn.micronutrientsLabel), findsNothing);

    await _pump(tester, _meal(), showMicronutrients: true);
    expect(find.text(l10nEn.micronutrientsLabel), findsOneWidget);
    expect(find.text('150.0mg'), findsOneWidget);
    expect(find.text(l10nEn.ironLabel), findsOneWidget);
  });
}
