import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Output of a product/food search. [meals] is the deduplicated list shown
/// to the user (custom-meal matches first, then remote results).
/// [remoteSourceEmpty] is true when the remote source returned zero rows
/// or failed (rate limit, timeout, network error). The UI uses this to
/// decide whether to render a "no remote results" hint below the custom-meal
/// matches.
class SearchProductsResult {
  final List<MealEntity> meals;
  final bool remoteSourceEmpty;

  const SearchProductsResult({
    required this.meals,
    required this.remoteSourceEmpty,
  });
}

class SearchProductsUseCase {
  final _log = Logger('SearchProductsUseCase');

  final ProductsRepository _productsRepository;
  final GetIntakeUsecase _getIntakeUsecase;
  final CustomMealDataSource _customMealDataSource;
  final RemoteSearchCacheDataSource _cachedOffMealDataSource;
  final RecipeDataSource _recipeDataSource;
  final GetConfigUsecase _getConfigUsecase;

  SearchProductsUseCase(
    this._productsRepository,
    this._getIntakeUsecase,
    this._customMealDataSource,
    this._cachedOffMealDataSource,
    this._recipeDataSource,
    this._getConfigUsecase,
  );

  /// [skipRemote] limits the search to local matches (custom meals, recipes,
  /// recent intake, cached results) and does not touch the network — used for
  /// short as-you-type queries.
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async {
    if (skipRemote) {
      return _buildResult(searchString, const [],
          remoteSkipped: true, cacheSource: MealSourceEntity.off);
    }
    final remote = await _safeRemoteCall(
      'OFF',
      () => _productsRepository.getOFFProductsByString(searchString),
    );
    // Cache the result page. Untouched entries age out after 90 days
    // (RemoteSearchCacheDataSource.pruneStale), so this can't grow
    // unbounded. Items the user actually selects (logs an intake of)
    // get their timestamp refreshed and stay until 90 days after the
    // last selection.
    await _cacheRemoteResults(remote);
    return _buildResult(searchString, remote,
        cacheSource: MealSourceEntity.off);
  }

  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
  }) async {
    if (skipRemote) {
      return _buildResult(searchString, const [],
          remoteSkipped: true, cacheSource: MealSourceEntity.fdc);
    }
    final remote = await _safeRemoteCall(
      'FDC',
      () => _productsRepository.getSupabaseFoodsByString(searchString),
    );
    await _cacheRemoteResults(remote);
    return _buildResult(searchString, remote,
        cacheSource: MealSourceEntity.fdc);
  }

  Future<void> _cacheRemoteResults(List<MealEntity> remote) async {
    if (remote.isEmpty) return;
    // cacheFromSearch (vs cacheAll) preserves timestamps for entries
    // already in the cache. Important so that an item the user logged
    // earlier (its timestamp got bumped via the intent path) keeps that
    // newer timestamp even when a subsequent search re-includes it,
    // letting it remain at the top of the cache-sorted list.
    await _cachedOffMealDataSource
        .cacheFromSearch(remote.map(MealDBO.fromMealEntity));
  }

  /// Run a remote search and fall back to an empty list when the source
  /// throws (rate limit, timeout, network failure, etc). The caller still
  /// receives matching custom meals from local intake history even when the
  /// remote API is unavailable.
  Future<List<MealEntity>> _safeRemoteCall(
    String sourceLabel,
    Future<List<MealEntity>> Function() call,
  ) async {
    try {
      return await call();
    } catch (exception, stack) {
      _log.warning(
        '$sourceLabel search failed; falling back to custom-meal results only',
        exception,
        stack,
      );
      return const [];
    }
  }

  Future<SearchProductsResult> _buildResult(
    String searchString,
    List<MealEntity> remoteResults, {
    bool remoteSkipped = false,
    required MealSourceEntity cacheSource,
  }) async {
    // When the remote source was deliberately skipped (short query), don't
    // claim it returned nothing — that would show a misleading "no results"
    // hint while the user is still typing.
    final remoteSourceEmpty = !remoteSkipped && remoteResults.isEmpty;

    final normalizedSearchString = searchString.trim().toLowerCase();
    if (normalizedSearchString.isEmpty) {
      return SearchProductsResult(
        meals: remoteResults,
        remoteSourceEmpty: remoteSourceEmpty,
      );
    }

    // Local sources of matches, in priority order:
    //  1. Custom-meal box: the user's own templates (created or CSV-
    //     imported). Covers entries that haven't been logged as intake.
    //  2. Recipes: user-authored composite meals — sit at the top of the
    //     list (alongside #1 / above cached + remote) so users find their
    //     own creations before scrolling into remote-cache hits. The
    //     MealItemCard renders a "Recipe" chip + accent border so they're
    //     visually distinguishable from cached OFF/FDC entries.
    //  3. Recent intake history: custom-meal copies the user has logged
    //     even after the original template was deleted.
    //  4. Cached OFF/FDC results: products we previously fetched from the
    //     network. Lets repeat searches and offline use work without a
    //     round-trip — and means freshly-imported users will hit increasing
    //     local hit-rates as they use the app over weeks.
    // All four are passed through the same dedup helper alongside fresh
    // remote results.
    final fromCustomMealBox = _customMealDataSource
        .getAllCustomMeals()
        .map(MealEntity.fromMealDBO)
        .where((meal) => _mealMatchesSearch(meal, normalizedSearchString))
        .toList();

    final fromRecipes = _recipeDataSource
        .getAllRecipes()
        .map((dbo) => RecipeEntity.fromDBO(dbo).toMealEntity())
        .where((meal) => _mealMatchesSearch(meal, normalizedSearchString))
        .toList();

    final recentIntake = await _getIntakeUsecase.getRecentIntake();
    final fromIntakeHistory = recentIntake
        .map((intake) => intake.meal)
        .where((meal) => meal.source == MealSourceEntity.custom)
        .where((meal) => _mealMatchesSearch(meal, normalizedSearchString))
        .toList();

    // Sorted with the most recently touched entries first so an item the
    // user just selected (logged) appears at the top of the next search
    // result list, ahead of other cached items they haven't touched.
    //
    // The cache box holds both OFF and FDC entries (cacheFromSearch writes
    // whatever either remote returned), so filter to the source of the tab
    // being built. Without this, a prior OFF search leaks branded products
    // into the FDC "Food" tab and vice versa, since both tabs share this
    // helper. Custom meals, recipes and intake history above are the user's
    // own and are intentionally surfaced in both tabs.
    // Cached entries respect the food-source selection (Settings → Food
    // databases) just like fresh remote results, which the data source
    // already filters server-side. Entries without a backendSource (OFF
    // products, pre-migration rows) are always kept — only Supabase backend
    // sources are user-selectable.
    final config = await _getConfigUsecase.getConfig();
    final fromCache = _cachedOffMealDataSource
        .getAllByMostRecentlyTouched()
        .map(MealEntity.fromMealDBO)
        .where((meal) => meal.source == cacheSource)
        .where((meal) =>
            meal.backendSource == null ||
            config.isFoodSourceEnabled(meal.backendSource!))
        .where((meal) => _mealMatchesSearch(meal, normalizedSearchString))
        .toList();

    // Cache-first ordering: cached entries appear before fresh remote
    // results. The dedup helper takes the first occurrence, so a cached
    // entry wins when its code matches a fresh remote one — keeps the
    // search list stable from the user's perspective ("the version I
    // saw yesterday is still at the top"). Fresh remote data still
    // wins on the per-item refresh path triggered by intake-add.
    return SearchProductsResult(
      meals: _deduplicateMeals([
        ...fromCustomMealBox,
        ...fromRecipes,
        ...fromIntakeHistory,
        ...fromCache,
        ...remoteResults,
      ]),
      remoteSourceEmpty: remoteSourceEmpty,
    );
  }

  bool _mealMatchesSearch(MealEntity meal, String normalizedSearchString) {
    return (meal.name?.toLowerCase().contains(normalizedSearchString) ??
            false) ||
        (meal.brands?.toLowerCase().contains(normalizedSearchString) ?? false);
  }

  List<MealEntity> _deduplicateMeals(List<MealEntity> meals) {
    final seenKeys = <String>{};
    final uniqueMeals = <MealEntity>[];

    for (final meal in meals) {
      final key = '${meal.source.name}:${meal.code ?? meal.name ?? ''}';
      if (seenKeys.add(key)) {
        uniqueMeals.add(meal);
      }
    }

    return uniqueMeals;
  }
}
