import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

/// One preset a user can tap in the meal-detail sheet to jump the
/// quantity + unit inputs to a common portion without typing.
///
/// [id] is a stable ASCII slug for building `Semantics(identifier: ...)`
/// values; [label] is the visible chip text and moves with the locale.
class QuickServingOption {
  final String id;
  final double quantity;
  final String unit;
  final String label;

  const QuickServingOption({
    required this.id,
    required this.quantity,
    required this.unit,
    required this.label,
  });
}

/// Presets for [product]. Returns an empty list when the food carries no
/// serving metadata and is not measured by mass or volume, so the sheet
/// can hide the row entirely rather than show a chip that rounds to
/// nothing meaningful.
///
/// [gramUnitLabel] is passed in so this helper stays context-free.
List<QuickServingOption> quickServingOptionsFor(
  MealEntity product,
  String gramUnitLabel,
) {
  final servingUnit = UnitDropdownItem.serving.toString();
  final gramUnit = UnitDropdownItem.g.toString();
  final options = <QuickServingOption>[];

  if (product.scalableServingQuantity != null) {
    options.addAll([
      QuickServingOption(
        id: 'half-serving',
        quantity: 0.5,
        unit: servingUnit,
        label: '0.5×',
      ),
      QuickServingOption(
        id: 'one-serving',
        quantity: 1,
        unit: servingUnit,
        label: '1×',
      ),
      QuickServingOption(
        id: 'double-serving',
        quantity: 2,
        unit: servingUnit,
        label: '2×',
      ),
    ]);
  }
  // Mirror the unit dropdown's gate at meal_detail_bottom_sheet.dart:167-170,
  // so quick-add custom meals (mealUnit == 'g/ml') and liquids with no
  // serving still get the 100 g shortcut.
  if (product.isSolid || (!product.isLiquid && !product.isSolid)) {
    options.add(
      QuickServingOption(
        id: '100g',
        quantity: 100,
        unit: gramUnit,
        label: '100 $gramUnitLabel',
      ),
    );
  }
  return options;
}
