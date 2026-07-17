import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food_nutriment_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_nutriments_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

FDCFoodNutrimentDTO _fdc(int id, double amount) =>
    FDCFoodNutrimentDTO(nutrientId: id, amount: amount);

void main() {
  group('MealNutrimentsEntity.fromFDCNutriments', () {
    test('maps core macros correctly', () {
      final entity = MealNutrimentsEntity.fromFDCNutriments([
        _fdc(FDCConst.fdcTotalKcalId, 250),
        _fdc(FDCConst.fdcTotalCarbsId, 30),
        _fdc(FDCConst.fdcTotalFatId, 10),
        _fdc(FDCConst.fdcTotalProteinsId, 15),
        _fdc(FDCConst.fdcTotalSugarId, 5),
        _fdc(FDCConst.fdcTotalSaturatedFatId, 3),
        _fdc(FDCConst.fdcTotalDietaryFiberId, 2),
      ]);

      expect(entity.energyKcal100, 250);
      expect(entity.carbohydrates100, 30);
      expect(entity.fat100, 10);
      expect(entity.proteins100, 15);
      expect(entity.sugars100, 5);
      expect(entity.saturatedFat100, 3);
      expect(entity.fiber100, 2);
    });

    test('energy ids match the FDC nutrient ids, not the numbers', () {
      // Regression for #252: the Atwater energy constants must be the FDC
      // nutrient *ids* (2047/2048), not the numbers (957/958). Foundation
      // foods such as "Potatoes, russet, without skin, raw" (FDC 2346401)
      // carry only Atwater energy, so keying on the numbers left them with no
      // kcal and they were rejected as "missing required kcal".
      expect(FDCConst.fdcKcalAtwaterGeneralId, 2047);
      expect(FDCConst.fdcKcalAtwaterSpecificId, 2048);
      expect(FDCConst.fdcTotalKcalId, 1008);
    });

    test('micronutrient ids match the FDC nutrient ids, not the numbers', () {
      // #237 originally used FDC nutrient *numbers* for the lipid / mineral /
      // vitamin constants, so they never matched the FDC `nutrientId` the data
      // is keyed on and silently resolved to null. These are the ids. Vitamin A
      // is the RAE form (1106) and Vitamin D the µg form (1114) so the values
      // land in the units the entity documents.
      expect(FDCConst.fdcMonounsaturatedFatId, 1292);
      expect(FDCConst.fdcPolyunsaturatedFatId, 1293);
      expect(FDCConst.fdcTransFatId, 1257);
      expect(FDCConst.fdcCholesterolId, 1253);
      expect(FDCConst.fdcSodiumId, 1093);
      expect(FDCConst.fdcPotassiumId, 1092);
      expect(FDCConst.fdcMagnesiumId, 1090);
      expect(FDCConst.fdcCalciumId, 1087);
      expect(FDCConst.fdcIronId, 1089);
      expect(FDCConst.fdcZincId, 1095);
      expect(FDCConst.fdcPhosphorusId, 1091);
      expect(FDCConst.fdcVitaminAId, 1106);
      expect(FDCConst.fdcVitaminCId, 1162);
      expect(FDCConst.fdcVitaminDId, 1114);
      expect(FDCConst.fdcVitaminB6Id, 1175);
      expect(FDCConst.fdcVitaminB12Id, 1178);
      expect(FDCConst.fdcNiacinId, 1167);
    });

    test('energy prefers Atwater Specific over General and total', () {
      // Atwater Specific is the most precise FDC energy value; when present it
      // should be used in preference to General or the raw total.
      final entity = MealNutrimentsEntity.fromFDCNutriments([
        _fdc(FDCConst.fdcTotalKcalId, 250),
        _fdc(FDCConst.fdcKcalAtwaterGeneralId, 180),
        _fdc(FDCConst.fdcKcalAtwaterSpecificId, 170),
      ]);
      expect(entity.energyKcal100, 170);
    });

    test('energy falls back to Atwater General when Specific absent', () {
      final entity = MealNutrimentsEntity.fromFDCNutriments([
        _fdc(FDCConst.fdcTotalKcalId, 250),
        _fdc(FDCConst.fdcKcalAtwaterGeneralId, 180),
      ]);
      expect(entity.energyKcal100, 180);
    });

    test('energy falls back to total kcal when no Atwater values present', () {
      final entity = MealNutrimentsEntity.fromFDCNutriments([
        _fdc(FDCConst.fdcTotalKcalId, 250),
      ]);
      expect(entity.energyKcal100, 250);
    });

    test('maps all micronutrient fields correctly', () {
      final entity = MealNutrimentsEntity.fromFDCNutriments([
        _fdc(FDCConst.fdcMonounsaturatedFatId, 1.1),
        _fdc(FDCConst.fdcPolyunsaturatedFatId, 2.2),
        _fdc(FDCConst.fdcTransFatId, 0.5),
        _fdc(FDCConst.fdcCholesterolId, 55),
        _fdc(FDCConst.fdcSodiumId, 120),
        _fdc(FDCConst.fdcPotassiumId, 300),
        _fdc(FDCConst.fdcMagnesiumId, 25),
        _fdc(FDCConst.fdcCalciumId, 100),
        _fdc(FDCConst.fdcIronId, 2),
        _fdc(FDCConst.fdcZincId, 1),
        _fdc(FDCConst.fdcPhosphorusId, 150),
        _fdc(FDCConst.fdcVitaminAId, 90),
        _fdc(FDCConst.fdcVitaminCId, 45),
        _fdc(FDCConst.fdcVitaminDId, 5),
        _fdc(FDCConst.fdcVitaminB6Id, 0.3),
        _fdc(FDCConst.fdcVitaminB12Id, 1.5),
        _fdc(FDCConst.fdcNiacinId, 8),
      ]);

      expect(entity.monounsaturatedFat100, 1.1);
      expect(entity.polyunsaturatedFat100, 2.2);
      expect(entity.transFat100, 0.5);
      expect(entity.cholesterol100, 55);
      expect(entity.sodium100, 120);
      expect(entity.potassium100, 300);
      expect(entity.magnesium100, 25);
      expect(entity.calcium100, 100);
      expect(entity.iron100, 2);
      expect(entity.zinc100, 1);
      expect(entity.phosphorus100, 150);
      expect(entity.vitaminA100, 90);
      expect(entity.vitaminC100, 45);
      expect(entity.vitaminD100, 5);
      expect(entity.vitaminB6100, 0.3);
      expect(entity.vitaminB12100, 1.5);
      expect(entity.niacin100, 8);
    });

    test('absent micronutrients are null', () {
      final entity = MealNutrimentsEntity.fromFDCNutriments([
        _fdc(FDCConst.fdcTotalKcalId, 100),
      ]);

      expect(entity.monounsaturatedFat100, isNull);
      expect(entity.sodium100, isNull);
      expect(entity.vitaminC100, isNull);
    });
  });

  group('MealNutrimentsEntity.fromOffNutriments', () {
    OFFProductNutrimentsDTO buildDto({
      dynamic energyKcal,
      dynamic carbs,
      dynamic fat,
      dynamic proteins,
      dynamic sugars,
      dynamic saturatedFat,
      dynamic fiber,
      dynamic monounsaturatedFat,
      dynamic polyunsaturatedFat,
      dynamic transFat,
      dynamic cholesterol,
      dynamic sodium,
      dynamic potassium,
      dynamic magnesium,
      dynamic calcium,
      dynamic iron,
      dynamic zinc,
      dynamic phosphorus,
      dynamic vitaminA,
      dynamic vitaminC,
      dynamic vitaminD,
      dynamic vitaminB6,
      dynamic vitaminB12,
      dynamic niacin,
    }) =>
        OFFProductNutrimentsDTO(
          energy_kcal_100g: energyKcal,
          carbohydrates_100g: carbs,
          fat_100g: fat,
          proteins_100g: proteins,
          sugars_100g: sugars,
          saturated_fat_100g: saturatedFat,
          fiber_100g: fiber,
          monounsaturated_fat_100g: monounsaturatedFat,
          polyunsaturated_fat_100g: polyunsaturatedFat,
          trans_fat_100g: transFat,
          cholesterol_100g: cholesterol,
          sodium_100g: sodium,
          potassium_100g: potassium,
          magnesium_100g: magnesium,
          calcium_100g: calcium,
          iron_100g: iron,
          zinc_100g: zinc,
          phosphorus_100g: phosphorus,
          vitamin_a_100g: vitaminA,
          vitamin_c_100g: vitaminC,
          vitamin_d_100g: vitaminD,
          vitamin_b6_100g: vitaminB6,
          vitamin_b12_100g: vitaminB12,
          niacin_100g: niacin,
        );

    test('maps core macros correctly', () {
      final entity = MealNutrimentsEntity.fromOffNutriments(buildDto(
        energyKcal: 200.0,
        carbs: 25.0,
        fat: 8.0,
        proteins: 12.0,
        sugars: 4.0,
        saturatedFat: 2.5,
        fiber: 3.0,
      ));

      expect(entity.energyKcal100, 200.0);
      expect(entity.carbohydrates100, 25.0);
      expect(entity.fat100, 8.0);
      expect(entity.proteins100, 12.0);
      expect(entity.sugars100, 4.0);
      expect(entity.saturatedFat100, 2.5);
      expect(entity.fiber100, 3.0);
    });

    test('handles integer values from OFF (dynamic type)', () {
      final entity = MealNutrimentsEntity.fromOffNutriments(buildDto(
        energyKcal: 200,
        carbs: 25,
        fat: 8,
        proteins: 12,
        sugars: 4,
        saturatedFat: 2,
        fiber: 3,
      ));

      expect(entity.energyKcal100, 200.0);
      expect(entity.carbohydrates100, 25.0);
    });

    test('handles string values from OFF (dynamic type)', () {
      final entity = MealNutrimentsEntity.fromOffNutriments(buildDto(
        energyKcal: '200',
        carbs: '25',
        fat: '8',
        proteins: '12',
        sugars: null,
        saturatedFat: null,
        fiber: null,
      ));

      expect(entity.energyKcal100, 200.0);
      expect(entity.carbohydrates100, 25.0);
    });

    test('maps all micronutrient fields correctly', () {
      final entity = MealNutrimentsEntity.fromOffNutriments(buildDto(
        energyKcal: 0,
        carbs: 0,
        fat: 0,
        proteins: 0,
        sugars: 0,
        saturatedFat: 0,
        fiber: 0,
        monounsaturatedFat: 1.1,
        polyunsaturatedFat: 2.2,
        transFat: 0.5,
        cholesterol: 55.0,
        sodium: 0.12,
        potassium: 0.3,
        magnesium: 25.0,
        calcium: 100.0,
        iron: 2.0,
        zinc: 1.0,
        phosphorus: 150.0,
        vitaminA: 90.0,
        vitaminC: 45.0,
        vitaminD: 5.0,
        vitaminB6: 0.3,
        vitaminB12: 1.5,
        niacin: 8.0,
      ));

      expect(entity.monounsaturatedFat100, 1.1);
      expect(entity.polyunsaturatedFat100, 2.2);
      expect(entity.transFat100, 0.5);
      expect(entity.cholesterol100, 55.0);
      expect(entity.sodium100, 0.12);
      expect(entity.potassium100, 0.3);
      expect(entity.magnesium100, 25.0);
      expect(entity.calcium100, 100.0);
      expect(entity.iron100, 2.0);
      expect(entity.zinc100, 1.0);
      expect(entity.phosphorus100, 150.0);
      expect(entity.vitaminA100, 90.0);
      expect(entity.vitaminC100, 45.0);
      expect(entity.vitaminD100, 5.0);
      expect(entity.vitaminB6100, 0.3);
      expect(entity.vitaminB12100, 1.5);
      expect(entity.niacin100, 8.0);
    });

    test('absent micronutrients are null', () {
      final entity = MealNutrimentsEntity.fromOffNutriments(buildDto(
        energyKcal: 100,
        carbs: 10,
        fat: 5,
        proteins: 5,
        sugars: 2,
        saturatedFat: 1,
        fiber: 1,
      ));

      expect(entity.monounsaturatedFat100, isNull);
      expect(entity.sodium100, isNull);
      expect(entity.vitaminC100, isNull);
    });

    test('returns empty entity when DTO is null', () {
      final entity = MealNutrimentsEntity.fromOffNutriments(null);
      expect(entity.energyKcal100, isNull);
      expect(entity.carbohydrates100, isNull);
    });
  });

  group('MealNutrimentsEntity.hasMicronutrientData', () {
    test('returns false when all micronutrients are null', () {
      const entity = MealNutrimentsEntity(
        energyKcal100: 200,
        carbohydrates100: 30,
        fat100: 10,
        proteins100: 15,
        sugars100: 5,
        saturatedFat100: 3,
        fiber100: 2,
      );
      expect(entity.hasMicronutrientData, isFalse);
    });

    test('returns true when any micronutrient is non-null', () {
      const entity = MealNutrimentsEntity(
        energyKcal100: 200,
        carbohydrates100: 30,
        fat100: 10,
        proteins100: 15,
        sugars100: 5,
        saturatedFat100: 3,
        fiber100: 2,
        sodium100: 120,
      );
      expect(entity.hasMicronutrientData, isTrue);
    });

    test('returns false for empty entity', () {
      final entity = MealNutrimentsEntity.empty();
      expect(entity.hasMicronutrientData, isFalse);
    });
  });
}
