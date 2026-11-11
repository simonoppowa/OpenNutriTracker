import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/food_emoji_resolver.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

IntakeEntity _intake(String name, MealSourceEntity source) => IntakeEntity(
  id: 'test',
  unit: 'g',
  amount: 100,
  type: IntakeTypeEntity.breakfast,
  dateTime: DateTime(2026, 1, 1),
  meal: MealEntity(
    code: 'meal',
    name: name,
    url: null,
    mealQuantity: '100',
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: '100 g',
    nutriments: MealNutrimentsEntity(
      energyKcal100: 42,
      carbohydrates100: 5,
      fat100: 1,
      proteins100: 3,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: source,
  ),
);

Widget _card(IntakeEntity intake) => ChangeNotifierProvider<EnergyUnitProvider>(
  create: (_) => EnergyUnitProvider(),
  child: MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: IntakeCard(
        key: const ValueKey('card'),
        intake: intake,
        firstListElement: false,
        usesImperialUnits: false,
      ),
    ),
  ),
);

void main() {
  // The FDC description the search list already resolves to 🥛.
  const milk = 'Milk, fluid, nonfat';

  group('IntakeCard thumbnail emoji (#1288)', () {
    testWidgets('an FDC food without an image shows the search emoji', (
      tester,
    ) async {
      final emoji = resolveFoodEmoji(milk);
      expect(emoji, isNotNull, reason: 'fixture must resolve to an emoji');

      await tester.pumpWidget(_card(_intake(milk, MealSourceEntity.fdc)));
      await tester.pump();

      expect(find.text(emoji!), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_rounded), findsNothing);
    });

    testWidgets('a branded OFF product keeps the food icon', (tester) async {
      await tester.pumpWidget(_card(_intake(milk, MealSourceEntity.off)));
      await tester.pump();

      expect(find.text(resolveFoodEmoji(milk)!), findsNothing);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });

    testWidgets('an FDC food with no emoji match keeps the food icon', (
      tester,
    ) async {
      const name = 'Zzyzx, unmatched';
      expect(resolveFoodEmoji(name), isNull);

      await tester.pumpWidget(_card(_intake(name, MealSourceEntity.fdc)));
      await tester.pump();

      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });
  });
}
