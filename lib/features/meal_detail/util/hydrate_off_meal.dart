import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// The full Open Food Facts record behind a thin search hit, or null when
/// there is nothing to fetch.
///
/// A text search returns a projection without the serving fields, so a
/// default amount picked from it is 100 g where the product has a serving.
/// Meal detail swaps the full record in before it picks; the + on a search
/// result has to do the same to promise the same default. A cached full
/// record answers offline; otherwise it is fetched and cached. Throws when
/// the fetch fails — the callers keep the thin record then.
Future<MealEntity?> fetchDetailedOffMeal(
  MealEntity meal,
  RemoteSearchCacheDataSource cache,
  ProductsRepository products,
) async {
  final code = meal.code;
  if (meal.source != MealSourceEntity.off ||
      meal.detailed ||
      code == null ||
      code.isEmpty) {
    return null;
  }
  final cached = cache.getDetailedByBarcode(code);
  if (cached != null) return MealEntity.fromMealDBO(cached);
  final full = await products.getOFFProductByBarcode(code);
  await cache.cache(MealDBO.fromMealEntity(full));
  return full;
}
