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
  // #237: Extended lipid profile
  final double? monounsaturatedFat100;
  final double? polyunsaturatedFat100;
  final double? transFat100;
  final double? cholesterol100;
  // #237: Minerals (mg per 100g)
  final double? sodium100;
  final double? potassium100;
  final double? magnesium100;
  final double? calcium100;
  final double? iron100;
  final double? zinc100;
  final double? phosphorus100;
  // #237: Vitamins
  final double? vitaminA100; // µg RAE
  final double? vitaminC100; // mg
  final double? vitaminD100; // µg
  final double? vitaminB6100; // mg
  final double? vitaminB12100; // µg
  final double? niacin100; // mg (B3)

  double? get energyPerUnit => _getValuePerUnit(energyKcal100);

  double? get carbohydratesPerUnit => _getValuePerUnit(carbohydrates100);

  double? get fatPerUnit => _getValuePerUnit(fat100);

  double? get proteinsPerUnit => _getValuePerUnit(proteins100);

  /// Returns true when at least one of the extended micronutrient fields
  /// (lipid profile / minerals / vitamins from #237) has a value.
  bool get hasMicronutrientData =>
      monounsaturatedFat100 != null ||
      polyunsaturatedFat100 != null ||
      transFat100 != null ||
      cholesterol100 != null ||
      sodium100 != null ||
      potassium100 != null ||
      magnesium100 != null ||
      calcium100 != null ||
      iron100 != null ||
      zinc100 != null ||
      phosphorus100 != null ||
      vitaminA100 != null ||
      vitaminC100 != null ||
      vitaminD100 != null ||
      vitaminB6100 != null ||
      vitaminB12100 != null ||
      niacin100 != null;

  const MealNutrimentsEntity({
    required this.energyKcal100,
    required this.carbohydrates100,
    required this.fat100,
    required this.proteins100,
    required this.sugars100,
    required this.saturatedFat100,
    required this.fiber100,
    this.monounsaturatedFat100,
    this.polyunsaturatedFat100,
    this.transFat100,
    this.cholesterol100,
    this.sodium100,
    this.potassium100,
    this.magnesium100,
    this.calcium100,
    this.iron100,
    this.zinc100,
    this.phosphorus100,
    this.vitaminA100,
    this.vitaminC100,
    this.vitaminD100,
    this.vitaminB6100,
    this.vitaminB12100,
    this.niacin100,
  });

  factory MealNutrimentsEntity.empty() => const MealNutrimentsEntity(
        energyKcal100: null,
        carbohydrates100: null,
        fat100: null,
        proteins100: null,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      );

  factory MealNutrimentsEntity.fromMealNutrimentsDBO(
    MealNutrimentsDBO nutriments,
  ) {
    return MealNutrimentsEntity(
      energyKcal100: nutriments.energyKcal100,
      carbohydrates100: nutriments.carbohydrates100,
      fat100: nutriments.fat100,
      proteins100: nutriments.proteins100,
      sugars100: nutriments.sugars100,
      saturatedFat100: nutriments.saturatedFat100,
      fiber100: nutriments.fiber100,
      monounsaturatedFat100: nutriments.monounsaturatedFat100,
      polyunsaturatedFat100: nutriments.polyunsaturatedFat100,
      transFat100: nutriments.transFat100,
      cholesterol100: nutriments.cholesterol100,
      sodium100: nutriments.sodium100,
      potassium100: nutriments.potassium100,
      magnesium100: nutriments.magnesium100,
      calcium100: nutriments.calcium100,
      iron100: nutriments.iron100,
      zinc100: nutriments.zinc100,
      phosphorus100: nutriments.phosphorus100,
      vitaminA100: nutriments.vitaminA100,
      vitaminC100: nutriments.vitaminC100,
      vitaminD100: nutriments.vitaminD100,
      vitaminB6100: nutriments.vitaminB6100,
      vitaminB12100: nutriments.vitaminB12100,
      niacin100: nutriments.niacin100,
    );
  }

  factory MealNutrimentsEntity.fromOffNutriments(
    OFFProductNutrimentsDTO? offNutriments,
  ) {
    if (offNutriments == null) return MealNutrimentsEntity.empty();

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
      fiber100: (offNutriments.fiber_100g as Object?).asDoubleOrNull(),
      // #237: Extended lipid profile
      monounsaturatedFat100:
          (offNutriments.monounsaturated_fat_100g as Object?).asDoubleOrNull(),
      polyunsaturatedFat100:
          (offNutriments.polyunsaturated_fat_100g as Object?).asDoubleOrNull(),
      transFat100: (offNutriments.trans_fat_100g as Object?).asDoubleOrNull(),
      cholesterol100:
          (offNutriments.cholesterol_100g as Object?).asDoubleOrNull(),
      // #237: Minerals
      sodium100: (offNutriments.sodium_100g as Object?).asDoubleOrNull(),
      potassium100: (offNutriments.potassium_100g as Object?).asDoubleOrNull(),
      magnesium100: (offNutriments.magnesium_100g as Object?).asDoubleOrNull(),
      calcium100: (offNutriments.calcium_100g as Object?).asDoubleOrNull(),
      iron100: (offNutriments.iron_100g as Object?).asDoubleOrNull(),
      zinc100: (offNutriments.zinc_100g as Object?).asDoubleOrNull(),
      phosphorus100:
          (offNutriments.phosphorus_100g as Object?).asDoubleOrNull(),
      // #237: Vitamins
      vitaminA100: (offNutriments.vitamin_a_100g as Object?).asDoubleOrNull(),
      vitaminC100: (offNutriments.vitamin_c_100g as Object?).asDoubleOrNull(),
      vitaminD100: (offNutriments.vitamin_d_100g as Object?).asDoubleOrNull(),
      vitaminB6100: (offNutriments.vitamin_b6_100g as Object?).asDoubleOrNull(),
      vitaminB12100:
          (offNutriments.vitamin_b12_100g as Object?).asDoubleOrNull(),
      niacin100: (offNutriments.niacin_100g as Object?).asDoubleOrNull(),
    );
  }

  factory MealNutrimentsEntity.fromFDCNutriments(
    List<FDCFoodNutrimentDTO> fdcNutriment,
  ) {
    double? fdcAmount(int nutrientId) => fdcNutriment
        .firstWhereOrNull((nutriment) => nutriment.nutrientId == nutrientId)
        ?.amount;

    // FDC Food nutriments can have different values for Energy [Energy,
    // Energy (Atwater General Factors), Energy (Atwater Specific Factors)].
    // Prefer the most-precise Atwater value; fall back to raw total last.
    final energyTotal = fdcAmount(FDCConst.fdcKcalAtwaterSpecificId) ??
        fdcAmount(FDCConst.fdcKcalAtwaterGeneralId) ??
        fdcAmount(FDCConst.fdcTotalKcalId);

    return MealNutrimentsEntity(
      energyKcal100: energyTotal,
      carbohydrates100: fdcAmount(FDCConst.fdcTotalCarbsId),
      fat100: fdcAmount(FDCConst.fdcTotalFatId),
      proteins100: fdcAmount(FDCConst.fdcTotalProteinsId),
      sugars100: fdcAmount(FDCConst.fdcTotalSugarId),
      saturatedFat100: fdcAmount(FDCConst.fdcTotalSaturatedFatId),
      fiber100: fdcAmount(FDCConst.fdcTotalDietaryFiberId),
      // #237: Extended lipid profile
      monounsaturatedFat100: fdcAmount(FDCConst.fdcMonounsaturatedFatId),
      polyunsaturatedFat100: fdcAmount(FDCConst.fdcPolyunsaturatedFatId),
      transFat100: fdcAmount(FDCConst.fdcTransFatId),
      cholesterol100: fdcAmount(FDCConst.fdcCholesterolId),
      // #237: Minerals
      sodium100: fdcAmount(FDCConst.fdcSodiumId),
      potassium100: fdcAmount(FDCConst.fdcPotassiumId),
      magnesium100: fdcAmount(FDCConst.fdcMagnesiumId),
      calcium100: fdcAmount(FDCConst.fdcCalciumId),
      iron100: fdcAmount(FDCConst.fdcIronId),
      zinc100: fdcAmount(FDCConst.fdcZincId),
      phosphorus100: fdcAmount(FDCConst.fdcPhosphorusId),
      // #237: Vitamins
      vitaminA100: fdcAmount(FDCConst.fdcVitaminAId),
      vitaminC100: fdcAmount(FDCConst.fdcVitaminCId),
      vitaminD100: fdcAmount(FDCConst.fdcVitaminDId),
      vitaminB6100: fdcAmount(FDCConst.fdcVitaminB6Id),
      vitaminB12100: fdcAmount(FDCConst.fdcVitaminB12Id),
      niacin100: fdcAmount(FDCConst.fdcNiacinId),
    );
  }

  static double? _getValuePerUnit(double? valuePer100) {
    if (valuePer100 != null) {
      return valuePer100 / 100;
    } else {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        energyKcal100,
        carbohydrates100,
        fat100,
        proteins100,
      ];
}

