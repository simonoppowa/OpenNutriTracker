import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food_nutriment_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// Validator for the three per-field physical-plausibility rules from
/// issue #222. The reporter described an apple-with-fibre-bigger-than-its-
/// weight as the motivating case; these tests pin each rule and a couple of
/// realistic FDC-shaped samples that must still pass.

MealNutrimentsEntity _nutriments({
  double? carbs,
  double? fat,
  double? proteins,
  double? sugars,
  double? saturatedFat,
  double? fiber,
}) =>
    MealNutrimentsEntity(
      energyKcal100: null,
      carbohydrates100: carbs,
      fat100: fat,
      proteins100: proteins,
      sugars100: sugars,
      saturatedFat100: saturatedFat,
      fiber100: fiber,
    );

void main() {
  group('isNutrimentsConsistent — rule 1: sugars <= carbohydrates', () {
    test('passes when sugars are below carbs', () {
      final n = _nutriments(carbs: 30, sugars: 5);
      expect(isNutrimentsConsistent(n), isTrue);
    });

    test('fails when sugars exceed carbs by more than the rounding tolerance', () {
      // The reporter's flagship example: a value where sugar is reported as
      // many times its parent carbohydrate value. Drop it.
      final n = _nutriments(carbs: 10, sugars: 80);
      final result = validateNutriments(n);
      expect(result.isConsistent, isFalse);
      expect(result.failureReason, 'sugars_exceed_carbs');
    });

    test('still passes when sugars exceed carbs only within rounding tolerance', () {
      // Sources round to 0.1g or 1g; a sugar value that nudges 0.5g above
      // its parent carb total is a rounding artefact, not corruption.
      final n = _nutriments(carbs: 5.0, sugars: 5.5);
      expect(isNutrimentsConsistent(n), isTrue);
    });
  });

  group('isNutrimentsConsistent — rule 2: saturated fat <= total fat', () {
    test('passes when saturated fat is below total fat', () {
      final n = _nutriments(fat: 10, saturatedFat: 3);
      expect(isNutrimentsConsistent(n), isTrue);
    });

    test('fails when saturated fat exceeds total fat', () {
      final n = _nutriments(fat: 2, saturatedFat: 15);
      final result = validateNutriments(n);
      expect(result.isConsistent, isFalse);
      expect(result.failureReason, 'saturated_fat_exceeds_total_fat');
    });
  });

  group('isNutrimentsConsistent — rule 3: macros sum to <= 100g per 100g basis', () {
    test('passes for a normal high-protein item', () {
      // Lean chicken breast: ~31g protein, ~3.6g fat, 0g carbs per 100g.
      final n = _nutriments(carbs: 0, fat: 3.6, proteins: 31, saturatedFat: 1);
      expect(isNutrimentsConsistent(n), isTrue);
    });

    test('fails when carbs + fat + protein exceed 100g per 100g basis', () {
      // Physically impossible: 60 + 30 + 30 = 120g, but the item only weighs
      // 100g. Likely a units/scale error upstream.
      final n = _nutriments(carbs: 60, fat: 30, proteins: 30);
      final result = validateNutriments(n);
      expect(result.isConsistent, isFalse);
      expect(result.failureReason, 'macros_exceed_100g');
    });
  });

  group('isNutrimentsConsistent — realistic samples pass', () {
    test('apple (typical FDC values) passes all rules', () {
      // Apple per 100g: ~14g carbs (of which ~10g sugars), ~0.2g fat,
      // ~0.3g protein, ~2.4g fibre, 0g saturated fat.
      final n = MealNutrimentsEntity.fromFDCNutriments([
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalKcalId, amount: 52),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalCarbsId, amount: 13.8),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalFatId, amount: 0.2),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalProteinsId, amount: 0.3),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalSugarId, amount: 10.4),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalSaturatedFatId, amount: 0),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalDietaryFiberId, amount: 2.4),
      ]);
      expect(isNutrimentsConsistent(n), isTrue);
    });

    test('olive oil (almost entirely fat) passes all rules', () {
      // Olive oil: ~100g fat, ~14g saturated fat, 0g carbs / protein / sugar.
      // Sits right at the 100g boundary on rule 3 — the tolerance keeps it in.
      final n = MealNutrimentsEntity.fromFDCNutriments([
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalKcalId, amount: 884),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalCarbsId, amount: 0),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalFatId, amount: 100),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalProteinsId, amount: 0),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalSugarId, amount: 0),
        FDCFoodNutrimentDTO(nutrientId: FDCConst.fdcTotalSaturatedFatId, amount: 13.8),
      ]);
      expect(isNutrimentsConsistent(n), isTrue);
    });

    test('empty nutriments pass (no rule has both values to compare on)', () {
      // A meal with no parsed nutrient data is a separate problem (the
      // energy-fallback chain handles that); the validator should not drop
      // it on the basis of nulls alone.
      expect(isNutrimentsConsistent(MealNutrimentsEntity.empty()), isTrue);
    });
  });
}
