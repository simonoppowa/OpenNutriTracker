class OFFConst {
  static const offWebsiteUrl = "https://world.openfoodfacts.org/";
  static const _offBaseUrl = "world.openfoodfacts.org";
  static const _offSearchTag = "/cgi/search.pl";
  static const _offProductSearchTag = "/api/v2/product";

  static const offHttpSuccessCode = 200;
  static const offHttpDownCodes = [502, 503, 500];
  static const offProductNotFoundCode = 404;

  static const _offProductSearchTermsTag = "search_terms";
  static const _offFieldsTag = "fields";
  static const _offJsonTag = "json";
  static const _offJsonValue = "true";

  static const _offProductNameTag = "product_name";
  static const _offProductNameENTag = "product_name_en";
  static const _offProductNameDETag = "product_name_de";
  static const _offProductNameFRTag = "product_name_fr";
  static const _offCodeTag = "code";
  static const _offBrandsTag = "brands";

  static const _offUrlTag = "url";
  static const _offImageUrlTag = "image_url";
  static const _offImageThumbUrlTag = "image_front_thumb_url";
  static const _offImageFrontUrlTag = "image_front_url";
  // static const _offImageNutritionUrlTag = "image_nutrition_url";
  // static const _offImageIngredientsUrlTag = "image_ingredients_url";

  static const _offProductQuantityTag = "product_quantity";
  static const _offQuantityTag = "quantity";
  static const _offServingQuantityTag = "serving_quantity";
  static const _offServingSizeTag = "serving_size";
  static const _offNutrimentsTag = "nutriments";

  static const _returnFields = [
    _offCodeTag,
    _offBrandsTag,
    _offProductNameTag,
    _offProductNameENTag,
    _offProductNameDETag,
    _offProductNameFRTag,
    _offUrlTag,
    _offImageUrlTag,
    _offImageThumbUrlTag,
    _offImageFrontUrlTag,
    _offProductQuantityTag,
    _offQuantityTag,
    _offServingQuantityTag,
    _offServingSizeTag,
    _offNutrimentsTag
  ];

  static String _getReturnFields() => _returnFields.join(",");

  static Uri getOffWordSearchUrl(String searchString) {
    final queryParameters = {
      _offProductSearchTermsTag: searchString,
      _offFieldsTag: _getReturnFields(),
      _offJsonTag: _offJsonValue,
    };

    return Uri.https(_offBaseUrl, _offSearchTag, queryParameters);
  }

  static Uri getOffBarcodeSearchUri(String barcode) {
    final queryParameters = {
      _offFieldsTag: _getReturnFields(),
      _offJsonTag: _offJsonValue
    };

    return Uri.https(
        _offBaseUrl, '$_offProductSearchTag/$barcode', queryParameters);
  }
}
