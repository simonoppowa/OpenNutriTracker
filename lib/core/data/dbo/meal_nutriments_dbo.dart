import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

part 'meal_nutriments_dbo.g.dart';

@HiveType(typeId: 3)
class MealNutrimentsDBO extends HiveObject {
  @HiveField(0)
  final double? energyKcal100;
  @HiveField(1)
  final double? energyPerUnit;
  @HiveField(2)
  final double? carbohydrates100g;
  @HiveField(3)
  final double? carbohydratesPerUnit;
  @HiveField(4)
  final double? fat100g;
  @HiveField(5)
  final double? fatPerUnit;
  @HiveField(6)
  final double? proteins100g;
  @HiveField(7)
  final double? proteinsPerUnit;
  @HiveField(8)
  final double? sugars100g;
  @HiveField(9)
  final double? saturatedFat100g;
  @HiveField(10)
  final double? fiber100g;

  MealNutrimentsDBO(
      {required this.energyKcal100,
      required this.energyPerUnit,
      required this.carbohydrates100g,
      required this.carbohydratesPerUnit,
      required this.fat100g,
      required this.fatPerUnit,
      required this.proteins100g,
      required this.proteinsPerUnit,
      required this.sugars100g,
      required this.saturatedFat100g,
      required this.fiber100g});

  factory MealNutrimentsDBO.fromProductNutrimentsEntity(
      MealNutrimentsEntity nutriments) {
    return MealNutrimentsDBO(
        energyKcal100: nutriments.energyKcal100,
        energyPerUnit: nutriments.energyPerUnit,
        carbohydrates100g: nutriments.carbohydrates100g,
        carbohydratesPerUnit: nutriments.carbohydratesPerUnit,
        fat100g: nutriments.fat100g,
        fatPerUnit: nutriments.fatPerUnit,
        proteins100g: nutriments.proteins100g,
        proteinsPerUnit: nutriments.proteinsPerUnit,
        sugars100g: nutriments.sugars100g,
        saturatedFat100g: nutriments.saturatedFat100g,
        fiber100g: nutriments.fiber100g);
  }
}
