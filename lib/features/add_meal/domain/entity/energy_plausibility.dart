import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// Why a set of per-100 g values looks wrong.
class PlausibilityIssue {
  /// `energy_mismatch`, or the rule `validateNutriments` names
  /// (`sugars_exceed_carbs`, `saturated_fat_exceeds_total_fat`,
  /// `macros_exceed_100g`).
  final String rule;
  final double? statedKcal;
  final double? expectedKcal;

  const PlausibilityIssue(this.rule, {this.statedKcal, this.expectedKcal});
}

/// The kcal gap the check tolerates: a quarter of the expected energy, and
/// at least 25 kcal, so rounding on labels and light drinks never trip it.
const _relativeTolerance = 0.25;
const _absoluteToleranceKcal = 25.0;

/// Checks per-100 g values the way a careful reader of a label would: the
/// stated kcal against the energy of fat, carbohydrate, protein and fibre
/// (9, 4, 4 and 2 kcal/g), plus the physical rules of `validateNutriments`.
/// EU labels give carbohydrate without fibre, USDA FDC data includes it, so
/// the stated kcal is plausible when it is close to either reading. Returns
/// null when the values look plausible or when they are too incomplete to
/// judge.
///
/// Products with sugar alcohols are flagged too (they count as carbohydrate
/// at 2.4 kcal/g); the result is meant for a "please check" hint, not for
/// dropping a product.
PlausibilityIssue? checkEnergyPlausibility(MealNutrimentsEntity nutriments) {
  final rules = validateNutriments(nutriments);
  if (!rules.isConsistent) {
    return PlausibilityIssue(rules.failureReason ?? 'inconsistent');
  }

  final kcal = nutriments.energyKcal100;
  final fat = nutriments.fat100;
  final carbs = nutriments.carbohydrates100;
  final protein = nutriments.proteins100;
  if (kcal == null || fat == null || carbs == null || protein == null) {
    return null;
  }
  final fiber = (nutriments.fiber100 ?? 0).clamp(0, carbs).toDouble();
  final fiberExcluded = 9 * fat + 4 * carbs + 4 * protein + 2 * fiber;
  final fiberIncluded = fiberExcluded - 4 * fiber;
  bool near(double expected) =>
      (kcal - expected).abs() <=
      (expected * _relativeTolerance).clamp(
        _absoluteToleranceKcal,
        double.infinity,
      );
  if (near(fiberExcluded) || near(fiberIncluded)) return null;
  final nearer = (kcal - fiberExcluded).abs() <= (kcal - fiberIncluded).abs()
      ? fiberExcluded
      : fiberIncluded;
  return PlausibilityIssue(
    'energy_mismatch',
    statedKcal: kcal,
    expectedKcal: nearer,
  );
}
