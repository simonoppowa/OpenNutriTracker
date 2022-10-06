import 'package:hive_flutter/hive_flutter.dart';

part 'product_nutriments_dbo.g.dart';

@HiveType(typeId: 3)
class ProductNutrimentsDBO extends HiveObject {
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

  ProductNutrimentsDBO(
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
}