/// Outcome of running the three physical-plausibility checks against a
/// [MealNutrimentsEntity] parsed from a remote source (FDC via Supabase, OFF,
/// or the direct FDC API). When [isConsistent] is false, [failureReason]
/// names the first rule that tripped — that is the value to attach to a
/// Sentry breadcrumb so we can spot systematic upstream problems.
///
/// The rules come from issue #222 and are deliberately conservative: they
/// only fire on data that is physically impossible on a 100g basis, so a
/// borderline-noisy-but-plausible item is left alone.
class NutrimentsValidationResult {
  final bool isConsistent;
  final String? failureReason;

  const NutrimentsValidationResult.ok()
      : isConsistent = true,
        failureReason = null;

  const NutrimentsValidationResult.failed(this.failureReason)
      : isConsistent = false;
}

/// Tolerance applied to weight-summation and subset-of comparisons. Source
/// data is typically rounded to 0.1g or 1g, and the per-nutrient values do
/// not always sum exactly; a small slack keeps us from dropping items that
/// are merely noisy rather than corrupt.
const double _nutrimentsValidationToleranceG = 1.0;

/// Returns true when [nutriments] passes the three physical-plausibility
/// rules from issue #222:
///
///   1. `sugars100 <= carbohydrates100` (sugars are a subset of carbs)
///   2. `saturatedFat100 <= fat100` (sat fat is a subset of total fat)
///   3. `carbohydrates100 + fat100 + proteins100 <= 100g` (per-100g basis)
///
/// A null on either side of a comparison skips the rule (we cannot prove a
/// violation without both values). A small tolerance absorbs rounding from
/// the source.
///
/// Convenience wrapper around [validateNutriments] for callers that only
/// need the pass/fail bit.
bool isNutrimentsConsistent(MealNutrimentsEntity nutriments) =>
    validateNutriments(nutriments).isConsistent;

