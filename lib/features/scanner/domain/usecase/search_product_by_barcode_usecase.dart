import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';

class SearchProductByBarcodeUseCase {
  final ProductsRepository productsRepository = ProductsRepository();

  Future<ProductEntity> searchProductByBarcode(String barcode) async {
    return await productsRepository.getProductByBarcode(barcode);
  }
}
