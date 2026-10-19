import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

IntakeEntity _intake(String id, {double? fiber, double? sodium}) =>
    IntakeEntity(
      id: id,
      unit: 'g',
      amount: 100,
      type: IntakeTypeEntity.breakfast,
      dateTime: DateTime(2026, 10, 19),
      meal: MealEntity(
        code: id,
        name: id,
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: 'g',
        servingSize: null,
        source: MealSourceEntity.custom,
        nutriments: MealNutrimentsEntity(
          energyKcal100: 100,
          carbohydrates100: 0,
          fat100: 0,
          proteins100: 0,
          sugars100: null,
          saturatedFat100: null,
          fiber100: fiber,
          sodium100: sodium,
        ),
      ),
    );

void main() {
  group('coverage of the panel totals (#46)', () {
    test('a nutrient no entry knows is unknown, not 0', () {
      final totals = NutrientPanelTotals.fromIntakes([
        _intake('a', fiber: 3),
        _intake('b', fiber: 2),
      ]);

      expect(totals.coverage[NutrientPanelKeys.sodium]!.isUnknown, isTrue);
      expect(totals.coverage[NutrientPanelKeys.fiber]!.isUnknown, isFalse);
      expect(totals.fiberG, 5);
    });

    test('a nutrient some entries know is a lower bound', () {
      final totals = NutrientPanelTotals.fromIntakes([
        _intake('a', sodium: 400),
        _intake('b'),
      ]);

      final sodium = totals.coverage[NutrientPanelKeys.sodium]!;
      expect(sodium.isPartial, isTrue);
      expect(sodium.unknownEntries, 1);
      expect(totals.sodiumMg, 400);
    });

    test('every panel key has a coverage entry', () {
      final totals = NutrientPanelTotals.fromIntakes(const []);

      expect(totals.coverage.keys.toSet(), NutrientPanelKeys.all.toSet());
    });
  });

  testWidgets('the panel says unknown and at least', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: SingleChildScrollView(
            child: DailyNutrientPanel(
              intakes: [_intake('a', sodium: 400), _intake('b', fiber: 3)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('${l10nEn.nutrientUnknownLabel} / '),
      findsWidgets,
    );
    expect(find.textContaining('≥ 400 / '), findsOneWidget);
    expect(find.text(l10nEn.nutrientPartialHint(1)), findsWidgets);
  });
}