/// Full validation result. Use this when you need the failing rule name —
/// for example, to log a Sentry breadcrumb at the call site that dropped the
/// item from search results.
NutrimentsValidationResult validateNutriments(MealNutrimentsEntity nutriments) {
  final sugars = nutriments.sugars100;
  final carbs = nutriments.carbohydrates100;
  if (sugars != null && carbs != null && sugars > carbs + _nutrimentsValidationToleranceG) {
    return const NutrimentsValidationResult.failed('sugars_exceed_carbs');
  }

  final satFat = nutriments.saturatedFat100;
  final fat = nutriments.fat100;
  if (satFat != null && fat != null && satFat > fat + _nutrimentsValidationToleranceG) {
    return const NutrimentsValidationResult.failed('saturated_fat_exceeds_total_fat');
  }

  // Per-100g basis: the weight-bearing macros (carbs + fat + protein) cannot
  // sum to more than 100g. Fibre is intentionally excluded because it is
  // typically already inside the carbohydrate total in both FDC and OFF
  // accounting, so adding it would double-count. Micronutrients are in
  // mg/µg so they do not enter the sum.
  final protein = nutriments.proteins100;
  final macroSum = (carbs ?? 0) + (fat ?? 0) + (protein ?? 0);
  if (macroSum > 100 + _nutrimentsValidationToleranceG) {
    return const NutrimentsValidationResult.failed('macros_exceed_100g');
  }

  return const NutrimentsValidationResult.ok();
}
