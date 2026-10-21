import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/trends/domain/nutrient_deficits.dart';

IntakeEntity _intake(
  double grams, {
  double? iron,
  double? vitaminC,
  double? zinc,
}) => IntakeEntity(
  id: '$grams-$iron-$vitaminC-$zinc',
  unit: 'g',
  amount: grams,
  type: IntakeTypeEntity.lunch,
  dateTime: DateTime(2026, 10, 19),
  meal: MealEntity(
    code: 'x',
    name: 'x',
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: null,
    servingSize: null,
    nutriments: MealNutrimentsEntity(
      energyKcal100: 100,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
      iron100: iron,
      vitaminC100: vitaminC,
      zinc100: zinc,
    ),
    source: MealSourceEntity.off,
  ),
);

double? _reference(String key, DateTime day) => switch (key) {
  NutrientPanelKeys.iron => 10,
  NutrientPanelKeys.vitaminC => 100,
  NutrientPanelKeys.zinc => 10,
  _ => null,
};

void main() {
  final days = [for (var d = 19; d <= 22; d++) DateTime(2026, 10, d)];

  test('counts the days below the share of the reference', () {
    final deficits = nutrientDeficits(
      intakesByDay: {
        days[0]: [_intake(100, iron: 2)],
        days[1]: [_intake(100, iron: 9)],
        days[2]: [_intake(100, iron: 5)],
      },
      referenceOf: _reference,
    );

    final iron = deficits.singleWhere((d) => d.key == NutrientPanelKeys.iron);
    expect(iron.deficitDays, 2);
    expect(iron.evaluatedDays, 3);
    expect(iron.share, closeTo(2 / 3, 1e-9));
  });

  test('a day with mostly unknown values is no deficit and not counted', () {
    final deficits = nutrientDeficits(
      intakesByDay: {
        days[0]: [_intake(100, iron: 1), _intake(100), _intake(100)],
        days[1]: [_intake(100, iron: 1), _intake(100)],
      },
      referenceOf: _reference,
    );

    final iron = deficits.singleWhere((d) => d.key == NutrientPanelKeys.iron);
    expect(iron.evaluatedDays, 1);
    expect(iron.deficitDays, 1);
  });

  test('a nutrient nothing gave a value for is no deficit', () {
    final deficits = nutrientDeficits(
      intakesByDay: {
        days[0]: [_intake(100, iron: 1)],
      },
      referenceOf: _reference,
    );

    expect(deficits.map((d) => d.key), isNot(contains(NutrientPanelKeys.zinc)));
    expect(
      deficits.map((d) => d.key),
      isNot(contains(NutrientPanelKeys.vitaminC)),
    );
  });

  test('the threshold can be set', () {
    final intakes = {
      days[0]: [_intake(100, iron: 8)],
    };

    expect(
      nutrientDeficits(intakesByDay: intakes, referenceOf: _reference),
      isEmpty,
    );
    expect(
      nutrientDeficits(
        intakesByDay: intakes,
        referenceOf: _reference,
        threshold: 0.9,
      ).single.key,
      NutrientPanelKeys.iron,
    );
  });

  test('the most frequent deficits come first, cut to the top', () {
    final deficits = nutrientDeficits(
      intakesByDay: {
        for (final day in days)
          day: [
            _intake(
              100,
              iron: 1,
              vitaminC: day == days[0] ? 10 : 200,
              zinc: day.day.isEven ? 1 : 20,
            ),
          ],
      },
      referenceOf: _reference,
      top: 2,
    );

    expect(deficits.map((d) => d.key), [
      NutrientPanelKeys.iron,
      NutrientPanelKeys.zinc,
    ]);
  });

  test('limits like sodium are never deficits', () {
    final deficits = nutrientDeficits(
      intakesByDay: {
        days[0]: [_intake(100, iron: 1)],
      },
      referenceOf: (key, day) => 1000,
    );

    expect(
      deficits.map((d) => d.key),
      isNot(contains(NutrientPanelKeys.sodium)),
    );
  });
}
