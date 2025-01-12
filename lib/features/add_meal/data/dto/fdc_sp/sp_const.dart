import 'package:opennutritracker/core/utils/supported_language.dart';

class SPConst {
  static const maxNumberOfItems = 20;

  // Table names
  static const fdcFoodTableName = 'fdc_food';
  static const fdcPortionsName = 'fdc_portions';
  static const fdcNutrientsName = 'fdc_nutrients';

  // Column names
  static const fdcFoodId = 'fdc_id';
  static const fdcFoodDescriptionEn = 'description_en';
  static const fdcFoodDescriptionDe = 'description_de';

  static const fdcPortionsMeasureUnitId = 'measure_unit_id';
  static const fdcPortionsAmount = 'measure_unit_id';
  static const fdcPortionsGramWeight = 'gram_weight';

  static const fdcNutrientId = 'nutrient_id';
  static const fdcNutrientsAmount = 'amount';

  static String getFdcFoodDescriptionColumnName(SupportedLanguage language) {
    switch (language) {
      case SupportedLanguage.en:
        return fdcFoodDescriptionEn;
      case SupportedLanguage.de:
        return fdcFoodDescriptionDe;
      }
  }

}
