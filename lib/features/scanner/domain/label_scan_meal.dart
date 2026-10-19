import 'package:opennutritracker/core/utils/barcode_validator.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// Whether [meal] is an Open Food Facts product without energy or one of the
/// macros, which the app cannot log; scanning its table fills them in.
bool lacksNutrients(MealEntity meal) {
  if (meal.source != MealSourceEntity.off) return false;
  final n = meal.nutriments;
  return n.energyKcal100 == null ||
      n.carbohydrates100 == null ||
      n.fat100 == null ||
      n.proteins100 == null;
}

/// The custom food a label scan of [product] becomes: the product's name
/// and brand, a fresh id, everything else from the scan.
MealEntity labelScanMealFor(MealEntity product) => MealEntity(
  code: IdGenerator.getUniqueID(),
  name: product.name,
  brands: product.brands,
  url: null,
  mealQuantity: null,
  mealUnit: 'gml',
  servingQuantity: null,
  servingUnit: 'gml',
  servingSize: '',
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.custom,
);

/// The retail barcode of [product], so the scanned food is found by the
/// next scan of the pack.
String? labelScanBarcodeFor(MealEntity product) {
  final code = product.code;
  return code != null && isBarcodeFormatValid(code) ? code : null;
}
