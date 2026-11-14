import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/util/last_portion.dart';

// #1265: which unit and quantity the meal-detail screen opens on, given the
// last time the food was logged. Null keeps the screen's usual default.

const _nutriments = MealNutrimentsEntity(
  energyKcal100: 100,
  carbohydrates100: 10,
  fat100: 5,
  proteins100: 5,
  sugars100: null,
  saturatedFat100: null,
  fiber100: null,
);

MealEntity _meal({
  String mealUnit = 'g',
  double? servingQuantity,
  String? servingSize,
  MealSourceEntity source = MealSourceEntity.off,
}) => MealEntity(
  code: 'food',
  name: 'Food',
  url: null,
  mealQuantity: '100',
  mealUnit: mealUnit,
  servingQuantity: servingQuantity,
  servingUnit: servingQuantity == null ? null : 'g',
  servingSize: servingSize,
  nutriments: _nutriments,
  source: source,
);

IntakeEntity _logged(String unit, double amount, {MealEntity? meal}) =>
    IntakeEntity(
      id: 'last',
      unit: unit,
      amount: amount,
      type: IntakeTypeEntity.breakfast,
      meal: meal ?? _meal(servingQuantity: 30),
      dateTime: DateTime(2026, 3, 1),
    );

void main() {
  test('nothing logged keeps the default', () {
    expect(lastPortionFor(_meal(), null), isNull);
  });

  test('grams come back as the same grams', () {
    final portion = lastPortionFor(_meal(), _logged('g', 60));

    expect(portion?.unit, 'g');
    expect(portion?.quantity, '60');
  });

  test('servings come back as the number of servings', () {
    final food = _meal(servingQuantity: 30);
    final portion = lastPortionFor(food, _logged('serving', 60, meal: food));

    expect(portion?.unit, 'serving');
    expect(portion?.quantity, '2');
  });

  test('a serving that changed size keeps the amount, not the count', () {
    // Logged as 2 x 30 g; the food now says a serving is 40 g. 60 g is what
    // was eaten, so it opens on 1.5 servings rather than 2 x 40 g.
    final portion = lastPortionFor(
      _meal(servingQuantity: 40),
      _logged('serving', 60, meal: _meal(servingQuantity: 30)),
    );

    expect(portion?.unit, 'serving');
    expect(portion?.quantity, '1.5');
  });

  test('a serving the food no longer has falls back to the default', () {
    expect(lastPortionFor(_meal(), _logged('serving', 60)), isNull);
  });

  test('a serving logged when the food had none falls back too', () {
    // The amount was never scaled then (#629), so it is no weight to divide.
    expect(
      lastPortionFor(
        _meal(servingQuantity: 30),
        _logged('serving', 1, meal: _meal()),
      ),
      isNull,
    );
  });

  test('a serving read from the serving text counts as a serving', () {
    final food = _meal(servingSize: '1 bar (45 g)');
    final portion = lastPortionFor(food, _logged('serving', 90, meal: food));

    expect(portion?.unit, 'serving');
    expect(portion?.quantity, '2');
  });

  test('ounces come back in ounces', () {
    final portion = lastPortionFor(_meal(), _logged('oz', UnitCalc.ozToG(2)));

    expect(portion?.unit, 'oz');
    expect(portion?.quantity, '2');
  });

  test('fluid ounces come back in fluid ounces', () {
    final drink = _meal(mealUnit: 'ml');
    final portion = lastPortionFor(
      drink,
      _logged('fl.oz', UnitCalc.flOzToMl(12), meal: drink),
    );

    expect(portion?.unit, 'fl.oz');
    expect(portion?.quantity, '12');
  });

  test('a weight unit on a food that is now a drink falls back', () {
    expect(lastPortionFor(_meal(mealUnit: 'ml'), _logged('g', 200)), isNull);
  });

  test('g/ml stays g/ml on a food of unknown shape', () {
    final portion = lastPortionFor(
      _meal(mealUnit: 'gml'),
      _logged('g/ml', 150),
    );

    expect(portion?.unit, 'g/ml');
    expect(portion?.quantity, '150');
  });

  test('a unit the screen does not offer falls back', () {
    expect(lastPortionFor(_meal(), _logged('kcal', 100)), isNull);
    expect(lastPortionFor(_meal(), _logged('', 100)), isNull);
  });

  test('a portion suffix is read as the serving it was stored as', () {
    final food = _meal(servingQuantity: 30);
    final portion = lastPortionFor(food, _logged('serving#1', 90, meal: food));

    expect(portion?.unit, 'serving');
    expect(portion?.quantity, '3');
  });

  test('a zero, negative or non-finite amount falls back', () {
    expect(lastPortionFor(_meal(), _logged('g', 0)), isNull);
    expect(lastPortionFor(_meal(), _logged('g', -5)), isNull);
    expect(lastPortionFor(_meal(), _logged('g', double.nan)), isNull);
    expect(lastPortionFor(_meal(), _logged('g', double.infinity)), isNull);
    // Rounds to 0 at two decimals.
    expect(lastPortionFor(_meal(), _logged('g', 0.001)), isNull);
  });

  test('a quantity is rounded to two decimals', () {
    final portion = lastPortionFor(_meal(), _logged('g', 33.3333));

    expect(portion?.quantity, '33.33');
  });

  test('a Quick Add entry comes back as the 100 g it was stored as', () {
    // Quick Add stores its totals per 100 and logs 100 g of them.
    final quickAdd = _meal(mealUnit: 'gml', source: MealSourceEntity.custom);
    final portion = lastPortionFor(quickAdd, _logged('g', 100, meal: quickAdd));

    expect(portion?.unit, 'g');
    expect(portion?.quantity, '100');
  });

  test('a recipe logged by the serving comes back by the serving', () {
    final recipe = _meal(
      servingQuantity: 300,
      servingSize: '4 servings',
      source: MealSourceEntity.recipe,
    );
    final portion = lastPortionFor(
      recipe,
      _logged('serving', 600, meal: recipe),
    );

    expect(portion?.unit, 'serving');
    expect(portion?.quantity, '2');
  });
}
