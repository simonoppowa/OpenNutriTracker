import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

class EditMealBloc {
  MealEntity createNewMealEntity(
      MealEntity oldMealEntity,
      String nameText,
      String brandsText,
      String mealQuantityText,
      String servingQuantityText,
      String baseQuantity,
      String? unitText,
      String kcalText,
      String carbsText,
      String fatText,
      String proteinText) {

    final baseQuantityDouble = double.tryParse(baseQuantity); 
    
    final double factorTo100g = baseQuantityDouble != null ? (100/baseQuantityDouble): 1;
    
    double? multiplyIfNotNull(double? nutritmentValue) {
      return nutritmentValue != null ? nutritmentValue * factorTo100g: null;
    }

    final newMealNutriments = MealNutrimentsEntity(
        energyKcal100: multiplyIfNotNull(kcalText.toDoubleOrNull()),
        carbohydrates100: multiplyIfNotNull(carbsText.toDoubleOrNull()),
        fat100: multiplyIfNotNull(fatText.toDoubleOrNull()),
        proteins100: multiplyIfNotNull(proteinText.toDoubleOrNull()),
        sugars100: multiplyIfNotNull(oldMealEntity.nutriments.sugars100),
        saturatedFat100: multiplyIfNotNull(oldMealEntity.nutriments.saturatedFat100),
        fiber100: multiplyIfNotNull(oldMealEntity.nutriments.fiber100));

    return MealEntity(
        code: oldMealEntity.code,
        name: nameText.toStringOrNull(),
        brands: brandsText.toStringOrNull(),
        url: oldMealEntity.url,
        thumbnailImageUrl: oldMealEntity.thumbnailImageUrl,
        mainImageUrl: oldMealEntity.mainImageUrl,
        mealQuantity: mealQuantityText.toStringOrNull(),
        mealUnit: unitText,
        servingQuantity: servingQuantityText.toDoubleOrNull(),
        servingUnit: servingQuantityText.toStringOrNull(),
        nutriments: newMealNutriments,
        source: oldMealEntity.source);
  }
}
