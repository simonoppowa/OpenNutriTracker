import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

MealEntity _meal({String? servingSize, double? servingQuantity}) => MealEntity(
  code: '123',
  name: 'Bread',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: servingQuantity,
  servingUnit: 'g',
  servingSize: servingSize,
  source: MealSourceEntity.fdc,
  nutriments: MealNutrimentsEntity.empty(),
);

void main() {
  group('MealEntity.withServingLabel (#864)', () {
    test('replaces the label and records that it is localized', () {
      final meal = _meal(servingSize: '1 slice (38 g)', servingQuantity: 38);
      expect(meal.servingSizeIsLocalized, isFalse);

      final localized = meal.withServingLabel('1 Scheibe (38 g)');
      expect(localized.servingSize, '1 Scheibe (38 g)');
      expect(localized.servingSizeIsLocalized, isTrue);
    });

    test('leaves the gram weight alone', () {
      // The backend picks the label and the weight from the same portion
      // row, so swapping one without the other is how "1 slice" ends up
      // beside a weight that belongs to a different portion.
      final localized =
          _meal(servingSize: '1 slice (38 g)', servingQuantity: 38)
              .withServingLabel('1 Scheibe (38 g)');
      expect(localized.servingQuantity, 38);
      expect(localized.servingUnit, 'g');
    });

    test('carries the rest of the meal across unchanged', () {
      final localized = _meal(servingSize: '1 slice', servingQuantity: 38)
          .withServingLabel('1 Scheibe');
      expect(localized.code, '123');
      expect(localized.name, 'Bread');
      expect(localized.source, MealSourceEntity.fdc);
      expect(localized.mealUnit, 'g');
    });

    test('a meal read back from the database is never marked localized', () {
      // Nothing persists this provenance, so a stored meal must report the
      // conservative answer rather than inheriting a default of true.
      expect(_meal(servingSize: '1 slice').servingSizeIsLocalized, isFalse);
    });
  });
}
