import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/meal_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';

class LocalDataSource {
  final log = Logger('LocalDataSource');
  final mealSrc = locator<MealDataSource>();

  Future<List<MealEntity>> fetchSearchWordResults(String searchString) async {
    return (await mealSrc.getMealsByName(searchString)).map((meal) => MealEntity.fromMealDBO(meal)).toList();
  }

  Future<MealEntity> fetchBarcodeResults(String barcode) async {
    log.fine('Fetching Local result for $barcode');
    final product = await mealSrc.getMealByBarcode(barcode);
    if (product == null) {
      log.warning("Local product not found");
      return Future.error(ProductNotFoundException);
    }
    return MealEntity.fromMealDBO(product);
  }
}
