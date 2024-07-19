import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

class MealEntityFixtures {
  static final meal_one = MealEntity(
      code: "1",
      name: null,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom);
  static final meal_two = MealEntity(
      code: "2",
      name: null,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom);
  static final meal_three = MealEntity(
      code: "3",
      name: null,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom);
}