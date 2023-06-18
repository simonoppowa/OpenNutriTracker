import 'package:collection/collection.dart';
import 'package:opennutritracker/core/data/dbo/product_nutriments_dbo.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food_nutriment.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off_product_nutriments.dart';

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

  factory ProductNutrimentsEntity.fromProductNutrimentsDBO(
      ProductNutrimentsDBO nutriments) {
    return ProductNutrimentsEntity(
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

  factory ProductNutrimentsEntity.fromOffNutriments(
      OFFProductNutriments offNutriments) {
    // 1. OFF product nutriments can either be String, int, double or null
    // 2. Extension function asDoubleOrNull does not work on a dynamic data
    // type, so cast to it Object?
    return ProductNutrimentsEntity(
        energyKcal100:
            (offNutriments.energy_kcal_100g as Object?).asDoubleOrNull(),
        energyPerUnit: _getValuePerUnit(
            (offNutriments.energy_kcal_100g as Object?).asDoubleOrNull()),
        carbohydrates100g:
            (offNutriments.carbohydrates_100g as Object?).asDoubleOrNull(),
        carbohydratesPerUnit: _getValuePerUnit(
            (offNutriments.carbohydrates_100g as Object?).asDoubleOrNull()),
        fat100g: (offNutriments.fat_100g as Object?).asDoubleOrNull(),
        fatPerUnit: _getValuePerUnit(
            (offNutriments.fat_100g as Object?).asDoubleOrNull()),
        proteins100g: (offNutriments.proteins_100g as Object?).asDoubleOrNull(),
        proteinsPerUnit: _getValuePerUnit(
            (offNutriments.proteins_100g as Object?).asDoubleOrNull()),
        sugars100g: (offNutriments.sugars_100g as Object?).asDoubleOrNull(),
        saturatedFat100g:
            (offNutriments.saturated_fat_100g as Object?).asDoubleOrNull(),
        fiber100g: (offNutriments.fiber_100g as Object?).asDoubleOrNull());
  }

  factory ProductNutrimentsEntity.fromFDCNutriments(
      List<FDCFoodNutriment> fdcNutriment) {
    final energyTotal = fdcNutriment
        .firstWhereOrNull(
            (nutriment) => nutriment.nutrientId == FDCConst.fdcTotalKcalId)
        ?.value;

    final carbsTotal = fdcNutriment
        .firstWhereOrNull(
            (nutriment) => nutriment.nutrientId == FDCConst.fdcTotalCarbsId)
        ?.value;

    final fatTotal = fdcNutriment
        .firstWhereOrNull(
            (nutriment) => nutriment.nutrientId == FDCConst.fdcTotalFatId)
        ?.value;

    final proteinsTotal = fdcNutriment
        .firstWhereOrNull(
            (nutriment) => nutriment.nutrientId == FDCConst.fdcTotalProteinsId)
        ?.value;

    final sugarTotal = fdcNutriment
        .firstWhereOrNull(
            (nutriment) => nutriment.nutrientId == FDCConst.fdcTotalSugarId)
        ?.value;

    final saturatedFatTotal = fdcNutriment
        .firstWhereOrNull((nutriment) =>
            nutriment.nutrientId == FDCConst.fdcTotalSaturatedFatId)
        ?.value;

    final fiberTotal = fdcNutriment
        .firstWhereOrNull((nutriment) =>
            nutriment.nutrientId == FDCConst.fdcTotalDietaryFiberId)
        ?.value;

    return ProductNutrimentsEntity(
        energyKcal100: energyTotal,
        energyPerUnit: _getValuePerUnit(energyTotal),
        carbohydrates100g: carbsTotal,
        carbohydratesPerUnit: _getValuePerUnit(carbsTotal),
        fat100g: fatTotal,
        fatPerUnit: _getValuePerUnit(fatTotal),
        proteins100g: proteinsTotal,
        proteinsPerUnit: _getValuePerUnit(proteinsTotal),
        sugars100g: sugarTotal,
        saturatedFat100g: saturatedFatTotal,
        fiber100g: fiberTotal);
  }

  static double? _getValuePerUnit(double? valuePer100) {
    if (valuePer100 != null) {
      return valuePer100 / 100;
    } else {
      return null;
    }
  }
}
