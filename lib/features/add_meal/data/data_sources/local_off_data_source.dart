import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_nutriments_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';
import 'package:sqflite/sqflite.dart';

/// URL examples:
/// product page: https://openfoodfacts.org/product/0050428338483
/// api: https://world.openfoodfacts.org/api/v2/product/0050428338483


class LocalOFFDataSource {
  final _log = Logger('LocalOFFDataSource');

  Future<OFFWordResponseDTO> fetchSearchWordResults(String searchString, String localDatabaseFile) async {
     try {
      /// TOOD: for some reason this handles DatabaseException internally and does not 
      /// throw it. Why?
      final Database db = await openDatabase(localDatabaseFile);

      int page = 0;
      int pageCount = 1;
      int pageSize = 20;

      String query = "SELECT * from food WHERE product_name LIKE '%$searchString%' LIMIT $pageSize";
      List<Map<String, Object?>> results = await db.rawQuery(query);

      int count  = results.length;

      List<OFFProductDTO> products = List.empty(growable: true);


      for(Map<String, Object?> result in results) {
        products.add(
          OFFProductDTO(
            code: result["code"] as String,
            product_name: result["product_name"] as String,
            product_name_en: null,
            product_name_fr: null,
            product_name_de: null,
            brands: null,
            image_front_thumb_url: null,
            image_front_url: null,
            image_ingredients_url: null,
            image_nutrition_url: null,
            image_url: null,
            url: "https://openfoodfacts.org/product/${result["code"]}",  // OFFConst.getOffBarcodeSearchUri.toString(),
            quantity: null,
            product_quantity: null,
            serving_quantity: null,
            serving_size: null,
            nutriments: OFFProductNutrimentsDTO(
              energy_kcal_100g: null,
              carbohydrates_100g: null,
              fat_100g: null,
              proteins_100g: null,
              sugars_100g: null,
              saturated_fat_100g: null,
              fiber_100g: null
            )
          )
        );
      }



      OFFWordResponseDTO response = OFFWordResponseDTO(
        count: count,
        page: page,
        page_count: pageCount,
        page_size: pageSize,
        products: products
      );

      return response;

    } on DatabaseException catch (e, s) {
      _log.severe("Error during database access");
      _log.severe(e.toString());
      _log.severe(s.toString());
      return Future.error(e);
    } catch (e, s) {
      _log.severe(e.toString());
      _log.severe(s.toString());
      return Future.error(e);
    }
  }
}