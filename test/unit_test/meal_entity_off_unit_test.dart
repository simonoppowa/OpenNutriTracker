import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

OFFProductDTO _product({
  String? servingQuantityUnit,
  String? servingSize,
  String? quantity,
}) {
  return OFFProductDTO(
    code: '123',
    product_name: 'Test product',
    product_name_en: 'Test product',
    product_name_fr: null,
    product_name_de: null,
    brands: null,
    image_front_thumb_url: null,
    image_front_url: null,
    image_ingredients_url: null,
    image_nutrition_url: null,
    image_url: null,
    url: null,
    quantity: quantity,
    product_quantity: null,
    serving_quantity: 30,
    serving_size: servingSize,
    serving_quantity_unit: servingQuantityUnit,
    nutriments: null,
  );
}

void main() {
  group('MealEntity.fromOFFProduct unit derivation', () {
    test("OFF's normalised serving unit wins", () {
      final meal = MealEntity.fromOFFProduct(
        _product(servingQuantityUnit: 'ml', quantity: '500 g'),
      );
      expect(meal.mealUnit, 'ml');
      expect(meal.servingUnit, 'ml');
      expect(meal.isLiquid, isTrue);
    });

    test('volume variants of the serving unit collapse to ml', () {
      final meal = MealEntity.fromOFFProduct(
        _product(servingQuantityUnit: 'cl'),
      );
      expect(meal.mealUnit, 'ml');
    });

    test('falls back to the unit parsed from serving_size', () {
      final meal = MealEntity.fromOFFProduct(_product(servingSize: '30 g'));
      expect(meal.mealUnit, 'g');
      expect(meal.isSolid, isTrue);
    });

    test('falls back to the package quantity string last', () {
      final meal = MealEntity.fromOFFProduct(_product(quantity: '1 L'));
      expect(meal.mealUnit, 'ml');
    });

    test('stays null when no unit source is available', () {
      final meal = MealEntity.fromOFFProduct(_product());
      expect(meal.mealUnit, isNull);
      expect(meal.isSolid, isFalse);
      expect(meal.isLiquid, isFalse);
    });

    test('household serving descriptions containing "l" stay solid', () {
      for (final servingSize in [
        '1 slice (38 g)',
        '1 roll (60g)',
        '1 bowl (250 g)',
        '1 fillet',
      ]) {
        final meal = MealEntity.fromOFFProduct(
          _product(servingSize: servingSize),
        );
        expect(meal.mealUnit, 'g', reason: 'for "$servingSize"');
        expect(meal.isSolid, isTrue, reason: 'for "$servingSize"');
      }
    });
  });
}
