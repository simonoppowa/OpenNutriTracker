import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';

/// The unit and quantity the meal-detail screen opens [meal] on when [last]
/// is the last time it was logged (#1265), or null to keep the screen's
/// usual default.
///
/// An intake stores its amount in grams or millilitres, beside the unit the
/// user picked. The quantity is that amount read back in that unit for the
/// food as it is now, so the screen opens on the same amount as last time.
/// For a serving that changed size since, that keeps the amount, not the
/// count: 60 g logged as 2 × 30 g opens as 1.5 servings of 40 g.
///
/// Null when the food no longer offers the unit, when a serving was logged
/// while the food had none (that amount was never scaled, #629), or when
/// the amount is not a positive number.
({String unit, String quantity})? lastPortionFor(
  MealEntity meal,
  IntakeEntity? last,
) {
  if (last == null) return null;
  final amount = last.amount;
  if (!amount.isFinite || amount <= 0) return null;

  final unit = storedUnit(last.unit);
  if (!offersUnit(meal, unit)) return null;

  final double quantity;
  if (unit == UnitDropdownItem.serving.toString()) {
    final serving = meal.scalableServingQuantity;
    final loggedServing = last.meal.scalableServingQuantity;
    if (serving == null || serving <= 0) return null;
    if (loggedServing == null || loggedServing <= 0) return null;
    quantity = amount / serving;
  } else if (unit == UnitDropdownItem.oz.toString()) {
    quantity = UnitCalc.gToOz(amount);
  } else if (unit == UnitDropdownItem.flOz.toString()) {
    quantity = UnitCalc.mlToFlOz(amount);
  } else {
    quantity = amount;
  }

  final rounded = (quantity * 100).round() / 100;
  if (rounded <= 0) return null;
  return (
    unit: unit,
    quantity: rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toString(),
  );
}
