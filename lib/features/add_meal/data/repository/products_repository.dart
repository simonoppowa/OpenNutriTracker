import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';

class ProductsRepository {
  final offDataSource = OFFDataSource();
  final fdcDataSource = FDCDataSource();

  Future<List<ProductEntity>> getOFFProductsByString(
      String searchString) async {
    final offWordResponse =
        await offDataSource.fetchSearchWordResults(searchString);

    final products = offWordResponse.products
        .map((offProduct) => ProductEntity.fromOFFProduct(offProduct))
        .toList();

    return products;
  }

  Future<List<ProductEntity>> getFDCFoodsByString(String searchString) async {
    final fdcWordResponse =
        await fdcDataSource.fetchSearchWordResults(searchString);
    final products = fdcWordResponse.foods
        .map((food) => ProductEntity.fromFDCFood(food))
        .toList();
    return products;
  }

  Future<ProductEntity> getOFFProductByBarcode(String barcode) async {
    final productResponse = await offDataSource.fetchBarcodeResults(barcode);

    return ProductEntity.fromOFFProduct(productResponse.product);
  }
}
