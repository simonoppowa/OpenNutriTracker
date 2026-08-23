import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

/// Converts a user-entered amount into the base unit the nutriment values
/// are expressed in (grams or millilitres).
///
/// `MealNutrimentsEntity`'s `*PerUnit` getters are per gram/millilitre, so an
/// amount entered as `oz`, `fl.oz` or `serving` has to be converted *before*
/// it is multiplied out or stored on an `IntakeEntity` — `IntakeEntity.totalKcal`
/// is simply `amount * energyPerUnit` and does no conversion of its own.
///
/// Extracted so the meal-detail screen and the bulk-add screen cannot drift:
/// the bottom sheet passes `MealDetailState.totalQuantityConverted` to
/// `addIntake`, and anything else calling `addIntake` has to arrive at the
/// same number the same way. Logging the raw amount instead silently
/// under-counts — 4 oz of steak would be stored as 4 g.
double convertQuantityToBaseUnit(
  double quantity,
  String unit,
  MealEntity meal,
) {
  if (unit == UnitDropdownItem.serving.toString()) {
    // `scalableServingQuantity`, not `servingQuantity` (#629): OFF often
    // leaves the numeric field empty while `serving_size` carries the figure
    // as text, and reading only the numeric one left this branch silently
    // doing nothing — "1 serving" logged one gram. The extraction of this
    // helper and that fix crossed on separate branches, so the rule lives
    // here now rather than in the two call sites it was lifted out of.
    final servingQuantity = meal.scalableServingQuantity;
    // A meal with no serving data can't be scaled — leave the amount alone
    // rather than guessing, matching UpdateKcalEvent.
    return servingQuantity != null ? quantity * servingQuantity : quantity;
  }
  if (unit == UnitDropdownItem.oz.toString()) {
    return UnitCalc.ozToG(quantity);
  }
  if (unit == UnitDropdownItem.flOz.toString()) {
    return UnitCalc.flOzToMl(quantity);
  }
  return quantity;
}

/// Energy for [quantity] of [meal] entered in [unit], or null when the meal
/// carries no energy value.
double? kcalForQuantity(double quantity, String unit, MealEntity meal) {
  final energyPerUnit = meal.nutriments.energyPerUnit;
  if (energyPerUnit == null) return null;
  return convertQuantityToBaseUnit(quantity, unit, meal) * energyPerUnit;
}
