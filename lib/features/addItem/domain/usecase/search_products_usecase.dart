import 'package:opennutritracker/features/addItem/data/repository/products_repository.dart';
import 'package:opennutritracker/features/addItem/domain/entity/product_entity.dart';

class SearchProductsUseCase {
  final ProductsRepository productsRepository = ProductsRepository();

  Future<List<ProductEntity>> searchProductsByString(
      String searchString) async {
    final products = await productsRepository.getProductsByString(searchString);
    return products;
  }
}
