import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';

class SearchProductsUseCase {
  final ProductsRepository _productsRepository;

  SearchProductsUseCase(this._productsRepository);

  Future<List<ProductEntity>> searchOFFProductsByString(
      String searchString) async {
    final products =
        await _productsRepository.getOFFProductsByString(searchString);
    return products;
  }

  Future<List<ProductEntity>> searchFDCFoodByString(String searchString) async {
    final foods = await _productsRepository.getFDCFoodsByString(searchString);
    return foods;
  }
}
