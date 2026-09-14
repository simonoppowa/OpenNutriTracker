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

    // Every value below is what Open Food Facts actually sends: it normalises
    // each `<nutrient>_100g` field to grams, whatever unit the label used.
    // The expectations are the app's own units, so this is the conversion
    // #716 was missing, read in both directions at once.
    test('converts micronutrients out of the grams OFF sends them in', () {
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
        cholesterol: 0.055,
        sodium: 0.12,
        potassium: 0.3,
        magnesium: 0.025,
        calcium: 0.1,
        iron: 0.002,
        zinc: 0.001,
        phosphorus: 0.15,
        vitaminA: 0.00009,
        vitaminC: 0.045,
        vitaminD: 0.000005,
        vitaminB6: 0.0003,
        vitaminB12: 0.0000015,
        niacin: 0.008,
      ));

      // Lipids are grams on both sides, so they pass straight through.
      expect(entity.monounsaturatedFat100, 1.1);
      expect(entity.polyunsaturatedFat100, 2.2);
      expect(entity.transFat100, 0.5);
      // Milligrams from here down.
      expect(entity.cholesterol100, 55.0);
      expect(entity.sodium100, 120.0);
      expect(entity.potassium100, 300.0);
      expect(entity.magnesium100, 25.0);
      expect(entity.calcium100, 100.0);
      expect(entity.iron100, 2.0);
      expect(entity.zinc100, 1.0);
      expect(entity.phosphorus100, 150.0);
      // Micrograms for A, D and B12; the rest of the vitamins are milligrams.
      expect(entity.vitaminA100, 90.0);
      expect(entity.vitaminC100, 45.0);
      expect(entity.vitaminD100, 5.0);
      expect(entity.vitaminB6100, 0.3);
      expect(entity.vitaminB12100, 1.5);
      expect(entity.niacin100, 8.0);
    });

    // Values copied from live OFF responses rather than invented, so the
    // fixture cannot drift away from what the API really sends: iron for
    // barcode 3168930010265 and sodium for 3017620422003, both reported with
    // `_unit: "g"`.
    test('matches what the live OFF API returns for real barcodes', () {
      final entity = MealNutrimentsEntity.fromOffNutriments(buildDto(
        iron: 0.0021,
        sodium: 0.0428,
      ));

      expect(entity.iron100, closeTo(2.1, 1e-9));
      expect(entity.sodium100, closeTo(42.8, 1e-9));
    });

    // The point of #716 in one assertion: the same food should read the same
    // whichever database it came from. Before the conversion the OFF entity
    // was a thousand times smaller than the FDC one on every mineral, and a
    // million times smaller on vitamins A, D and B12.
    test('agrees with the FDC mapping for the same food', () {
      final fromOff = MealNutrimentsEntity.fromOffNutriments(buildDto(
        cholesterol: 0.055,
        sodium: 0.12,
        potassium: 0.3,
        magnesium: 0.025,
        calcium: 0.1,
        iron: 0.002,
        zinc: 0.001,
        phosphorus: 0.15,
        vitaminA: 0.00009,
        vitaminC: 0.045,
        vitaminD: 0.000005,
        vitaminB6: 0.0003,
        vitaminB12: 0.0000015,
        niacin: 0.008,
      ));
      final fromFdc = MealNutrimentsEntity.fromFDCNutriments([
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

      expect(fromOff.cholesterol100, fromFdc.cholesterol100);
      expect(fromOff.sodium100, fromFdc.sodium100);
      expect(fromOff.potassium100, fromFdc.potassium100);
      expect(fromOff.magnesium100, fromFdc.magnesium100);
      expect(fromOff.calcium100, fromFdc.calcium100);
      expect(fromOff.iron100, fromFdc.iron100);
      expect(fromOff.zinc100, fromFdc.zinc100);
      expect(fromOff.phosphorus100, fromFdc.phosphorus100);
      expect(fromOff.vitaminA100, fromFdc.vitaminA100);
      expect(fromOff.vitaminC100, fromFdc.vitaminC100);
      expect(fromOff.vitaminD100, fromFdc.vitaminD100);
      expect(fromOff.vitaminB6100, fromFdc.vitaminB6100);
      expect(fromOff.vitaminB12100, fromFdc.vitaminB12100);
      expect(fromOff.niacin100, fromFdc.niacin100);
    });

    // A declared zero is a fact about the food and has to survive the
    // conversion as a zero, not become a null the panel then ignores.
    test('keeps a declared zero as zero rather than null', () {
      final entity = MealNutrimentsEntity.fromOffNutriments(buildDto(
        sodium: 0,
        vitaminD: 0.0,
      ));

      expect(entity.sodium100, 0.0);
      expect(entity.vitaminD100, 0.0);
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
      expect(entity.vitaminD100, isNull);
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
