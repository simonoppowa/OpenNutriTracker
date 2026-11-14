import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/presentation/widgets/empty_hint.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/search_debounce.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/default_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_search_bar.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/partial_results_notice.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The recipe builder's ingredient search. It searches the way the add-food
/// screen does (#1283): the same source chips, opening on Recent, typing
/// into one merged, ranked All list, and the same [MealItemCard] rows. A
/// pick goes to [onMealSelected] instead of the meal-detail logging flow,
/// so it adds an ingredient and never logs an intake.
///
/// The source rules mirror `AddMealScreen`; keep the two in step.
class FoodSearchTabView extends StatefulWidget {
  final void Function(MealEntity meal) onMealSelected;
  // When non-null, the search bar shows a barcode-scan suffix icon and
  // taps are forwarded here. The recipe builder uses this to push the
  // scanner in pick mode and feed the result back through [onMealSelected].
  final VoidCallback? onBarcodePressed;

  /// The id of the recipe being edited, left out of every list so a recipe
  /// cannot be picked as an ingredient of itself.
  final String? excludedRecipeId;

  const FoodSearchTabView({
    super.key,
    required this.onMealSelected,
    this.onBarcodePressed,
    this.excludedRecipeId,
  });

  @override
  State<FoodSearchTabView> createState() => _FoodSearchTabViewState();
}

enum _SearchSource { recent, favourites, all, products, food }

class _FoodSearchTabViewState extends State<FoodSearchTabView> {
  final ValueNotifier<String> _searchStringListener = ValueNotifier('');

  late ProductsBloc _productsBloc;
  late FoodBloc _foodBloc;
  late RecentMealBloc _recentMealBloc;
  late FavouriteMealBloc _favouriteMealBloc;

  // Opens on Recent; typing searches All unless Recent was chosen by hand.
  _SearchSource _source = _SearchSource.recent;
  bool _stickOnRecent = false;

  @override
  void initState() {
    super.initState();
    _productsBloc = locator<ProductsBloc>();
    _foodBloc = locator<FoodBloc>();
    _recentMealBloc = locator<RecentMealBloc>();
    _favouriteMealBloc = locator<FavouriteMealBloc>();
  }

