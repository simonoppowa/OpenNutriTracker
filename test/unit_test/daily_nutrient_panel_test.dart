import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';

/// Convenience builder for a `MealEntity` carrying a specific micronutrient
/// profile. All fields default to zero so each test only has to spell out
/// the nutrients it cares about.
MealEntity _meal({
  double? fiber,
  double? sodium,
  double? saturatedFat,
  double? sugars,
  double? calcium,
  double? iron,
  double? potassium,
  double? vitaminD,
  double? vitaminB12,
  double? magnesium,
}) {
  return MealEntity(
    code: 'test',
    name: 'test meal',
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
      sugars100: sugars,
      saturatedFat100: saturatedFat,
      fiber100: fiber,
      sodium100: sodium,
      potassium100: potassium,
      magnesium100: magnesium,
      calcium100: calcium,
      iron100: iron,
      vitaminD100: vitaminD,
      vitaminB12100: vitaminB12,
    ),
  );
}

IntakeEntity _intake({
  required double amountGrams,
  required MealEntity meal,
  DateTime? at,
}) {
  return IntakeEntity(
    id: 'i-${meal.code}-${amountGrams.toString()}',
    unit: 'g',
    amount: amountGrams,
    type: IntakeTypeEntity.breakfast,
    meal: meal,
    dateTime: at ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('NutrientPanelTotals.fromIntakes — day view', () {
    test('aggregates three sample intakes for every surfaced nutrient', () {
      // Three foods, each carrying a slice of the nutrients we surface. The
      // expected totals are amount × (value100 / 100) summed across foods.
      final intakes = <IntakeEntity>[
        _intake(
          amountGrams: 200,
          meal: _meal(
            fiber: 5,
            sodium: 400,
            saturatedFat: 1.0,
            sugars: 6,
            calcium: 120,
            iron: 1.5,
            potassium: 350,
            vitaminD: 2.5,
            vitaminB12: 0.8,
            magnesium: 40,
          ),
        ),
        _intake(
          amountGrams: 150,
          meal: _meal(
            fiber: 8,
            sodium: 200,
            saturatedFat: 4.0,
            sugars: 10,
            calcium: 80,
            iron: 2.0,
            potassium: 600,
            vitaminD: 5.0,
            vitaminB12: 1.2,
            magnesium: 60,
          ),
        ),
        _intake(
          amountGrams: 100,
          meal: _meal(
            fiber: 2,
            sodium: 50,
            saturatedFat: 0.5,
            sugars: 1,
            calcium: 200,
            iron: 0.5,
            potassium: 100,
            vitaminD: 1.0,
            vitaminB12: 0.4,
            magnesium: 20,
          ),
        ),
      ];

      final totals = NutrientPanelTotals.fromIntakes(intakes);

      // fiber: 200×5/100 + 150×8/100 + 100×2/100 = 10 + 12 + 2 = 24
      expect(totals.fiberG, closeTo(24.0, 1e-9));
      // sodium: 200×400/100 + 150×200/100 + 100×50/100 = 800 + 300 + 50 = 1150
      expect(totals.sodiumMg, closeTo(1150.0, 1e-9));
      // saturated fat: 200×1.0/100 + 150×4.0/100 + 100×0.5/100 = 2 + 6 + 0.5 = 8.5
      expect(totals.saturatedFatG, closeTo(8.5, 1e-9));
      // sugars: 200×6/100 + 150×10/100 + 100×1/100 = 12 + 15 + 1 = 28
      expect(totals.sugarG, closeTo(28.0, 1e-9));
      // calcium: 200×120/100 + 150×80/100 + 100×200/100 = 240 + 120 + 200 = 560
      expect(totals.calciumMg, closeTo(560.0, 1e-9));
      // iron: 200×1.5/100 + 150×2.0/100 + 100×0.5/100 = 3 + 3 + 0.5 = 6.5
      expect(totals.ironMg, closeTo(6.5, 1e-9));
      // potassium: 200×350/100 + 150×600/100 + 100×100/100 = 700 + 900 + 100 = 1700
      expect(totals.potassiumMg, closeTo(1700.0, 1e-9));
      // vitamin D: 200×2.5/100 + 150×5.0/100 + 100×1.0/100 = 5 + 7.5 + 1 = 13.5
      expect(totals.vitaminDMcg, closeTo(13.5, 1e-9));
      // vitamin B12: 200×0.8/100 + 150×1.2/100 + 100×0.4/100 = 1.6 + 1.8 + 0.4 = 3.8
      expect(totals.vitaminB12Mcg, closeTo(3.8, 1e-9));
      // magnesium: 200×40/100 + 150×60/100 + 100×20/100 = 80 + 90 + 20 = 190
      expect(totals.magnesiumMg, closeTo(190.0, 1e-9));
    });

    test('treats null nutrient values as zero', () {
      final intakes = [
        _intake(amountGrams: 100, meal: _meal(fiber: 4)),
        _intake(amountGrams: 100, meal: _meal()),
      ];

      final totals = NutrientPanelTotals.fromIntakes(intakes);

      expect(totals.fiberG, closeTo(4.0, 1e-9));
      expect(totals.sodiumMg, 0.0);
      expect(totals.vitaminDMcg, 0.0);
    });
  });

  group('NutrientPanelTotals.fromIntakes — week view', () {
    test('divides every total by 7 to land on a daily average', () {
      // Three days' worth of sample intakes, lumped into a single list (the
      // panel does the same — it pre-fetches the 7-day window and hands the
      // flattened list to the totals helper).
      final intakes = <IntakeEntity>[
        // Day 1
        _intake(
          amountGrams: 200,
          meal: _meal(fiber: 7, iron: 2.0, magnesium: 50, vitaminD: 4.0),
          at: DateTime(2026, 1, 1),
        ),
        // Day 2
        _intake(
          amountGrams: 100,
          meal: _meal(fiber: 5, iron: 3.0, magnesium: 80, vitaminD: 7.0),
          at: DateTime(2026, 1, 2),
        ),
        // Day 3
        _intake(
          amountGrams: 50,
          meal: _meal(fiber: 8, iron: 4.0, magnesium: 60, vitaminD: 10.0),
          at: DateTime(2026, 1, 3),
        ),
      ];

      final totals = NutrientPanelTotals.fromIntakes(intakes, weekly: true);

      // fiber sum: 200×7/100 + 100×5/100 + 50×8/100 = 14 + 5 + 4 = 23
      // weekly average: 23 / 7 ≈ 3.2857
      expect(totals.fiberG, closeTo(23.0 / 7.0, 1e-9));
      // iron sum: 200×2.0/100 + 100×3.0/100 + 50×4.0/100 = 4 + 3 + 2 = 9
      expect(totals.ironMg, closeTo(9.0 / 7.0, 1e-9));
      // magnesium sum: 200×50/100 + 100×80/100 + 50×60/100 = 100 + 80 + 30 = 210
      expect(totals.magnesiumMg, closeTo(210.0 / 7.0, 1e-9));
      // vitamin D sum: 200×4.0/100 + 100×7.0/100 + 50×10.0/100 = 8 + 7 + 5 = 20
      expect(totals.vitaminDMcg, closeTo(20.0 / 7.0, 1e-9));
    });

    test('empty week window yields zeros, not NaN', () {
      final totals = NutrientPanelTotals.fromIntakes(<IntakeEntity>[],
          weekly: true);
      expect(totals.fiberG, 0.0);
      expect(totals.ironMg, 0.0);
      expect(totals.vitaminB12Mcg, 0.0);
    });
  });

  group('ConfigEntity.isNutrientVisible', () {
    /// A minimal config — most fields don't matter for visibility behaviour.
    ConfigEntity withVisibility(Map<String, bool> v) => ConfigEntity(
          false,
          false,
          false,
          AppThemeEntity.system,
          nutrientPanelVisibility: v,
        );

    test('defaults to visible when the map is empty', () {
      final config = withVisibility(const {});
      for (final key in NutrientPanelKeys.all) {
        expect(config.isNutrientVisible(key), isTrue, reason: 'key=$key');
      }
    });

    test('honours explicit false overrides', () {
      final config = withVisibility(const {
        NutrientPanelKeys.vitaminD: false,
        NutrientPanelKeys.magnesium: false,
      });
      expect(config.isNutrientVisible(NutrientPanelKeys.vitaminD), isFalse);
      expect(config.isNutrientVisible(NutrientPanelKeys.magnesium), isFalse);
      // Unrelated keys still default to visible.
      expect(config.isNutrientVisible(NutrientPanelKeys.iron), isTrue);
      expect(config.isNutrientVisible(NutrientPanelKeys.fiber), isTrue);
    });

    test('honours explicit true overrides as a no-op', () {
      final config = withVisibility(const {
        NutrientPanelKeys.iron: true,
      });
      expect(config.isNutrientVisible(NutrientPanelKeys.iron), isTrue);
    });
  });

  group('NutrientPanelKeys', () {
    test('exposes all ten nutrient identifiers', () {
      expect(NutrientPanelKeys.all, hasLength(10));
      expect(
        NutrientPanelKeys.all.toSet(),
        equals(<String>{
          NutrientPanelKeys.fiber,
          NutrientPanelKeys.sodium,
          NutrientPanelKeys.saturatedFat,
          NutrientPanelKeys.sugar,
          NutrientPanelKeys.calcium,
          NutrientPanelKeys.iron,
          NutrientPanelKeys.potassium,
          NutrientPanelKeys.vitaminD,
          NutrientPanelKeys.vitaminB12,
          NutrientPanelKeys.magnesium,
        }),
      );
    });
  });
}
