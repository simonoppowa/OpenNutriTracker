import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

class MealEntityFixtures {
  static final mealOne = MealEntity(
      code: "1",
      name: null,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: '2 Tbsp (32 g)',
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom);
  static final mealTwo = MealEntity(
      code: "2",
      name: null,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: '2 Tbsp (32 g)',
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom);
  static final mealThree = MealEntity(
      code: "3",
      name: null,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: '2 Tbsp (32 g)',
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom);
}