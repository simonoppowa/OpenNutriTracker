import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Looks up the meal corresponding to a scanned barcode. Resolution order:
///
///   1. **User's own custom meals** — a custom meal the user has saved
///      with a barcode (#167) wins over remote data, because the user
///      explicitly created the entry and a matching scan should pull
///      that exact saved record back.
///   2. **Cached OFF lookup** — makes repeat scans instant and works
///      offline.
///   3. **Live OFF API** — only when nothing local matches. The
///      successful result is then written to the cache for next time.
///
/// Recipes do not participate in this lookup. Recipes are compositions
/// of meals, not single scannable products, so attaching a barcode to a
/// recipe was a model error in the first cut of #167 — corrected here.
/// A user who wants a scan to recall a saved meal should set the
/// barcode on the meal itself via Edit Meal.
class SearchProductByBarcodeUseCase {
  final ProductsRepository _productsRepository;
  final CustomMealDataSource _customMealDataSource;
  final RemoteSearchCacheDataSource _cachedOffMealDataSource;

  SearchProductByBarcodeUseCase(
    this._productsRepository,
    this._customMealDataSource,
    this._cachedOffMealDataSource,
  );

  Future<MealEntity> searchProductByBarcode(String barcode) async {
    final customMatch = _customMealDataSource
        .getAllCustomMeals()
        .where((dbo) => dbo.code != null && dbo.code == barcode)
        .firstOrNull;
    if (customMatch != null) {
      return MealEntity.fromMealDBO(customMatch);
    }

    final cachedMatch = _cachedOffMealDataSource.getByBarcode(barcode);
    if (cachedMatch != null) {
      return MealEntity.fromMealDBO(cachedMatch);
    }

    final remote = await _productsRepository.getOFFProductByBarcode(barcode);
    await _cachedOffMealDataSource.cache(MealDBO.fromMealEntity(remote));
    return remote;
  }
}
