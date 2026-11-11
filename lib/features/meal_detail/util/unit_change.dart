import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/util/meal_quantity_converter.dart';

/// The amount in [toUnit] that weighs what [text] in [fromUnit] does, so
/// changing the unit keeps the amount of food: 180 g becomes 1 serving of
/// 180 g, not 180 servings.
///
/// Grams and millilitres are rounded to whole numbers, every other unit to
/// a tenth, and an amount is never rounded down to nothing. Null when
/// [text] is not an amount, or [toUnit] weighs nothing for [meal].
String? amountInUnit(
  String text,
  String fromUnit,
  String toUnit,
  MealEntity meal,
) {
  final quantity = double.tryParse(text.trim().replaceAll(',', '.'));
  if (quantity == null || quantity <= 0) return null;
  final base = convertQuantityToBaseUnit(quantity, fromUnit, meal);
  final perOne = convertQuantityToBaseUnit(1, toUnit, meal);
  if (perOne <= 0) return null;
  final value = base / perOne;
  final whole = {
    UnitDropdownItem.g.toString(),
    UnitDropdownItem.ml.toString(),
    UnitDropdownItem.gml.toString(),
  }.contains(storedUnit(toUnit));
  var rounded = whole ? value.roundToDouble() : (value * 10).round() / 10;
  // Too little to round: the field's smallest step, never zero.
  if (rounded <= 0) {
    rounded = whole ? 1 : (value * 100).round() / 100;
    if (rounded <= 0) rounded = 0.01;
  }
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}
