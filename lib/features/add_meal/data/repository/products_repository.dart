import 'package:opennutritracker/features/addItem/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/addItem/domain/entity/product_entity.dart';

class ProductsRepository {
  final offDataSource = OFFDataSource();

  Future<List<ProductEntity>> getProductsByString(String searchString) async {
    final offWordResponse =
        await offDataSource.fetchSearchWordResults(searchString);

    final products = offWordResponse.products
        .map((offProduct) => ProductEntity.fromOFFProduct(offProduct))
        .toList();

    return products;
  }

  Future<ProductEntity> getProductByBarcode(String barcode) async {
    final productResponse = await offDataSource.fetchBarcodeResults(barcode);

    return ProductEntity.fromOFFProduct(productResponse.product);
  }
}
