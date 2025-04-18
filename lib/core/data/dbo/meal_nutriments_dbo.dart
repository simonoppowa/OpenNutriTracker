import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

part 'meal_nutriments_dbo.g.dart';

@HiveType(typeId: 3)
@JsonSerializable()
class MealNutrimentsDBO extends HiveObject {
  @HiveField(0)
  final double? energyKcal100;
  @HiveField(1)
  final double? carbohydrates100;
  @HiveField(2)
  final double? fat100;
  @HiveField(3)
  final double? proteins100;
  @HiveField(4)
  final double? sugars100;
  @HiveField(5)
  final double? saturatedFat100;
  @HiveField(6)
  final double? fiber100;

  MealNutrimentsDBO(
      {required this.energyKcal100,
      required this.carbohydrates100,
      required this.fat100,
      required this.proteins100,
      required this.sugars100,
      required this.saturatedFat100,
      required this.fiber100});

  factory MealNutrimentsDBO.fromProductNutrimentsEntity(
      MealNutrimentsEntity nutriments) {
    return MealNutrimentsDBO(
        energyKcal100: nutriments.energyKcal100,
        carbohydrates100: nutriments.carbohydrates100,
        fat100: nutriments.fat100,
        proteins100: nutriments.proteins100,
        sugars100: nutriments.sugars100,
        saturatedFat100: nutriments.saturatedFat100,
        fiber100: nutriments.fiber100);
  }

  factory MealNutrimentsDBO.fromJson(Map<String, dynamic> json) =>
      _$MealNutrimentsDBOFromJson(json);

  Map<String, dynamic> toJson() => _$MealNutrimentsDBOToJson(this);
}
