import 'package:opennutritracker/features/addItem/data/dto/off_product_nutriments.dart';

class ProductNutrimentsEntity {
  final double? energyKcal100g;
  final double? carbohydrates100g;
  final double? fat100g;
  final double? proteins100g;
  final double? sugars100g;
  final double? saturatedFat100g;
  final double? fiber100g;

  ProductNutrimentsEntity({required this.energyKcal100g,
    required this.carbohydrates100g,
    required this.fat100g,
    required this.proteins100g,
    required this.sugars100g,
    required this.saturatedFat100g,
    required this.fiber100g});

  factory ProductNutrimentsEntity.fromOffNutriments(
      OFFProductNutriments offNutriments) {
    return ProductNutrimentsEntity(energyKcal100g: offNutriments.energy_kcal,
        carbohydrates100g: offNutriments.carbohydrates_100g,
        fat100g: offNutriments.fat_100g,
        proteins100g: offNutriments.proteins_100g,
        sugars100g: offNutriments.sugars_100g,
        saturatedFat100g: offNutriments.saturated_fat_100g,
        fiber100g: offNutriments.fiber_100g);
  }

}
