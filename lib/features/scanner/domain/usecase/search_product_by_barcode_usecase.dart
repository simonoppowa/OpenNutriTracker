import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/usecase/toggle_favourite_meal_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Looks up the meal corresponding to a scanned barcode. Resolution order:
///
///   1. **User's own custom meals** — a custom meal the user has saved
///      with a barcode (#167) wins over remote data, because the user
///      explicitly created the entry and a matching scan should pull
///      that exact saved record back.
///   2. **Cached full OFF lookup** — makes repeat scans instant and works
///      offline. Only full (hydrated/scanned) cache entries count; a thin
///      Search-a-licious search result under the same code is skipped so the
///      scan still pulls the complete product.
///   3. **Live OFF API** — only when nothing local matches. The
///      successful result is then written to the cache for next time, and
///      over the snapshot of a favourite on the product (#1307), so a
///      product whose data changed upstream is not logged offline or
///      exported with the old figures. Only this fresh record is written:
///      the cached and custom matches are what is stored already.
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
  final ToggleFavouriteMealUsecase _favourites;

  SearchProductByBarcodeUseCase(
    this._productsRepository,
    this._customMealDataSource,
    this._cachedOffMealDataSource,
    this._favourites,
  );

  static final _log = Logger('SearchProductByBarcodeUseCase');

  Future<MealEntity> searchProductByBarcode(String barcode) async {
    final customMatch = _customMealDataSource
        .getAllCustomMeals()
        .where((dbo) => dbo.code != null && dbo.code == barcode)
        .firstOrNull;
    if (customMatch != null) {
      return MealEntity.fromMealDBO(customMatch);
    }

    final cachedMatch = _cachedOffMealDataSource.getDetailedByBarcode(barcode);
    if (cachedMatch != null) {
      return MealEntity.fromMealDBO(cachedMatch);
    }

    final remote = await _productsRepository.getOFFProductByBarcode(barcode);
    await _cachedOffMealDataSource.cache(MealDBO.fromMealEntity(remote));
    // Best effort: a favourite that keeps its old snapshot must not cost
    // the user the scan.
    try {
      await _favourites.refreshDetailedSnapshot(remote);
    } catch (error, stackTrace) {
      _log.warning(
        'Could not refresh a favourite on $barcode',
        error,
        stackTrace,
      );
    }
    return remote;
  }
}
