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
import 'package:opennutritracker/features/meal_detail/util/hydrate_off_meal.dart';

/// Output of a product/food search. [meals] is the deduplicated list shown
/// to the user (custom-meal matches first, then remote results).
/// [remoteSourceEmpty] is true when the remote source returned zero rows
/// or failed (rate limit, timeout, network error). The UI uses this to
/// decide whether to render a "no remote results" hint below the custom-meal
/// matches.
///
/// [remoteSourceFailed] is true only when the remote source threw — a
/// genuine zero-row answer leaves it false. The "All" view needs the two
/// apart: a provider outage must not read as "no matching foods".
class SearchProductsResult {
  final List<MealEntity> meals;
  final bool remoteSourceEmpty;
  final bool remoteSourceFailed;

  const SearchProductsResult({
    required this.meals,
    required this.remoteSourceEmpty,
    this.remoteSourceFailed = false,
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
    await _cacheRemoteResults(remote.meals);
    return _buildResult(searchString, remote.meals,
        remoteFailed: remote.failed, cacheSource: MealSourceEntity.off);
  }

  /// Searches the reference-food corpus. "FDC" here names the *data* (USDA
  /// FoodData Central and the other datasets ingested alongside it), not the
  /// host: the request goes to the Supabase backend, never to USDA. The name
  /// is kept because [MealSourceEntity.fdc] is persisted in Hive and renaming
  /// it would need a data migration.
  ///
  /// [forResolution] is what `ResolveParsedMealsUseCase` passes and the
  /// Food tab does not: the backend's hundred rows are cut to twenty in
  /// the data source, and for the resolver's page — which it auto-selects
  /// from — that cut reads each row's `has_portion` column, where the
  /// Food tab's page is cut without it (#1164 part 3, #1190; the cut's
  /// comment in `sp_food_data_source.dart` has the measurements).
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async {
    if (skipRemote) {
      return _buildResult(searchString, const [],
          remoteSkipped: true, cacheSource: MealSourceEntity.fdc);
    }
    final remote = await _safeRemoteCall(
      'FDC',
      () => _productsRepository.getSupabaseFoodsByString(
        searchString,
        forResolution: forResolution,
      ),
    );
    await _cacheRemoteResults(remote.meals);
    return _buildResult(searchString, remote.meals,
        remoteFailed: remote.failed, cacheSource: MealSourceEntity.fdc);
  }

  /// The full Open Food Facts record behind a thin text-search hit, or null
  /// when [meal] is not one — see [fetchDetailedOffMeal], which the + on a
  /// search result and meal detail already use. Cache first, then the v2
  /// product endpoint; throws when that fetch fails.
  Future<MealEntity?> fetchFullOffRecord(MealEntity meal) =>
      fetchDetailedOffMeal(meal, _cachedOffMealDataSource, _productsRepository);

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
  /// remote API is unavailable; [failed] tells that fallback apart from a
  /// source that answered with zero rows.
  Future<({List<MealEntity> meals, bool failed})> _safeRemoteCall(
    String sourceLabel,
    Future<List<MealEntity>> Function() call,
  ) async {
    try {
      return (meals: await call(), failed: false);
    } catch (exception, stack) {
      _log.warning(
        '$sourceLabel search failed; falling back to custom-meal results only',
        exception,
        stack,
      );
      return (meals: const <MealEntity>[], failed: true);
    }
  }

  Future<SearchProductsResult> _buildResult(
    String searchString,
    List<MealEntity> remoteResults, {
    bool remoteSkipped = false,
    bool remoteFailed = false,
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
        remoteSourceFailed: remoteFailed,
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

    // Sorted with the most recently touched entries first.
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
    //
    // A record this search's remote page returned is in the cache already
    // — `_cacheRemoteResults` ran first — and its cached copy takes the
    // fresh copy's place in the dedup below. The cache cannot hold
    // everything a fresh backend result carries, though: `MealDBO` has no
    // column for `portions` or for `servingSizeIsLocalized`, so the copy
    // read back is the same record with its portions gone, and the
    // resolver, which scores portions (#1164) and offers them for picking
    // (#968), saw none on this path from the first search on. Every
    // persisted field agrees between the two — the cache was just written
    // from the page — so the fresh entity stands in for the cached copy
    // (see [_freshest]).
    final config = await _getConfigUsecase.getConfig();
    final freshByKey = {
      for (final meal in remoteResults) _dedupKey(meal): meal,
    };
    final fromCache = _cachedOffMealDataSource
        .getAllByMostRecentlyTouched()
        .map(MealEntity.fromMealDBO)
        .where((meal) => meal.source == cacheSource)
        .where((meal) =>
            meal.backendSource == null ||
            config.isFoodSourceEnabled(meal.backendSource!))
        .where((meal) => _mealMatchesSearch(meal, normalizedSearchString))
        .map((meal) => _freshest(meal, freshByKey))
        .toList();

    // The page in the order its source ranked it, each record as the
    // cached copy above has it — which is the fresh one but for the
    // hydrated product [_freshest] keeps.
    final cachedByKey = {for (final meal in fromCache) _dedupKey(meal): meal};
    final fromRemote = [
      for (final meal in remoteResults) cachedByKey[_dedupKey(meal)] ?? meal,
    ];

    // Only what the user has logged goes above the page. Everything else
    // the cache holds is there because a search page once listed it —
    // cacheFromSearch stamps every new row with the time it was seen —
    // so a cache-first list was the page re-sorted by when its rows were
    // first seen: rows new to the cache all at the top, under one
    // timestamp, in whatever order an unstable sort left them, and a row
    // an earlier search had cached below every one of them. That is how
    // "banane" showed puddings and baby foods above "Banane, roh", and
    // "apfel" a baby juice above "Apfel, roh" (#1473). Logged records
    // keep their place at the top, most recently touched first; the
    // cache's other matches follow the page, where they still answer a
    // search the remote could not.
    final loggedKeys = {
      for (final intake in recentIntake)
        if (intake.meal.source == cacheSource) _dedupKey(intake.meal),
    };
    bool logged(MealEntity meal) => loggedKeys.contains(_dedupKey(meal));

    return SearchProductsResult(
      meals: _deduplicateMeals([
        ...fromCustomMealBox,
        ...fromRecipes,
        ...fromIntakeHistory,
        ...fromCache.where(logged),
        ...fromRemote.where(logged),
        ...fromRemote,
        ...fromCache,
      ]),
      remoteSourceEmpty: remoteSourceEmpty,
      remoteSourceFailed: remoteFailed,
    );
  }

  bool _mealMatchesSearch(MealEntity meal, String normalizedSearchString) {
    return (meal.name?.toLowerCase().contains(normalizedSearchString) ??
            false) ||
        (meal.brands?.toLowerCase().contains(normalizedSearchString) ?? false);
  }

  /// The fresh copy of [cached] when this search's remote page returned the
  /// same record, else [cached] itself.
  ///
  /// The one fresh copy not taken is the one
  /// [RemoteSearchCacheDataSource.cacheFromSearch] refuses to write: a thin
  /// search result standing in for a product already hydrated to its full
  /// record. The cache kept the full one, and so does the list.
  MealEntity _freshest(MealEntity cached, Map<String, MealEntity> freshByKey) {
    final fresh = freshByKey[_dedupKey(cached)];
    if (fresh == null) return cached;
    if (cached.detailed && !fresh.detailed) return cached;
    return fresh;
  }

  String _dedupKey(MealEntity meal) =>
      '${meal.source.name}:${meal.code ?? meal.name ?? ''}';

  List<MealEntity> _deduplicateMeals(List<MealEntity> meals) {
    final seenKeys = <String>{};
    final uniqueMeals = <MealEntity>[];

    for (final meal in meals) {
      if (seenKeys.add(_dedupKey(meal))) {
        uniqueMeals.add(meal);
      }
    }

    return uniqueMeals;
  }
}
