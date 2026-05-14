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
      // The Supabase view only has English and German description
      // columns today. cs / it / pl / sk / tr / uk / zh fall through to
      // the English column for now.
      // TODO(@simonoppowa): add description_cs/_it/_pl/_sk/_tr/_uk/_zh
      // to the Supabase fdc_food view, then split these cases out.
      case SupportedLanguage.pl:
      case SupportedLanguage.zh:
      case SupportedLanguage.cs:
      case SupportedLanguage.it:
      case SupportedLanguage.sk:
      case SupportedLanguage.tr:
      case SupportedLanguage.uk:
        return fdcFoodDescriptionEn;
    }
  }
}
