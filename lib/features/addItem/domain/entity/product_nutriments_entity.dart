import 'package:opennutritracker/features/addItem/data/dto/off_product_nutriments.dart';

class ProductNutrimentsEntity {
  final double? energyKcal100;
  final double? energyPerUnit;
  final double? carbohydrates100g;
  final double? carbohydratesPerUnit;
  final double? fat100g;
  final double? fatPerUnit;
  final double? proteins100g;
  final double? proteinsPerUnit;
  final double? sugars100g;
  final double? saturatedFat100g;
  final double? fiber100g;

  ProductNutrimentsEntity(
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

  factory ProductNutrimentsEntity.fromOffNutriments(
      OFFProductNutriments offNutriments) {
    return ProductNutrimentsEntity(
        energyKcal100: offNutriments.energy_kcal_100g,
        energyPerUnit: _getValuePerUnit(offNutriments.energy_kcal_100g),
        carbohydrates100g: offNutriments.carbohydrates_100g,
        carbohydratesPerUnit: _getValuePerUnit(offNutriments.carbohydrates_100g),
        fat100g: offNutriments.fat_100g,
        fatPerUnit: _getValuePerUnit(offNutriments.fat_100g),
        proteins100g: offNutriments.proteins_100g,
        proteinsPerUnit: _getValuePerUnit(offNutriments.proteins_100g),
        sugars100g: offNutriments.sugars_100g,
        saturatedFat100g: offNutriments.saturated_fat_100g,
        fiber100g: offNutriments.fiber_100g);
  }

  static double? _getValuePerUnit(double? valuePer100) {
    if (valuePer100 != null) {
      return valuePer100 / 100;
    } else {
      return null;
    }
  }
}
