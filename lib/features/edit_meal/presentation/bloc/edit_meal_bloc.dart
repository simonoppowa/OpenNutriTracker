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
      String? unitText,
      String kcalText,
      String carbsText,
      String fatText,
      String proteinText) {
    final newMealNutriments = MealNutrimentsEntity(
        energyKcal100: kcalText.toDoubleOrNull(),
        carbohydrates100: carbsText.toDoubleOrNull(),
        fat100: fatText.toDoubleOrNull(),
        proteins100: proteinText.toDoubleOrNull(),
        sugars100: oldMealEntity.nutriments.sugars100,
        saturatedFat100: oldMealEntity.nutriments.saturatedFat100,
        fiber100: oldMealEntity.nutriments.fiber100);

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
