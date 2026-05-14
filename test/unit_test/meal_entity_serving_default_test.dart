import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

// Covers the fix for issue #158: when an OFF product carries serving data
// (either servingQuantity or servingSize), the meal-detail bottom sheet
// should default the unit dropdown to "1 serving" instead of "100 g/ml".
// The screen and recipe-ingredient dialog both branch on
// `MealEntity.hasServingValues` to pick the initial unit and to decide
// whether to surface the "serving" dropdown item, so the regression test
// targets that single getter rather than the whole UI path.

MealEntity _meal({
  double? servingQuantity,
  String? servingUnit,
  String? servingSize,
}) {
  return MealEntity(
    code: 'test',
    name: 'Test product',
    url: null,
    mealQuantity: null,
    mealUnit: null,
    servingQuantity: servingQuantity,
    servingUnit: servingUnit,
    servingSize: servingSize,
    nutriments: MealNutrimentsEntity.empty(),
    source: MealSourceEntity.off,
  );
}

void main() {
  group('MealEntity.hasServingValues — issue #158', () {
    test('true when only servingQuantity is set (servingUnit/Size both null)', () {
      // This is the scan path that previously regressed: OFF returns
      // serving_quantity = 30 (per granola bar) but no overall package
      // `quantity`, so the derived `servingUnit` is null. Before the fix,
      // hasServingValues required both fields and returned false, leaving
      // the dropdown stuck on 100 g/ml.
      final meal = _meal(servingQuantity: 30.0);
      expect(meal.hasServingValues, isTrue);
    });

    test('true when only servingSize is set (servingQuantity null)', () {
      // Some OFF entries surface a human-readable serving label like
      // "2 Tbsp (32 g)" without a numeric servingQuantity. The user still
      // wants the dropdown to default to that serving label.
      final meal = _meal(servingSize: '2 Tbsp (32 g)');
      expect(meal.hasServingValues, isTrue);
    });

    test('true when both servingQuantity and servingSize are set', () {
      final meal = _meal(
        servingQuantity: 30.0,
        servingUnit: 'g',
        servingSize: '1 bar (30 g)',
      );
      expect(meal.hasServingValues, isTrue);
    });

    test('false when neither servingQuantity nor servingSize is set', () {
      // Bulk products like 1 kg of flour have no serving — the dropdown
      // should keep defaulting to 100 g/ml, which depends on this returning
      // false.
      final meal = _meal();
      expect(meal.hasServingValues, isFalse);
    });
  });
}