  @override
  void dispose() {
    _searchStringListener.dispose();
    _productsBloc.close();
    _foodBloc.close();
    _recentMealBloc.close();
    _favouriteMealBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing16),
      child: Column(
        children: [
          const SizedBox(height: Dimens.spacing8),
          MealSearchBar(
            searchStringListener: _searchStringListener,
            onSearchSubmit: _onSearchSubmit,
            onSearchChanged: _onSearchChanged,
            onBarcodePressed: widget.onBarcodePressed,
          ),
          const SizedBox(height: Dimens.spacing12),
          _buildSourceChips(context),
          const SizedBox(height: Dimens.spacing12),
          // Rebuilt on every keystroke so an empty list can tell "no
          // results" apart from "a newer query is still searching".
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _searchStringListener,
              builder: (context, query, _) => _buildResults(context, query),
            ),
          ),
        ],
      ),
    );
  }

  _SearchSource _resolveSource(String trimmed) {
    if (_source == _SearchSource.favourites) return _SearchSource.favourites;
    if (trimmed.isEmpty) return _SearchSource.recent;
    if (_source == _SearchSource.recent) {
      return _stickOnRecent ? _SearchSource.recent : _SearchSource.all;
    }
    return _source;
  }

  bool _searchesProducts(_SearchSource s) =>
      s == _SearchSource.all || s == _SearchSource.products;
  bool _searchesFood(_SearchSource s) =>
      s == _SearchSource.all || s == _SearchSource.food;

  void _onSearchSubmit(String inputText) {
    final source = _resolveSource(inputText.trim());
    if (source != _source) setState(() => _source = source);
    _load(source, inputText);
  }

  void _onSearchChanged(String inputText) {
    final source = _resolveSource(inputText.trim());
    if (source != _source) setState(() => _source = source);
    if (_searchesProducts(source)) {
      _productsBloc.add(SearchInputChangedEvent(searchString: inputText));
    }
    if (_searchesFood(source)) {
      _foodBloc.add(SearchFoodInputChangedEvent(searchString: inputText));
    }
    if (source == _SearchSource.recent) {
      _recentMealBloc.add(
        RecentMealSearchChangedEvent(searchString: inputText),
      );
    }
    if (source == _SearchSource.favourites) {
      _favouriteMealBloc.add(LoadFavouriteMealEvent(searchString: inputText));
    }
  }

  void _load(_SearchSource source, String query) {
    if (_searchesProducts(source)) {
      _productsBloc.add(LoadProductsEvent(searchString: query));
    }
    if (_searchesFood(source)) {
      _foodBloc.add(LoadFoodEvent(searchString: query));
    }
    if (source == _SearchSource.recent) {
      _recentMealBloc.add(LoadRecentMealEvent(searchString: query));
    }
    if (source == _SearchSource.favourites) {
      _favouriteMealBloc.add(LoadFavouriteMealEvent(searchString: query));
    }
  }

  void _selectSource(_SearchSource source) {
    setState(() {
      _source = source;
      _stickOnRecent = source == _SearchSource.recent;
    });
    _load(source, _searchStringListener.value);
  }

  void _retryProducts() => _productsBloc.add(const RefreshProductsEvent());
  void _retryFood() => _foodBloc.add(const RefreshFoodEvent());
  void _retryAll() {
    _retryProducts();
    _retryFood();
  }

  Widget _buildSourceChips(BuildContext context) {
    final s = S.of(context);
    Widget chip(_SearchSource source, String id, String label) => Padding(
      padding: const EdgeInsets.only(right: Dimens.spacing8),
      child: Semantics(
        identifier: 'recipe-ingredient-source-$id',
        child: ChoiceChip(
          label: Text(label),
          selected: _source == source,
          showCheckmark: false,
          onSelected: (_) => _selectSource(source),
        ),
      ),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(_SearchSource.recent, 'recent', s.recentlyAddedLabel),
            chip(_SearchSource.favourites, 'favourites', s.favouritesLabel),
            chip(_SearchSource.all, 'all', s.allItemsLabel),
            chip(_SearchSource.products, 'products', s.searchProductsPage),
            chip(_SearchSource.food, 'food', s.searchFoodPage),
          ],
        ),
      ),
    );
  }

  /// Drops the recipe being edited: it cannot be its own ingredient.
  List<MealEntity> _offered(List<MealEntity> meals) {
    final excluded = widget.excludedRecipeId;
    if (excluded == null) return meals;
    return [
      for (final meal in meals)
        if (meal.source != MealSourceEntity.recipe || meal.code != excluded)
          meal,
    ];
  }

  Widget _card(MealEntity meal, bool usesImperialUnits) => MealItemCard(
    mealEntity: meal,
    usesImperialUnits: usesImperialUnits,
    onPicked: widget.onMealSelected,
  );

  Widget _list(
    String identifier,
    List<MealEntity> meals,
    bool imperial, {
    bool trailingNoResults = false,
  }) => Semantics(
    identifier: identifier,
    container: true,
    child: ListView.builder(
      itemCount: meals.length + (trailingNoResults ? 1 : 0),
      itemBuilder: (context, index) => index == meals.length
          ? const NoResultsWidget()
          : _card(meals[index], imperial),
    ),
  );

  Widget _noResults({bool searchAll = false}) => NoResultsWidget(
    onScanBarcode: widget.onBarcodePressed,
    onSearchAll: searchAll ? () => _selectSource(_SearchSource.all) : null,
  );

  static bool _productsPending(ProductsState state, String query) {
    if (state is ProductsLoadingState) return true;
    if (query.trim().length < minQueryLength) return false;
    if (state is ProductsInitial) return true;
    if (state is ProductsLoadedState) return state.query != query;
    return false;
  }

  static bool _foodPending(FoodState state, String query) {
    if (state is FoodLoadingState) return true;
    if (query.trim().length < minQueryLength) return false;
    if (state is FoodInitial) return true;
    if (state is FoodLoadedState) return state.query != query;
    return false;
  }

  static const _pendingSpinner = Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: EdgeInsets.only(top: 32),
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(),
      ),
    ),
  );

  Widget _buildResults(BuildContext context, String query) {
    switch (_source) {
      case _SearchSource.all:
        return _buildAllResults(context, query);
      case _SearchSource.products:
        return BlocBuilder<ProductsBloc, ProductsState>(
          bloc: _productsBloc,
          builder: (context, state) {
            if (_productsPending(state, query)) return _pendingSpinner;
            if (state is ProductsFailedState) {
              return _error(context, _retryProducts);
            }
            if (state is! ProductsLoadedState) {
              return const DefaultsResultsWidget();
            }
            final meals = _offered(state.products);
            if (meals.isEmpty) return _noResults();
            return _list(
              'recipe-ingredient-products-list',
              meals,
              state.usesImperialUnits,
              trailingNoResults: state.remoteSourceEmpty,
            );
          },
        );
      case _SearchSource.food:
        return BlocBuilder<FoodBloc, FoodState>(
          bloc: _foodBloc,
          builder: (context, state) {
            if (_foodPending(state, query)) return _pendingSpinner;
            if (state is FoodFailedState) return _error(context, _retryFood);
            if (state is! FoodLoadedState) {
              return const DefaultsResultsWidget();
            }
            final meals = _offered(state.food);
            if (meals.isEmpty) return _noResults();
            return _list(
              'recipe-ingredient-food-list',
              meals,
              state.usesImperialUnits,
              trailingNoResults: state.remoteSourceEmpty,
            );
          },
        );
      case _SearchSource.favourites:
        return BlocBuilder<FavouriteMealBloc, FavouriteMealState>(
          bloc: _favouriteMealBloc,
          builder: (context, state) {
            if (state is FavouriteMealInitial) {
              _favouriteMealBloc.add(
                LoadFavouriteMealEvent(searchString: query),
              );
              return const SizedBox();
            }
            if (state is FavouriteMealLoadingState) return _pendingSpinner;
            if (state is FavouriteMealFailedState) {
              return ErrorDialog(
                errorText: S.of(context).errorLoadingFavourites,
                onRefreshPressed: () => _favouriteMealBloc.add(
                  LoadFavouriteMealEvent(
                    searchString: _searchStringListener.value,
                  ),
                ),
                retryIdentifier: 'recipe-ingredient-favourites-retry',
              );
            }
            if (state is! FavouriteMealLoadedState) return const SizedBox();
            final meals = _offered(state.favourites);
            if (meals.isNotEmpty) {
              return _list(
                'recipe-ingredient-favourites-list',
                meals,
                state.usesImperialUnits,
              );
            }
            if (query.trim().isEmpty) {
              return SingleChildScrollView(
                child: EmptyHint(
                  icon: Icons.star_outline_rounded,
                  title: S.of(context).favouritesEmptyTitle,
                  subtitle: S.of(context).favouritesEmptySubtitle,
                ),
              );
            }
            return _noResults();
          },
        );
      case _SearchSource.recent:
        return BlocBuilder<RecentMealBloc, RecentMealState>(
          bloc: _recentMealBloc,
          builder: (context, state) {
            if (state is RecentMealInitial) {
              _recentMealBloc.add(const LoadRecentMealEvent(searchString: ''));
              return const SizedBox();
            }
            if (state is RecentMealLoadingState) return _pendingSpinner;
            if (state is RecentMealFailedState) {
              return ErrorDialog(
                errorText: S.of(context).noMealsRecentlyAddedLabel,
                onRefreshPressed: () => _recentMealBloc.add(
                  const LoadRecentMealEvent(searchString: ''),
                ),
              );
            }
            if (state is! RecentMealLoadedState) return const SizedBox();
            final meals = _offered(state.recentMeals);
            if (meals.isNotEmpty) {
              return _list(
                'recipe-ingredient-recent-list',
                meals,
                state.usesImperialUnits,
              );
            }
            if (query.trim().isEmpty) {
              return SingleChildScrollView(
                child: EmptyHint(
                  icon: Icons.history_rounded,
                  title: S.of(context).noMealsRecentlyAddedLabel,
                ),
              );
            }
            return _noResults(
              searchAll:
                  _stickOnRecent && query.trim().length >= minQueryLength,
            );
          },
        );
    }
  }

  Widget _error(BuildContext context, VoidCallback onRetry) =>
      SingleChildScrollView(
        child: ErrorDialog(
          errorText: S.of(context).errorFetchingProductData,
          onRefreshPressed: onRetry,
          retryIdentifier: 'search-all-retry',
        ),
      );

  /// The add-food screen's All list: both sources, merged and ranked by
  /// [mergeAndRankMeals], shown once both have answered.
  Widget _buildAllResults(BuildContext context, String query) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      bloc: _productsBloc,
      builder: (context, ps) => BlocBuilder<FoodBloc, FoodState>(
        bloc: _foodBloc,
        builder: (context, fs) {
          if (_productsPending(ps, query) || _foodPending(fs, query)) {
            return _pendingSpinner;
          }
          final productsFailed =
              ps is ProductsFailedState ||
              (ps is ProductsLoadedState && ps.remoteSourceFailed);
          final foodFailed =
              fs is FoodFailedState ||
              (fs is FoodLoadedState && fs.remoteSourceFailed);
          final VoidCallback retryFailed = productsFailed && foodFailed
              ? _retryAll
              : (productsFailed ? _retryProducts : _retryFood);
          final merged = _offered(
            mergeAndRankMeals(
              ps is ProductsLoadedState ? ps.products : const [],
              fs is FoodLoadedState ? fs.food : const [],
              query,
            ),
          );
          final imperial = ps is ProductsLoadedState
              ? ps.usesImperialUnits
              : (fs is FoodLoadedState ? fs.usesImperialUnits : false);
          if (merged.isEmpty) {
            if (ps is ProductsInitial && fs is FoodInitial) {
              return const DefaultsResultsWidget();
            }
            if (productsFailed && foodFailed) return _error(context, _retryAll);
            if (productsFailed || foodFailed) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PartialResultsNotice(onRetry: retryFailed),
                    _noResults(),
                  ],
                ),
              );
            }
            return _noResults();
          }
          return Column(
            children: [
              if (productsFailed || foodFailed)
                PartialResultsNotice(
                  onRetry: retryFailed,
                  allSourcesDown: productsFailed && foodFailed,
                ),
              Expanded(
                child: _list('recipe-ingredient-all-list', merged, imperial),
              ),
            ],
          );
        },
      ),
    );
  }
}
