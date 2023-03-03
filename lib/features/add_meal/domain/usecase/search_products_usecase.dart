import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';

class SearchProductsUseCase {
  // TODO make singleton
  final ProductsRepository productsRepository = ProductsRepository();

  Future<List<ProductEntity>> searchProductsByString(
      String searchString) async {
    final products = await productsRepository.getProductsByString(searchString);
    return products;
  }
}
