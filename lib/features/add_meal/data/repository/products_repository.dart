import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';

class ProductsRepository {
  final OFFDataSource _offDataSource;
  final FDCDataSource _fdcDataSource;

  ProductsRepository(this._offDataSource, this._fdcDataSource);

  Future<List<ProductEntity>> getOFFProductsByString(
      String searchString) async {
    final offWordResponse =
        await _offDataSource.fetchSearchWordResults(searchString);

    final products = offWordResponse.products
        .map((offProduct) => ProductEntity.fromOFFProduct(offProduct))
        .toList();

    return products;
  }

  Future<List<ProductEntity>> getFDCFoodsByString(String searchString) async {
    final fdcWordResponse =
        await _fdcDataSource.fetchSearchWordResults(searchString);
    final products = fdcWordResponse.foods
        .map((food) => ProductEntity.fromFDCFood(food))
        .toList();
    return products;
  }

  Future<ProductEntity> getOFFProductByBarcode(String barcode) async {
    final productResponse = await _offDataSource.fetchBarcodeResults(barcode);

    return ProductEntity.fromOFFProduct(productResponse.product);
  }
}
