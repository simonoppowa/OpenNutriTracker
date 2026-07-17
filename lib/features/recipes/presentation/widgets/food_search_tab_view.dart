import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/search_debounce.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/default_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_search_bar.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Reusable 3-tab food search (Products / Food / Recently) that delegates the
/// "selected" action to a callback rather than pushing MealDetailScreen.
/// Used by the recipe builder to add ingredients without touching the
/// existing AddMealScreen flow.
class FoodSearchTabView extends StatefulWidget {
  final void Function(MealEntity meal) onMealSelected;
  // When non-null, the search bar shows a barcode-scan suffix icon and
  // taps are forwarded here. The recipe builder uses this to push the
  // scanner in pick mode and feed the result back through [onMealSelected].
  final VoidCallback? onBarcodePressed;

  const FoodSearchTabView({
    super.key,
    required this.onMealSelected,
    this.onBarcodePressed,
  });

  @override
  State<FoodSearchTabView> createState() => _FoodSearchTabViewState();
}

class _FoodSearchTabViewState extends State<FoodSearchTabView>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<String> _searchStringListener = ValueNotifier('');

  late ProductsBloc _productsBloc;
  late FoodBloc _foodBloc;
  late RecentMealBloc _recentMealBloc;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _productsBloc = locator<ProductsBloc>();
    _foodBloc = locator<FoodBloc>();
    _recentMealBloc = locator<RecentMealBloc>();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      _onSearchSubmit(_searchStringListener.value);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          MealSearchBar(
            searchStringListener: _searchStringListener,
            onSearchSubmit: _onSearchSubmit,
            onSearchChanged: _onSearchChanged,
            onBarcodePressed: widget.onBarcodePressed,
          ),
          const SizedBox(height: 16),
          TabBar(
            tabs: [
              Tab(text: S.of(context).searchProductsPage),
              Tab(text: S.of(context).searchFoodPage),
              Tab(text: S.of(context).recentlyAddedLabel),
            ],
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(context),
                _buildFoodTab(context),
                _buildRecentTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _pendingSpinner = Center(
    child: Padding(
      padding: EdgeInsets.only(top: 32),
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(),
      ),
    ),
  );

  Widget _buildProductsTab(BuildContext context) {
    // Rebuild on keystrokes so an empty list can tell "no results for this
    // query" apart from "the search for it is still debouncing/in flight"
    // (loaded-state query lags behind the field) — the latter spins.
    return ValueListenableBuilder<String>(
      valueListenable: _searchStringListener,
      builder: (context, query, _) => BlocBuilder<ProductsBloc, ProductsState>(
        bloc: _productsBloc,
        builder: (context, state) {
        if (state is ProductsInitial) {
          return query.trim().length >= minQueryLength
              ? _pendingSpinner
              : const DefaultsResultsWidget();
        }
        if (state is ProductsLoadingState) {
          return _pendingSpinner;
        }
        if (state is ProductsLoadedState) {
          if (state.products.isEmpty) {
            return query.trim().length >= minQueryLength &&
                    state.query != query
                ? _pendingSpinner
                : const NoResultsWidget();
          }
          return ListView.builder(
            itemCount:
                state.products.length + (state.remoteSourceEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.products.length) {
                return const NoResultsWidget();
              }
              return _PickableMealCard(
                meal: state.products[index],
                onTap: widget.onMealSelected,
              );
            },
          );
        }
        if (state is ProductsFailedState) {
          return ErrorDialog(
            errorText: S.of(context).errorFetchingProductData,
            onRefreshPressed: () =>
                _productsBloc.add(const RefreshProductsEvent()),
          );
        }
        return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFoodTab(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _searchStringListener,
      builder: (context, query, _) => BlocBuilder<FoodBloc, FoodState>(
        bloc: _foodBloc,
        builder: (context, state) {
        if (state is FoodInitial) {
          return query.trim().length >= minQueryLength
              ? _pendingSpinner
              : const DefaultsResultsWidget();
        }
        if (state is FoodLoadingState) {
          return _pendingSpinner;
        }
        if (state is FoodLoadedState) {
          if (state.food.isEmpty) {
            return query.trim().length >= minQueryLength &&
                    state.query != query
                ? _pendingSpinner
                : const NoResultsWidget();
          }
          return ListView.builder(
            itemCount: state.food.length + (state.remoteSourceEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.food.length) return const NoResultsWidget();
              return _PickableMealCard(
                meal: state.food[index],
                onTap: widget.onMealSelected,
              );
            },
          );
        }
        if (state is FoodFailedState) {
          return ErrorDialog(
            errorText: S.of(context).errorFetchingProductData,
            onRefreshPressed: () => _foodBloc.add(const RefreshFoodEvent()),
          );
        }
        return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRecentTab(BuildContext context) {
    return BlocBuilder<RecentMealBloc, RecentMealState>(
      bloc: _recentMealBloc,
      builder: (context, state) {
        if (state is RecentMealInitial) {
          _recentMealBloc.add(const LoadRecentMealEvent(searchString: ''));
          return const SizedBox.shrink();
        }
        if (state is RecentMealLoadingState) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 32),
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        if (state is RecentMealLoadedState) {
          if (state.recentMeals.isEmpty) return const NoResultsWidget();
          return ListView.builder(
            itemCount: state.recentMeals.length,
            itemBuilder: (context, index) => _PickableMealCard(
              meal: state.recentMeals[index],
              onTap: widget.onMealSelected,
            ),
          );
        }
        if (state is RecentMealFailedState) {
          return ErrorDialog(
            errorText: S.of(context).noMealsRecentlyAddedLabel,
            onRefreshPressed: () => _recentMealBloc.add(
              const LoadRecentMealEvent(searchString: ''),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _onSearchSubmit(String inputText) {
    switch (_tabController.index) {
      case 0:
        _productsBloc.add(LoadProductsEvent(searchString: inputText));
      case 1:
        _foodBloc.add(LoadFoodEvent(searchString: inputText));
      case 2:
        _recentMealBloc.add(LoadRecentMealEvent(searchString: inputText));
    }
  }

  /// Debounced search-as-you-type for the ingredient picker. Recent-added
  /// (tab 2) stays submit-only — local-history filter, nothing to debounce.
  void _onSearchChanged(String inputText) {
    switch (_tabController.index) {
      case 0:
        _productsBloc.add(SearchInputChangedEvent(searchString: inputText));
      case 1:
        _foodBloc.add(SearchFoodInputChangedEvent(searchString: inputText));
    }
  }
}

class _PickableMealCard extends StatelessWidget {
  final MealEntity meal;
  final void Function(MealEntity meal) onTap;

  const _PickableMealCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing8, vertical: Dimens.spacing4),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: Dimens.borderRadiusL,
          onTap: () => onTap(meal),
          child: Padding(
            padding: const EdgeInsets.all(Dimens.spacing12),
            child: Row(
              children: [
                meal.thumbnailImageUrl != null
                    ? ClipRRect(
                        borderRadius: Dimens.borderRadiusS,
                        child: CachedNetworkImage(
                          cacheManager: locator<CacheManager>(),
                          fit: BoxFit.cover,
                          width: 52,
                          height: 52,
                          imageUrl: meal.thumbnailImageUrl ?? '',
                        ),
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: Dimens.borderRadiusS,
                        ),
                        child: Icon(
                          meal.source == MealSourceEntity.recipe
                              ? Icons.menu_book_rounded
                              : Icons.restaurant_rounded,
                          color: accent,
                          size: 24,
                        ),
                      ),
                const SizedBox(width: Dimens.spacing12),
                Expanded(
                  child: AutoSizeText.rich(
                    TextSpan(
                      text: meal.name ?? '?',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      children: [
                        TextSpan(
                          text: ' ${meal.brands ?? ''}',
                          style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                        ),
                      ],
                    ),
                    style: textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Dimens.spacing8),
                Icon(Icons.add_circle_outline_rounded, color: accent, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
