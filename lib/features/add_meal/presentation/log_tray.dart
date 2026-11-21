import 'package:flutter/widgets.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/util/portion_label.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/util/meal_quantity_converter.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// One food waiting on the add-food screen's "To log" list.
///
/// Holds exactly what `MealDetailBloc.addIntake` is later called with, so
/// the list writes the same intake the screen it came from would have
/// written: [unit] is the stored unit, [amount] the quantity already
/// converted to grams or millilitres.
@immutable
class LogTrayItem {
  final MealEntity meal;
  final String unit;
  final double amount;

  /// How the amount reads on screen — "1 slice", "200 g" — fixed when the
  /// item is added, because it is the user's own wording of the amount and
  /// the converted [amount] cannot reproduce it.
  final String amountLabel;

  /// The amount and unit as picked on the detail screen — 2 and `serving`,
  /// 150 and `g` — so tapping the row reopens that screen with them and the
  /// amount can still be changed before logging. Null on an entry with no
  /// food behind it to reopen (Quick add).
  final double? quantity;
  final String? selectedUnit;

  const LogTrayItem({
    required this.meal,
    required this.unit,
    required this.amount,
    required this.amountLabel,
    this.quantity,
    this.selectedUnit,
  });

  /// True when tapping the row can reopen the food with its amount.
  bool get canChangeAmount => quantity != null && selectedUnit != null;

  /// Energy for this amount, or 0 when the food carries none.
  double get kcal => amount * (meal.nutriments.energyPerUnit ?? 0);
}

/// The "To log" list of the add-food screen.
///
/// Owned by that screen and handed to every screen it opens — meal detail,
/// the scanner, the review screen — so that each of them adds to the list
/// instead of writing to the diary. Nothing is logged until the list's own
/// button is pressed, and then all of it at once.
class LogTray extends ChangeNotifier {
  final List<LogTrayItem> _items = [];

  List<LogTrayItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get length => _items.length;

  int _pending = 0;

  /// Whether a new food should join the list rather than be logged on its
  /// own: the list holds something, or a food is still on its way onto it.
  ///
  /// Logging on its own leaves the add-food screen, so a sheet that went by
  /// [isEmpty] alone would leave while a + was still fetching its food, and
  /// that food would arrive on a list nobody logs.
  bool get collects => _items.isNotEmpty || _pending > 0;

  /// Marks a food as on its way onto the list, until [endPending].
  void beginPending() {
    _pending++;
    notifyListeners();
  }

  /// The food [beginPending] announced has arrived or will not come.
  void endPending() {
    assert(_pending > 0, 'endPending without beginPending');
    _pending--;
    notifyListeners();
  }

  double get totalKcal => _items.fold(0, (sum, item) => sum + item.kcal);

  void add(LogTrayItem item) {
    _items.add(item);
    notifyListeners();
  }

  void addAll(Iterable<LogTrayItem> items) {
    _items.addAll(items);
    notifyListeners();
  }

  /// Puts [updated] where [old] is — by identity, so of two helpings of one
  /// food only the one being edited changes. Adds [updated] when [old] is no
  /// longer on the list, so a changed amount is never silently dropped.
  void replace(LogTrayItem old, LogTrayItem updated) {
    final index = _items.indexWhere((item) => identical(item, old));
    if (index < 0) {
      _items.add(updated);
    } else {
      _items[index] = updated;
    }
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  /// Removes exactly these entries, by identity rather than position: two
  /// helpings of the same food are two entries, and only the ones named
  /// here go.
  void removeAll(Iterable<LogTrayItem> items) {
    final gone = items.toList();
    _items.removeWhere((item) => gone.any((g) => identical(g, item)));
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

/// The amount the + on a search result adds without asking: the same
/// default the detail screen opens with, so a quick add and an untouched
/// detail screen put the same thing on the list.
///
/// One serving where the food has one the app can scale, unless the user
/// prefers raw units (#1126); otherwise 100 g/ml, or 1 oz/fl oz in imperial.
/// Null when the food lacks the values the detail screen requires before it
/// lets anything be added — the caller opens that screen instead, so the
/// user sees why.
LogTrayItem? defaultLogTrayItem(
  BuildContext context,
  MealEntity meal, {
  required bool usesImperialUnits,
  required bool defaultToRawFoodUnits,
}) {
  if (meal.missingRequiredNutrients.isNotEmpty) return null;

  final String unit;
  final double quantity;
  if (meal.scalableServingQuantity != null && !defaultToRawFoodUnits) {
    unit = UnitDropdownItem.serving.toString();
    quantity = 1;
  } else {
    if (meal.isLiquid) {
      unit = usesImperialUnits
          ? UnitDropdownItem.flOz.toString()
          : UnitDropdownItem.ml.toString();
    } else if (meal.isSolid) {
      unit = usesImperialUnits
          ? UnitDropdownItem.oz.toString()
          : UnitDropdownItem.g.toString();
    } else {
      unit = UnitDropdownItem.gml.toString();
    }
    quantity = usesImperialUnits ? 1 : 100;
  }
  return LogTrayItem(
    meal: meal,
    unit: storedUnit(unit),
    amount: convertQuantityToBaseUnit(quantity, unit, meal),
    amountLabel: logTrayAmountLabel(context, quantity, unit, meal),
    quantity: quantity,
    selectedUnit: unit,
  );
}

/// "1 slice", "200 g", "3 ×" — the amount as the user chose it.
String logTrayAmountLabel(
  BuildContext context,
  double quantity,
  String unit,
  MealEntity meal,
) => '${_formatQuantity(quantity)} ${logTrayUnitLabel(context, unit, meal)}';

/// The word for [unit] on [meal]: a fixed unit, or the food's own name for
/// its portion when that name is in the reader's language (#966).
String logTrayUnitLabel(BuildContext context, String unit, MealEntity meal) {
  final languageCode = Localizations.localeOf(context).languageCode;
  if (isPortionUnit(unit) && meal.portions.isNotEmpty) {
    final index = effectivePortionIndex(unit);
    if (index < meal.portions.length) {
      final portion = meal.portions[index];
      final label = householdPortionLabel(
        portion.label,
        languageCode: languageCode,
        textIsLocalized: portion.localized,
      );
      if (label != null) return label;
    }
  }
  final s = S.of(context);
  return switch (UnitDropdownItem.g.fromString(storedUnit(unit))) {
    UnitDropdownItem.g => s.gramUnit,
    UnitDropdownItem.ml => s.milliliterUnit,
    UnitDropdownItem.gml => s.gramMilliliterUnit,
    UnitDropdownItem.oz => s.ozUnit,
    UnitDropdownItem.flOz => s.flOzUnit,
    UnitDropdownItem.serving =>
      householdPortionLabel(
            meal.servingSize,
            languageCode: languageCode,
            textIsLocalized: meal.servingSizeIsLocalized,
          ) ??
          s.servingLabel,
  };
}

/// The energy of [item] as the rest of the app writes it — kcal or kJ.
String logTrayKcalLabel(BuildContext context, double kcal) =>
    EnergyDisplay.formatWithUnit(context, kcal);

String _formatQuantity(double value) {
  final rounded = (value * 100).round() / 100;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toString();
}
