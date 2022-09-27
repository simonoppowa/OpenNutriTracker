import 'dart:developer';

class OFFConst {
  static const _offBaseUrl = "https://world.openfoodfacts.org/";
  static const _offSearchTag = "search";

  static const offHttpSuccessCode = 200;
  static const offHttpDownCodes = [502, 503, 500];
  static const offProductNotFoundTag = "product not found";

  static const _offProductNameTag = "product_name";
  static const _offProductNameENTag = "product_name_en";
  static const _offProductNameDETag = "product_name_de";
  static const _offFieldsTag = "fields";
  static const _offJsonTag = "json";
  static const _offJsonValue = "true";

  static const _offCodeTag = "code";
  static const _offBrandsTag = "brands";
  static const _offUrlTag = "url";
  static const _offImageThumbTag = "image_front_thumb_url";
  static const _offImageNutritionTag = "image_nutrition_url";
  static const _offImageIngredientsTag = "image_ingredients_url";
  static const _offProductQuantityTag = "product_quantity";
  static const _offQuantityTag = "quantity";
  static const _offServingQuantityTag = "serving_quantity";
  static const _offServingSizeTag = "serving_size";
  static const _offNutrimentsTag = "nutriments";

  static Uri getOffWordSearchUrl(String searchWord) {
    String searchUrl =
        '$_offBaseUrl$_offSearchTag?$_offProductNameTag=$searchWord&$_offFieldsTag=${_getReturnFields()}&$_offJsonTag=$_offJsonValue';
    print('Fetching $searchUrl');

    return Uri.parse(searchUrl);
  }

  static String _getReturnFields() {
    return '$_offCodeTag,$_offBrandsTag,$_offProductNameTag,$_offProductNameENTag,$_offProductNameDETag,$_offUrlTag,$_offImageThumbTag,$_offProductQuantityTag,$_offQuantityTag,$_offServingQuantityTag,$_offServingSizeTag,$_offNutrimentsTag';
  }
}
