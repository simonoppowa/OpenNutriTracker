import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Whether the per-serving (simple) form can save [meal] without changing
/// it. That form always writes a base amount and a serving of 100 in g/ml,
/// so a food with any other shape — saved from the advanced form, read
/// off a label or imported — would silently lose its serving on save.
bool simpleFormKeeps(MealEntity meal) {
  bool isHundred(String? text) =>
      text == null || text.isEmpty || double.tryParse(text) == 100;
  return (meal.servingQuantity == null || meal.servingQuantity == 100) &&
      isHundred(meal.mealQuantity) &&
      const {null, '', 'gml', 'g/ml'}.contains(meal.mealUnit);
}
