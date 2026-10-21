import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_total.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/recipe_nutrients_table.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// 1000 g: energy known for all three ingredients (2300 kcal), iron for two
/// (29.4 mg), zinc for none.
final _coverage = {
  for (final field in NutrientField.values)
    field: switch (field) {
      NutrientField.energyKcal => const NutrientTotal(
        sum: 2300,
        knownEntries: 3,
        unknownEntries: 0,
      ),
      NutrientField.iron => const NutrientTotal(
        sum: 29.4,
        knownEntries: 2,
        unknownEntries: 1,
      ),
      _ => const NutrientTotal(sum: 0, knownEntries: 0, unknownEntries: 3),
    },
};

Future<void> _pump(
  WidgetTester tester, {
  int? servingsCount,
  bool showMicronutrients = true,
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
            child: RecipeNutrientsTable(
              coverage: _coverage,
              totalWeightG: 1000,
              servingsCount: servingsCount,
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
  testWidgets('a value some ingredients lack reads "at least"', (tester) async {
    await _pump(tester, servingsCount: 4);

    expect(find.text('≥ 2.94mg'), findsOneWidget);
    expect(find.text('≥ 7.35mg'), findsOneWidget);
    expect(find.text('1 ingredient without a value'), findsOneWidget);
  });

  testWidgets('a value no ingredient has reads as a dash', (tester) async {
    await _pump(tester);

    expect(find.text('zinc'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
    expect(find.text('≥ 2.94mg'), findsOneWidget);
  });

  testWidgets('fully known values carry no mark', (tester) async {
    await _pump(tester, servingsCount: 4);

    expect(find.text('230 kcal'), findsOneWidget);
    expect(find.text('575 kcal'), findsOneWidget);
  });

  testWidgets('the portion column needs portions', (tester) async {
    await _pump(tester, servingsCount: 4);
    expect(find.text('Per serving (250 g)'), findsWidgets);

    await _pump(tester);
    expect(find.text('Per serving (250 g)'), findsNothing);
    expect(find.text('Per 100 g'), findsWidgets);
  });

  testWidgets('the micronutrients follow the setting', (tester) async {
    await _pump(tester, showMicronutrients: false);

    expect(find.text('zinc'), findsNothing);
    expect(find.text('230 kcal'), findsOneWidget);
  });
}
