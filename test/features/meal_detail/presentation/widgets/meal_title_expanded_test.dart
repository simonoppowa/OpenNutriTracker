import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_title_expanded.dart';
import 'package:opennutritracker/generated/l10n.dart';

MealEntity _meal(MealSourceEntity source) => MealEntity(
  code: 'meal-title-test',
  name: 'Chili',
  url: null,
  mealQuantity: '1550.0',
  mealUnit: 'g',
  servingQuantity: 387.5,
  servingUnit: 'g',
  servingSize: '1 serving (387.5 g)',
  nutriments: MealNutrimentsEntity.empty(),
  source: source,
);

Future<void> _pump(WidgetTester tester, MealEntity meal) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: MealTitleExpanded(meal: meal, usesImperialUnits: false),
    ),
  ),
);

void main() {
  testWidgets('a recipe labels its weight as the whole recipe', (tester) async {
    await _pump(tester, _meal(MealSourceEntity.recipe));
    await tester.pumpAndSettle();

    expect(find.text('1550 g'), findsOneWidget);
    expect(find.text('Whole recipe'), findsOneWidget);
  });

  testWidgets('a food\'s package weight has no such label', (tester) async {
    await _pump(tester, _meal(MealSourceEntity.custom));
    await tester.pumpAndSettle();

    expect(find.text('Whole recipe'), findsNothing);
  });
}
