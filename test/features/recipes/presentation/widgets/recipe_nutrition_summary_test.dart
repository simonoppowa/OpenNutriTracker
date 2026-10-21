import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/recipe_nutrition_summary.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// 1000 g with 230 kcal, 30 g carbs, 5 g fat and 8 g protein per 100 g.
final _per100 = MealNutrimentsEntity(
  energyKcal100: 230,
  carbohydrates100: 30,
  fat100: 5,
  proteins100: 8,
  sugars100: null,
  saturatedFat100: null,
  fiber100: null,
);

Future<void> _pump(
  WidgetTester tester, {
  int? servingsCount,
  bool kilojoules = false,
}) async {
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
          body: RecipeNutritionSummary(
            nutrimentsPer100: _per100,
            totalWeightG: 1000,
            servingsCount: servingsCount,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with portions it shows the values per portion', (tester) async {
    await _pump(tester, servingsCount: 4);

    final line = find.textContaining('Per serving (250 g)');
    expect(line, findsOneWidget);
    final text = tester.widget<Text>(line).data!;
    expect(text, contains('575 kcal'));
    expect(text, contains('75.0g'));
    expect(text, contains('12.5g'));
    expect(text, contains('20.0g'));
    expect(find.textContaining('Per 100 g'), findsOneWidget);
  });

  testWidgets('without portions there is no portion line', (tester) async {
    await _pump(tester);

    expect(find.textContaining('Per serving'), findsNothing);
    expect(find.textContaining('Per 100 g'), findsOneWidget);
  });

  testWidgets('zero portions count as none', (tester) async {
    await _pump(tester, servingsCount: 0);

    expect(find.textContaining('Per serving'), findsNothing);
  });

  testWidgets('with kJ the portion energy is in kJ', (tester) async {
    await _pump(tester, servingsCount: 4, kilojoules: true);

    final text = tester
        .widget<Text>(find.textContaining('Per serving (250 g)'))
        .data!;
    expect(text, contains('2406 kJ'));
  });
}
