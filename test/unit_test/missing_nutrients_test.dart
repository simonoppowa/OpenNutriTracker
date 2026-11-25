import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/util/missing_nutrients.dart';

MealNutrimentsEntity _nutriments({
  double? kcal,
  double? carbs,
  double? fat,
  double? protein,
}) => MealNutrimentsEntity(
  energyKcal100: kcal,
  carbohydrates100: carbs,
  fat100: fat,
  proteins100: protein,
  sugars100: null,
  saturatedFat100: null,
  fiber100: null,
);

void main() {
  test('a food with energy and all three macros lacks nothing', () {
    expect(
      missingRequiredNutrients(
        _nutriments(kcal: 120, carbs: 10, fat: 5, protein: 8),
      ),
      isEmpty,
    );
  });

  test('a real 0 is a value, not a missing one', () {
    expect(
      missingRequiredNutrients(
        _nutriments(kcal: 0, carbs: 0, fat: 0, protein: 0),
      ),
      isEmpty,
    );
  });

  test('energy-only totals lack the three macros', () {
    expect(missingRequiredNutrients(_nutriments(kcal: 1800)), [
      RequiredNutrient.carbohydrate,
      RequiredNutrient.fat,
      RequiredNutrient.protein,
    ]);
  });

  test('missing energy is named first', () {
    expect(missingRequiredNutrients(_nutriments(carbs: 10, protein: 8)), [
      RequiredNutrient.energy,
      RequiredNutrient.fat,
    ]);
  });
}
