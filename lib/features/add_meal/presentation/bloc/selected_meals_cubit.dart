import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// A single selected item with a normalized quantity in base units:
/// - solids in grams (g)
/// - liquids in milliliters (ml)
class SelectedMealItem extends Equatable {
  final MealEntity meal;
  final double quantityBaseGml; // grams or milliliters in base unit

  const SelectedMealItem({required this.meal, required this.quantityBaseGml});

  SelectedMealItem copyWith({MealEntity? meal, double? quantityBaseGml}) =>
      SelectedMealItem(
        meal: meal ?? this.meal,
        quantityBaseGml: quantityBaseGml ?? this.quantityBaseGml,
      );

  @override
  List<Object?> get props => [meal, quantityBaseGml];
}

class SelectedMealsState extends Equatable {
  final List<SelectedMealItem> items;
  final bool selectionMode;

  const SelectedMealsState({
    this.items = const [],
    this.selectionMode = false,
  });

  SelectedMealsState copyWith({
    List<SelectedMealItem>? items,
    bool? selectionMode,
  }) =>
      SelectedMealsState(
        items: items ?? this.items,
        selectionMode: selectionMode ?? this.selectionMode,
      );

  @override
  List<Object?> get props => [items, selectionMode];
}

class SelectedMealsCubit extends Cubit<SelectedMealsState> {
  SelectedMealsCubit() : super(const SelectedMealsState());

  /// Turn selection mode on/off (e.g., when user taps a "Select" toggle).
  void setSelectionMode(bool enabled) {
    emit(state.copyWith(selectionMode: enabled));
    if (!enabled) {
      clear();
    }
  }

  /// Toggle an item in the selection. If adding, we default to:
  /// - 1 serving if the item has serving info
  /// - otherwise 100 g (solids) or 100 ml (liquids/unknown)
  void toggle(MealEntity meal) {
    final exists = state.items.indexWhere((e) => e.meal.code == meal.code);
    if (exists >= 0) {
      final newItems = List<SelectedMealItem>.from(state.items)..removeAt(exists);
      emit(state.copyWith(items: newItems));
      return;
    }

    final defaultQty = meal.hasServingValues
        ? (meal.servingQuantity ?? 1.0)
        : 100.0; // sensible default

    final normalized = _toBaseGml(meal, defaultQty,
        meal.hasServingValues ? 'serving' : (meal.isSolid ? 'g' : 'ml'));

    final newItems = List<SelectedMealItem>.from(state.items)
      ..add(SelectedMealItem(meal: meal, quantityBaseGml: normalized));
    emit(state.copyWith(items: newItems));
  }

  /// Update quantity for a given meal (quantity expressed in a UI unit).
  /// [unit] accepted: 'g', 'ml', 'oz', 'fl.oz', 'serving'
  void updateQuantity(MealEntity meal, double quantity, String unit) {
    final idx = state.items.indexWhere((e) => e.meal.code == meal.code);
    if (idx < 0) return;

    final base = _toBaseGml(meal, quantity, unit);
    final newItems = List<SelectedMealItem>.from(state.items)
      ..[idx] = state.items[idx].copyWith(quantityBaseGml: base);

    emit(state.copyWith(items: newItems));
  }

  void remove(MealEntity meal) {
    final newItems =
        state.items.where((e) => e.meal.code != meal.code).toList();
    emit(state.copyWith(items: newItems));
  }

  void clear() => emit(state.copyWith(items: const []));

  bool isSelected(MealEntity meal) =>
      state.items.any((e) => e.meal.code == meal.code);

  int get count => state.items.length;

  /// Compose a single custom MealEntity by aggregating nutrients
  /// weighted by each item's quantity in base units.
  ///
  /// Returns a MealEntity with:
  ///  - per-100 g/ml nutrients = (sum nutrients) / (total qty) * 100
  ///  - mealQuantity = total qty (as string), mealUnit = 'g/ml'
  ///  - source = custom
  MealEntity composeAsCustomMeal({String? name}) {
    if (state.items.isEmpty) {
      // Empty selection -> return a minimal custom meal
      return MealEntity.empty();
    }

    double totalQty = 0.0;
    double kcalSum = 0.0;
    double carbsSum = 0.0;
    double fatSum = 0.0;
    double proteinSum = 0.0;

    for (final item in state.items) {
      final q = item.quantityBaseGml;
      final n = item.meal.nutriments;

      final energyPerUnit = n.energyPerUnit ?? 0.0;
      final carbsPerUnit = n.carbohydratesPerUnit ?? 0.0;
      final fatPerUnit = n.fatPerUnit ?? 0.0;
      final proteinPerUnit = n.proteinsPerUnit ?? 0.0;

      totalQty += q;
      kcalSum += q * energyPerUnit;
      carbsSum += q * carbsPerUnit;
      fatSum += q * fatPerUnit;
      proteinSum += q * proteinPerUnit;
    }

    // Derive per-100 g/ml values
    double? per100(double sum) =>
        totalQty > 0 ? (sum / totalQty) * 100.0 : null;

    final nutriments = MealNutrimentsEntity(
      energyKcal100: per100(kcalSum),
      carbohydrates100: per100(carbsSum),
      fat100: per100(fatSum),
      proteins100: per100(proteinSum),
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    );

    return MealEntity(
      code: IdGenerator.getUniqueID(),
      name: name ?? 'Custom meal',
      brands: null,
      thumbnailImageUrl: null,
      mainImageUrl: null,
      url: null,
      mealQuantity: totalQty.toStringAsFixed(0),
      mealUnit: 'g/ml', // generic unit since we may mix solids & liquids
      servingQuantity: null,
      servingUnit: 'g/ml',
      servingSize: '',
      nutriments: nutriments,
      source: MealSourceEntity.custom,
    );
  }

  /// Normalize a [quantity] in [unit] to base g/ml for math.
  /// - 'serving' -> multiply by servingQuantity if present
  /// - 'oz' -> grams via UnitCalc
  /// - 'fl.oz' -> ml via UnitCalc
  /// - 'g' and 'ml' pass through
  double _toBaseGml(MealEntity meal, double quantity, String unit) {
    switch (unit) {
      case 'serving':
        final sq = meal.servingQuantity ?? 1.0;
        return quantity * sq;
      case 'oz':
        return UnitCalc.ozToG(quantity);
      case 'fl.oz':
        return UnitCalc.flOzToMl(quantity);
      case 'g':
      case 'ml':
      default:
        return quantity;
    }
  }
}

