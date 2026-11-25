import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

MealEntity _meal(
  MealSourceEntity source, {
  double? kcal = 350,
  double? carbs,
  double? fat,
  double? protein,
}) => MealEntity(
  code: 'required-nutrients-test',
  name: 'Cake',
  url: null,
  mealQuantity: '100',
  mealUnit: 'gml',
  servingQuantity: null,
  servingUnit: 'gml',
  servingSize: '',
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal,
    carbohydrates100: carbs,
    fat100: fat,
    proteins100: protein,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: source,
);

// #1295: a food the user made (Quick Add, a custom meal) may leave its
// macros out; logging it again must not be refused for that. Energy is
// always needed, and a database food still needs all four (#1474).
void main() {
  group('a food the user made', () {
    test('with only energy needs nothing more', () {
      expect(_meal(MealSourceEntity.custom).missingRequiredNutrients, isEmpty);
    });

    test('with some macros needs nothing more', () {
      expect(
        _meal(MealSourceEntity.custom, carbs: 40).missingRequiredNutrients,
        isEmpty,
      );
    });

    test('with every value needs nothing more', () {
      expect(
        _meal(
          MealSourceEntity.custom,
          carbs: 40,
          fat: 20,
          protein: 5,
        ).missingRequiredNutrients,
        isEmpty,
      );
    });

    test('without energy still needs it', () {
      expect(
        _meal(
          MealSourceEntity.custom,
          kcal: null,
          carbs: 40,
          fat: 20,
          protein: 5,
        ).missingRequiredNutrients,
        [RequiredNutrient.energy],
      );
    });
  });

  group('a database food', () {
    for (final source in [
      MealSourceEntity.off,
      MealSourceEntity.fdc,
      MealSourceEntity.recipe,
      MealSourceEntity.unknown,
    ]) {
      test('${source.name} with only energy still needs every macro', () {
        expect(_meal(source).missingRequiredNutrients, [
          RequiredNutrient.carbohydrates,
          RequiredNutrient.fat,
          RequiredNutrient.protein,
        ]);
      });
    }

    test('missing only fat needs fat', () {
      expect(
        _meal(
          MealSourceEntity.fdc,
          carbs: 53.4,
          protein: 1.3,
        ).missingRequiredNutrients,
        [RequiredNutrient.fat],
      );
    });

    test('with every value needs nothing', () {
      expect(
        _meal(
          MealSourceEntity.off,
          carbs: 1,
          fat: 0,
          protein: 0,
        ).missingRequiredNutrients,
        isEmpty,
      );
    });
  });
}
