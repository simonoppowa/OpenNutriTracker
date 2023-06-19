import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';

class SearchProductsUseCase {
  // TODO make singleton
  final ProductsRepository productsRepository = ProductsRepository();

  Future<List<ProductEntity>> searchOFFProductsByString(
      String searchString) async {
    final products =
        await productsRepository.getOFFProductsByString(searchString);
    return products;
  }

  Future<List<ProductEntity>> searchFDCFoodByString(String searchString) async {
    final foods = await productsRepository.getFDCFoodsByString(searchString);
    return foods;
  }
}
