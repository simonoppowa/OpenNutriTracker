import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// [grams] of a food with [protein100] g protein and [carbs100] g carbs
/// per 100 g.
IntakeEntity intakeOf(
  String name,
  double grams, {
  double protein100 = 0,
  double carbs100 = 0,
  IntakeTypeEntity type = IntakeTypeEntity.lunch,
}) => IntakeEntity(
  id: '$name-${type.name}',
  unit: 'g',
  amount: grams,
  type: type,
  meal: MealEntity(
    code: name,
    name: name,
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    nutriments: MealNutrimentsEntity(
      energyKcal100: 100,
      carbohydrates100: carbs100,
      fat100: 0,
      proteins100: protein100,
      sugars100: 0,
      saturatedFat100: 0,
      fiber100: 0,
    ),
    source: MealSourceEntity.custom,
  ),
  dateTime: DateTime(2026, 10, 23),
);
