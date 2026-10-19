import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The display name of each stored nutrient.
extension NutrientFieldLabel on NutrientField {
  String label(S s) => switch (this) {
    NutrientField.energyKcal => s.energyLabel,
    NutrientField.carbohydrates => s.carbohydrateLabel,
    NutrientField.fat => s.fatLabel,
    NutrientField.proteins => s.proteinLabel,
    NutrientField.sugars => s.sugarLabel,
    NutrientField.saturatedFat => s.saturatedFatLabel,
    NutrientField.fiber => s.fiberLabel,
    NutrientField.monounsaturatedFat => s.monounsaturatedFatLabel,
    NutrientField.polyunsaturatedFat => s.polyunsaturatedFatLabel,
    NutrientField.transFat => s.transFatLabel,
    NutrientField.cholesterol => s.cholesterolLabel,
    NutrientField.sodium => s.sodiumLabel,
    NutrientField.potassium => s.potassiumLabel,
    NutrientField.magnesium => s.magnesiumLabel,
    NutrientField.calcium => s.calciumLabel,
    NutrientField.iron => s.ironLabel,
    NutrientField.zinc => s.zincLabel,
    NutrientField.phosphorus => s.phosphorusLabel,
    NutrientField.vitaminA => s.vitaminALabel,
    NutrientField.vitaminC => s.vitaminCLabel,
    NutrientField.vitaminD => s.vitaminDLabel,
    NutrientField.vitaminB6 => s.vitaminB6Label,
    NutrientField.vitaminB12 => s.vitaminB12Label,
    NutrientField.niacin => s.niacinLabel,
  };
}
