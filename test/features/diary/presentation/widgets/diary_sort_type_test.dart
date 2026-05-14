import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_sort_type.dart';

IntakeEntity _intake({
  required String id,
  required double amount,
  required double kcal100,
  required double carbs100,
  required double fat100,
  required double protein100,
}) {
  return IntakeEntity(
    id: id,
    unit: 'g',
    amount: amount,
    type: IntakeTypeEntity.breakfast,
    dateTime: DateTime(2026, 1, 1),
    meal: MealEntity(
      code: id,
      name: 'Meal $id',
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: '100 g',
      nutriments: MealNutrimentsEntity(
        energyKcal100: kcal100,
        carbohydrates100: carbs100,
        fat100: fat100,
        proteins100: protein100,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    ),
  );
}

void main() {
  // Three intakes chosen so each macro has a different "winner", so we know
  // each sort path is actually doing something different.
  final apple = _intake(
    id: 'apple',
    amount: 200,
    kcal100: 52,
    carbs100: 14,
    fat100: 0.2,
    protein100: 0.3,
  );
  final almond = _intake(
    id: 'almond',
    amount: 30,
    kcal100: 579,
    carbs100: 22,
    fat100: 50,
    protein100: 21,
  );
  final chicken = _intake(
    id: 'chicken',
    amount: 150,
    kcal100: 165,
    carbs100: 0,
    fat100: 3.6,
    protein100: 31,
  );

  final source = [apple, almond, chicken];

  test('timeAdded preserves the original order', () {
    final result = DiarySortType.timeAdded.apply(source);
    expect(result.map((i) => i.id).toList(), ['apple', 'almond', 'chicken']);
  });

  test('kcal sorts high to low', () {
    final result = DiarySortType.kcal.apply(source);
    // 200g apple = 104 kcal, 30g almond = ~173 kcal, 150g chicken = ~248 kcal.
    expect(result.map((i) => i.id).toList(), ['chicken', 'almond', 'apple']);
  });

  test('protein sorts high to low', () {
    final result = DiarySortType.protein.apply(source);
    // 150g chicken = 46.5g, 30g almond = 6.3g, 200g apple = 0.6g.
    expect(result.map((i) => i.id).toList(), ['chicken', 'almond', 'apple']);
  });

  test('carbs sorts high to low', () {
    final result = DiarySortType.carbs.apply(source);
    // 200g apple = 28g, 30g almond = 6.6g, 150g chicken = 0g.
    expect(result.map((i) => i.id).toList(), ['apple', 'almond', 'chicken']);
  });

  test('fat sorts high to low', () {
    final result = DiarySortType.fat.apply(source);
    // 30g almond = 15g, 150g chicken = 5.4g, 200g apple = 0.4g.
    expect(result.map((i) => i.id).toList(), ['almond', 'chicken', 'apple']);
  });

  test('apply returns a new list and never mutates the source', () {
    final original = List<IntakeEntity>.of(source);
    final sorted = DiarySortType.kcal.apply(source);
    expect(identical(sorted, source), isFalse,
        reason: 'apply must return a copy');
    expect(source.map((i) => i.id).toList(),
        original.map((i) => i.id).toList(),
        reason: 'source list must be untouched');
  });

  test('apply handles an empty list without error', () {
    for (final sort in DiarySortType.values) {
      expect(sort.apply(const <IntakeEntity>[]), isEmpty);
    }
  });
}
