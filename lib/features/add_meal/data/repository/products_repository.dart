import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class ProductsRepository {
  final OFFDataSource _offDataSource;
  final FDCDataSource _fdcDataSource;

  ProductsRepository(this._offDataSource, this._fdcDataSource);

  Future<List<MealEntity>> getOFFProductsByString(
      String searchString) async {
    final offWordResponse =
        await _offDataSource.fetchSearchWordResults(searchString);

    final products = offWordResponse.products
        .map((offProduct) => MealEntity.fromOFFProduct(offProduct))
        .toList();

    return products;
  }

  Future<List<MealEntity>> getFDCFoodsByString(String searchString) async {
    final fdcWordResponse =
        await _fdcDataSource.fetchSearchWordResults(searchString);
    final products = fdcWordResponse.foods
        .map((food) => MealEntity.fromFDCFood(food))
        .toList();
    return products;
  }

  Future<MealEntity> getOFFProductByBarcode(String barcode) async {
    final productResponse = await _offDataSource.fetchBarcodeResults(barcode);

    return MealEntity.fromOFFProduct(productResponse.product);
  }
}
