import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food_nutriment_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_nutriments_dto.dart';

class MealNutrimentsEntity extends Equatable {
  final double? energyKcal100;

  final double? carbohydrates100;
  final double? fat100;
  final double? proteins100;
  final double? sugars100;
  final double? saturatedFat100;
  final double? fiber100;

  double? get energyPerUnit => _getValuePerUnit(energyKcal100);

  double? get carbohydratesPerUnit => _getValuePerUnit(carbohydrates100);

  double? get fatPerUnit => _getValuePerUnit(fat100);

  double? get proteinsPerUnit => _getValuePerUnit(proteins100);

  const MealNutrimentsEntity(
      {required this.energyKcal100,
      required this.carbohydrates100,
      required this.fat100,
      required this.proteins100,
      required this.sugars100,
      required this.saturatedFat100,
      required this.fiber100});

  factory MealNutrimentsEntity.empty() => const MealNutrimentsEntity(
      energyKcal100: null,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null);

  factory MealNutrimentsEntity.fromMealNutrimentsDBO(
      MealNutrimentsDBO nutriments) {
    return MealNutrimentsEntity(
        energyKcal100: nutriments.energyKcal100,
        carbohydrates100: nutriments.carbohydrates100,
        fat100: nutriments.fat100,
        proteins100: nutriments.proteins100,
        sugars100: nutriments.sugars100,
        saturatedFat100: nutriments.saturatedFat100,
        fiber100: nutriments.fiber100);
  }

  factory MealNutrimentsEntity.fromOffNutriments(
      OFFProductNutrimentsDTO offNutriments) {
    // 1. OFF product nutriments can either be String, int, double or null
    // 2. Extension function asDoubleOrNull does not work on a dynamic data
    // type, so cast to it Object?
    return MealNutrimentsEntity(
        energyKcal100:
            (offNutriments.energy_kcal_100g as Object?).asDoubleOrNull(),
        carbohydrates100:
            (offNutriments.carbohydrates_100g as Object?).asDoubleOrNull(),
        fat100: (offNutriments.fat_100g as Object?).asDoubleOrNull(),
        proteins100: (offNutriments.proteins_100g as Object?).asDoubleOrNull(),
        sugars100: (offNutriments.sugars_100g as Object?).asDoubleOrNull(),
        saturatedFat100:
            (offNutriments.saturated_fat_100g as Object?).asDoubleOrNull(),
        fiber100: (offNutriments.fiber_100g as Object?).asDoubleOrNull());
  }

  factory MealNutrimentsEntity.fromFDCNutriments(
      List<FDCFoodNutrimentDTO> fdcNutriment) {
    // FDC Food nutriments can have different values for Energy [Energy,
    // Energy (Atwater General Factors), Energy (Atwater Specific Factors)]
    final energyTotal = fdcNutriment
            .firstWhereOrNull(
                (nutriment) => nutriment.nutrientId == FDCConst.fdcTotalKcalId)
            ?.amount ??
        fdcNutriment
            .firstWhereOrNull((nutriment) =>
                nutriment.nutrientId == FDCConst.fdcKcalAtwaterGeneralId)
            ?.amount ??
        fdcNutriment
            .firstWhereOrNull((nutriment) =>
                nutriment.nutrientId == FDCConst.fdcKcalAtwaterSpecificId)
            ?.amount;

    final carbsTotal = fdcNutriment
        .firstWhereOrNull(
            (nutriment) => nutriment.nutrientId == FDCConst.fdcTotalCarbsId)
        ?.amount;

    final fatTotal = fdcNutriment
        .firstWhereOrNull(
            (nutriment) => nutriment.nutrientId == FDCConst.fdcTotalFatId)
        ?.amount;

    final proteinsTotal = fdcNutriment
        .firstWhereOrNull(
            (nutriment) => nutriment.nutrientId == FDCConst.fdcTotalProteinsId)
        ?.amount;

    final sugarTotal = fdcNutriment
        .firstWhereOrNull(
            (nutriment) => nutriment.nutrientId == FDCConst.fdcTotalSugarId)
        ?.amount;

    final saturatedFatTotal = fdcNutriment
        .firstWhereOrNull((nutriment) =>
            nutriment.nutrientId == FDCConst.fdcTotalSaturatedFatId)
        ?.amount;

    final fiberTotal = fdcNutriment
        .firstWhereOrNull((nutriment) =>
            nutriment.nutrientId == FDCConst.fdcTotalDietaryFiberId)
        ?.amount;

    return MealNutrimentsEntity(
        energyKcal100: energyTotal,
        carbohydrates100: carbsTotal,
        fat100: fatTotal,
        proteins100: proteinsTotal,
        sugars100: sugarTotal,
        saturatedFat100: saturatedFatTotal,
        fiber100: fiberTotal);
  }

  static double? _getValuePerUnit(double? valuePer100) {
    if (valuePer100 != null) {
      return valuePer100 / 100;
    } else {
      return null;
    }
  }

  @override
  List<Object?> get props =>
      [energyKcal100, carbohydrates100, fat100, proteins100];
}
