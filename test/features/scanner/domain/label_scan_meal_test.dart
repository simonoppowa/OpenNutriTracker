import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/scanner/domain/label_scan_meal.dart';

MealEntity _product({
  String? code = '4056489123456',
  MealSourceEntity source = MealSourceEntity.off,
  MealNutrimentsEntity? nutriments,
}) => MealEntity(
  code: code,
  name: 'Studenten-Futter',
  brands: 'Natur Gut',
  url: 'https://world.openfoodfacts.org/product/4056489123456',
  mealQuantity: '200',
  mealUnit: 'g',
  servingQuantity: 25,
  servingUnit: 'g',
  servingSize: '25 g',
  nutriments: nutriments ?? MealNutrimentsEntity.empty(),
  source: source,
);

const _complete = MealNutrimentsEntity(
  energyKcal100: 480,
  carbohydrates100: 40,
  fat100: 30,
  proteins100: 12,
  sugars100: null,
  saturatedFat100: null,
  fiber100: null,
);

void main() {
  test('the new food keeps name and brand and nothing else', () {
    final meal = labelScanMealFor(_product());

    expect(meal.source, MealSourceEntity.custom);
    expect(meal.name, 'Studenten-Futter');
    expect(meal.brands, 'Natur Gut');
    expect(meal.code, isNot('4056489123456'));
    expect(meal.url, isNull);
    expect(meal.nutriments.energyKcal100, isNull);
  });

  test('the barcode is carried over when it is a retail barcode', () {
    expect(labelScanBarcodeFor(_product()), '4056489123456');
    expect(labelScanBarcodeFor(_product(code: 'a3f1c0de-uuid')), isNull);
    expect(labelScanBarcodeFor(_product(code: null)), isNull);
  });

  test(
    'an Open Food Facts product without energy or macros lacks nutrients',
    () {
      expect(lacksNutrients(_product()), isTrue);
      expect(
        lacksNutrients(
          _product(
            nutriments: const MealNutrimentsEntity(
              energyKcal100: 480,
              carbohydrates100: null,
              fat100: 30,
              proteins100: 12,
              sugars100: null,
              saturatedFat100: null,
              fiber100: null,
            ),
          ),
        ),
        isTrue,
      );
      expect(lacksNutrients(_product(nutriments: _complete)), isFalse);
    },
  );

  test('only Open Food Facts products are offered the scan', () {
    expect(lacksNutrients(_product(source: MealSourceEntity.custom)), isFalse);
    expect(lacksNutrients(_product(source: MealSourceEntity.fdc)), isFalse);
  });
}
