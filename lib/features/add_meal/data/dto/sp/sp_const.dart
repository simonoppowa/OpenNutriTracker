import 'package:opennutritracker/core/utils/supported_language.dart';

/// Constants for the Supabase multi-source food backend.
///
/// The app reads exactly two relations from the backend schema
/// (opennutritracker-backend/sql/schema.sql):
///  * [foodSummaryTable] — materialized view with one flat row per food:
///    identity (source, source_code), display names, brand + barcode,
///    default serving, image URLs, tags and the 24 canonical per-100g
///    nutrient columns (mirroring MealNutrimentsDBO).
///  * [foodTranslationTable] — per-locale food names, used both to search
///    and to label foods in non-English locales.
class SPConst {
  static const maxNumberOfItems = 20;

  // Relations
  static const foodSummaryTable = 'food_summary';
  static const foodTranslationTable = 'food_translation';

  // food_summary columns
  static const foodId = 'food_id';
  static const foodSource = 'source';
  static const foodSourceCode = 'source_code';
  static const foodName = 'name';
  static const foodShortTitle = 'short_title';
  static const foodBrands = 'brands';
  static const foodBarcode = 'barcode';
  static const foodCategory = 'category';
  static const servingQuantity = 'serving_quantity';
  static const servingUnit = 'serving_unit';
  static const servingSize = 'serving_size';
  static const servingGramWeight = 'serving_gram_weight';
  static const thumbnailUrl = 'thumbnail_url';
  static const mainImageUrl = 'main_image_url';
  static const tags = 'tags';

  // food_translation columns
  static const translationFoodId = 'food_id';
  static const translationLocale = 'locale';
  static const translationDescription = 'description';
  static const translationSource = 'source';

  /// food_translation.source value for unreviewed machine translations
  /// (DeepL/LLM). The app shows a small disclosure hint for these; the
  /// other values (native, community, verified) involve a human and don't.
  static const translationSourceMachine = 'machine';

  // Text-search configs matching the indexes in schema.sql:
  // food.description uses to_tsvector('english', ...), food_translation
  // uses to_tsvector('simple', ...) since it holds many languages.
  static const foodNameFtsConfig = 'english';
  static const translationFtsConfig = 'simple';

  /// food_source.code prefix shared by the USDA FDC sources
  /// (fdc_foundation, fdc_sr_legacy, fdc_survey). Only these foods have a
  /// public detail page to link to.
  static const fdcSourcePrefix = 'fdc';

  /// food_source.code of the Bundeslebensmittelschlüssel.
  static const blsSourceCode = 'bls';

  /// BLS food-group letters (first character of the BLS code) that denote
  /// beverages: N = alkoholfreie Getränke, P = alkoholische Getränke.
  /// Used to default drinks to millilitre entry in the app.
  static const blsBeverageGroups = {'N', 'P'};

  /// Human-readable names of the backend food sources, keyed by
  /// food_source.code. Proper nouns — shown as-is in every app language.
  static const foodSourceDisplayNames = <String, String>{
    'fdc_foundation': 'FoodData Central (Foundation Foods)',
    'fdc_sr_legacy': 'FoodData Central (SR Legacy)',
    'fdc_survey': 'FoodData Central (FNDDS Survey)',
    'fdc_branded': 'FoodData Central (Branded Foods)',
    'bls': 'Bundeslebensmittelschlüssel (BLS)',
    'indb': 'Indian Nutrient Databank (INDB)',
    'tbca': 'Tabela Brasileira de Composição de Alimentos (TBCA)',
  };

  /// Compact source labels for chips on list items, where the full
  /// [foodSourceDisplayNames] would not fit.
  static const foodSourceShortNames = <String, String>{
    'fdc_foundation': 'FDC Foundation',
    'fdc_sr_legacy': 'FDC SR Legacy',
    'fdc_survey': 'FDC Survey',
    'fdc_branded': 'FDC Branded',
    'bls': 'BLS',
    'indb': 'INDB',
    'tbca': 'TBCA',
  };

  /// Sources offered in Settings → Food databases. INDB and TBCA exist in
  /// the schema but carry no data yet, so they are not selectable until
  /// their imports land — add them here once they do.
  static const settingsSelectableFoodSources = [
    'fdc_foundation',
    'fdc_sr_legacy',
    'fdc_survey',
    'fdc_branded',
    'bls',
  ];

  /// Public website per backend source: the "learn more" link in Settings →
  /// Food databases and the info-button fallback for foods without a
  /// per-item detail page (only FDC foods have one).
  static const foodSourceWebsites = <String, String>{
    'fdc_foundation': 'https://fdc.nal.usda.gov',
    'fdc_sr_legacy': 'https://fdc.nal.usda.gov',
    'fdc_survey': 'https://fdc.nal.usda.gov',
    'fdc_branded': 'https://fdc.nal.usda.gov',
    'bls': 'https://www.blsdb.de',
    'indb': 'https://www.anuvaad.org.in',
    'tbca': 'https://www.tbca.net.br',
  };

  /// BCP 47 locale used in food_translation for [language], or null when
  /// the base (English) food_summary.name applies directly.
  static String? translationLocaleOf(SupportedLanguage language) {
    switch (language) {
      case SupportedLanguage.en:
        return null;
      case SupportedLanguage.de:
        return 'de';
      case SupportedLanguage.pl:
        return 'pl';
      case SupportedLanguage.zh:
        return 'zh';
      case SupportedLanguage.cs:
        return 'cs';
      case SupportedLanguage.it:
        return 'it';
      case SupportedLanguage.sk:
        return 'sk';
      case SupportedLanguage.tr:
        return 'tr';
      case SupportedLanguage.uk:
        return 'uk';
    }
  }
}
