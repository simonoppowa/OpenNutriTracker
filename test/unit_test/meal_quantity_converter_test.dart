import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/util/meal_quantity_converter.dart';

MealEntity meal({double? servingQuantity, double? energyKcal100}) => MealEntity(
  code: 'test',
  name: 'Test',
  url: null,
  mealQuantity: null,
  mealUnit: null,
  servingQuantity: servingQuantity,
  servingUnit: null,
  servingSize: null,
  source: MealSourceEntity.off,
  nutriments: MealNutrimentsEntity(
    energyKcal100: energyKcal100,
    carbohydrates100: null,
    fat100: null,
    proteins100: null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
);

void main() {
  group('convertQuantityToBaseUnit', () {
    test('g, ml and g/ml pass through unchanged', () {
      for (final unit in ['g', 'ml', 'g/ml']) {
        expect(convertQuantityToBaseUnit(100, unit, meal()), 100);
      }
    });

    test('oz converts to grams', () {
      // The bug this guards: logging the raw amount stored 4 g for 4 oz,
      // roughly a 28x under-count.
      final grams = convertQuantityToBaseUnit(4, 'oz', meal());

      expect(grams, greaterThan(110));
      expect(grams, lessThan(115));
    });

    test('fl.oz converts to millilitres', () {
      final ml = convertQuantityToBaseUnit(4, 'fl.oz', meal());

      expect(ml, greaterThan(115));
      expect(ml, lessThan(120));
    });

    test('serving multiplies by the serving quantity', () {
      expect(
        convertQuantityToBaseUnit(2, 'serving', meal(servingQuantity: 125)),
        250,
      );
    });

    test('serving with no serving data leaves the amount alone', () {
      // Guessing here would be worse than logging what the user typed.
      expect(convertQuantityToBaseUnit(2, 'serving', meal()), 2);
    });
  });

  group('kcalForQuantity', () {
    test('scales energy by the converted amount, not the raw one', () {
      final food = meal(energyKcal100: 100);

      // 100 kcal/100 g = 1 kcal/g. 4 oz is ~113 g, so ~113 kcal — not 4.
      final kcal = kcalForQuantity(4, 'oz', food)!;

      expect(kcal, greaterThan(110));
      expect(kcal, lessThan(115));
    });

    test('a serving amount uses the serving quantity', () {
      final food = meal(energyKcal100: 100, servingQuantity: 125);

      expect(kcalForQuantity(2, 'serving', food), 250);
    });

    test('returns null when the food carries no energy value', () {
      expect(kcalForQuantity(100, 'g', meal()), isNull);
    });
  });
}
