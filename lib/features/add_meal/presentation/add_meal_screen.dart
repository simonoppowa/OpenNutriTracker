import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/search_debounce.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/default_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/quick_add_bottom_sheet.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/features/scanner/util/barcode_check_digit.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final ValueNotifier<String> _searchStringListener = ValueNotifier('');

  late AddMealType _mealType;
  late DateTime _day;

  late ProductsBloc _productsBloc;
  late FoodBloc _foodBloc;
  late RecentMealBloc _recentMealBloc;

  // Single smart search: one field, one results list, and source-filter chips.
  // Opens on Recent (fast re-logging); typing searches Products by default,
  // with Food / Recent a chip away.
  _SearchSource _source = _SearchSource.recent;

  @override
  void initState() {
    _productsBloc = locator<ProductsBloc>();
    _foodBloc = locator<FoodBloc>();
    _recentMealBloc = locator<RecentMealBloc>();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as AddMealScreenArguments;
    _mealType = args.mealType;
    _day = args.day;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _searchStringListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Scaffold(
      // Let the keyboard overlay the results rather than compress the body.
      // In landscape the space above the keyboard is shorter than the pinned
      // search bar + tab bar, which otherwise overflows (issue #165 testing).
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(_mealType.getTypeName(context)),
        actions: [
          Semantics(
            identifier: 'add-meal-quick-add',
            child: TextButton(
              onPressed: _onQuickAddPressed,
              child: Text(S.of(context).quickAddCardLabel),
            ),
          ),
          BlocBuilder<AddMealBloc, AddMealState>(
            bloc: locator<AddMealBloc>()..add(InitializeAddMealEvent()),
            builder: (BuildContext context, AddMealState state) {
              if (state is AddMealLoadedState) {
                return IconButton(
                  onPressed: () =>
                      _onCustomAddButtonPressed(state.usesImperialUnits),
                  icon: const Icon(Icons.add_circle_outline),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing16),
          child: Column(
            children: [
              const SizedBox(height: Dimens.spacing8),
              MealSearchBar(
                searchStringListener: _searchStringListener,
                onSearchSubmit: _onSearchSubmit,
                onSearchChanged: _onSearchChanged,
                onBarcodePressed: _onBarcodeIconPressed,
              ),
              const SizedBox(height: Dimens.spacing12),
              _buildSourceChips(context, palette),
              const SizedBox(height: Dimens.spacing12),
              // Rebuild on every keystroke so the empty-state logic can tell
              // "no results for this query" apart from "a newer query is
              // still debouncing/searching" — the latter shows a spinner.
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _searchStringListener,
                  builder: (context, query, _) =>
                      _buildResults(context, palette, query),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onProductsRefreshButtonPressed() {
    _productsBloc.add(const RefreshProductsEvent());
  }

  void _onFoodRefreshButtonPressed() {
    _foodBloc.add(const RefreshFoodEvent());
  }

  void _onRecentMealsRefreshButtonPressed() {
    _recentMealBloc.add(const LoadRecentMealEvent(searchString: ""));
  }

  /// Resolves the source to search for a query: an empty query always returns
  /// to Recent; a non-empty query searches Products by default, unless the user
  /// has explicitly chosen Food. Keeps the chip selection and the results in sync.
  _SearchSource _resolveSource(String trimmed) {
    if (trimmed.isEmpty) return _SearchSource.recent;
    // Typing searches every source at once (All); an explicit Products / Food
    // choice narrows that merged list.
    return _source == _SearchSource.recent ? _SearchSource.all : _source;
  }

  bool _searchesProducts(_SearchSource s) =>
      s == _SearchSource.all || s == _SearchSource.products;
  bool _searchesFood(_SearchSource s) =>
      s == _SearchSource.all || s == _SearchSource.food;

  void _onSearchSubmit(String inputText) {
    final trimmed = inputText.trim();
    final source = _resolveSource(trimmed);
    if (source != _source) setState(() => _source = source);
    // A scannable barcode jumps straight to the scanner (product sources only).
    if (_searchesProducts(source) && isValidBarcodeCheckDigit(trimmed)) {
      Navigator.of(context).pushNamed(
        NavigationOptions.scannerRoute,
        arguments: ScannerScreenArguments(
          _day,
          _mealType.getIntakeType(),
          initialBarcode: trimmed,
        ),
      );
      return;
    }
    if (_searchesProducts(source)) {
      _productsBloc.add(LoadProductsEvent(searchString: inputText));
    }
    if (_searchesFood(source)) {
      _foodBloc.add(LoadFoodEvent(searchString: inputText));
    }
    if (source == _SearchSource.recent) {
      _recentMealBloc.add(LoadRecentMealEvent(searchString: inputText));
    }
  }

  /// Debounced search-as-you-type. Recent filters local intake history; the
  /// remote sources debounce via their own *InputChanged events. "All" searches
  /// products and food together into one merged list.
  void _onSearchChanged(String inputText) {
    final trimmed = inputText.trim();
    final source = _resolveSource(trimmed);
    if (source != _source) setState(() => _source = source);
    if (_searchesProducts(source)) {
      _productsBloc.add(SearchInputChangedEvent(searchString: inputText));
    }
    if (_searchesFood(source)) {
      _foodBloc.add(SearchFoodInputChangedEvent(searchString: inputText));
    }
    if (source == _SearchSource.recent) {
      _recentMealBloc.add(LoadRecentMealEvent(searchString: inputText));
    }
  }

  void _selectSource(_SearchSource source) {
    setState(() => _source = source);
    final query = _searchStringListener.value;
    if (_searchesProducts(source)) {
      _productsBloc.add(LoadProductsEvent(searchString: query));
    }
    if (_searchesFood(source)) {
      _foodBloc.add(LoadFoodEvent(searchString: query));
    }
    if (source == _SearchSource.recent) {
      _recentMealBloc.add(LoadRecentMealEvent(searchString: query));
    }
  }

  Widget _buildSourceChips(BuildContext context, AppPalette palette) {
    Widget chip(_SearchSource source, String label) => Padding(
          padding: const EdgeInsets.only(right: Dimens.spacing8),
          child: ChoiceChip(
            label: Text(label),
            selected: _source == source,
            showCheckmark: false,
            onSelected: (_) => _selectSource(source),
          ),
        );
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(_SearchSource.recent, S.of(context).recentlyAddedLabel),
            chip(_SearchSource.all, S.of(context).allItemsLabel),
            chip(_SearchSource.products, S.of(context).searchProductsPage),
            chip(_SearchSource.food, S.of(context).searchFoodPage),
          ],
        ),
      ),
    );
  }

  Widget _resultsHeader(BuildContext context, AppPalette palette) => Container(
        padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
        alignment: Alignment.centerLeft,
        child: Text(
          S.of(context).searchResultsLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textMuted,
              ),
        ),
      );

  /// True while the results carried by [state] lag behind [query]: the
  /// search for the current input is still debouncing or in flight. Empty
  /// views show a spinner in that window instead of a premature "no
  /// results". Sub-threshold input never searches, so it is never pending;
  /// failed states return false so the error stays visible.
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

  // Fixed-size and top-aligned: the "All" view returns this inside an
  // Expanded, whose tight constraints would otherwise stretch the
  // indicator across the whole results area.
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

  Widget _buildResults(BuildContext context, AppPalette palette, String query) {
    switch (_source) {
      case _SearchSource.all:
        // One merged list across product sources; each card already shows its
        // own brand/source, so provenance stays clear.
        return Column(
          children: [
            _resultsHeader(context, palette),
            Expanded(
              child: BlocBuilder<ProductsBloc, ProductsState>(
                bloc: _productsBloc,
                builder: (context, ps) {
                  return BlocBuilder<FoodBloc, FoodState>(
                    bloc: _foodBloc,
                    builder: (context, fs) {
                      // Wait for BOTH sources (OFF and the Supabase backend)
                      // before rendering the merged list — showing whichever
                      // lands first would make results pop in and shift when
                      // the second source arrives. A failed source counts as
                      // answered, so one outage doesn't block the other's
                      // results.
                      if (_productsPending(ps, query) ||
                          _foodPending(fs, query)) {
                        return _pendingSpinner;
                      }
                      final products =
                          ps is ProductsLoadedState ? ps.products : const <MealEntity>[];
                      final foods =
                          fs is FoodLoadedState ? fs.food : const <MealEntity>[];
                      final merged = [...products, ...foods];
                      if (merged.isEmpty) {
                        if (ps is ProductsInitial && fs is FoodInitial) {
                          return const DefaultsResultsWidget();
                        }
                        return const NoResultsWidget();
                      }
                      final imperial = ps is ProductsLoadedState
                          ? ps.usesImperialUnits
                          : (fs is FoodLoadedState ? fs.usesImperialUnits : false);
                      return ListView.builder(
                        itemCount: merged.length,
                        itemBuilder: (context, index) => MealItemCard(
                          day: _day,
                          mealEntity: merged[index],
                          addMealType: _mealType,
                          usesImperialUnits: imperial,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      case _SearchSource.products:
        return Column(
          children: [
            _resultsHeader(context, palette),
            BlocBuilder<ProductsBloc, ProductsState>(
              bloc: _productsBloc,
              builder: (context, state) {
                if (state is ProductsInitial) {
                  return _productsPending(state, query)
                      ? _pendingSpinner
                      : const DefaultsResultsWidget();
                } else if (state is ProductsLoadingState) {
                  return _pendingSpinner;
                } else if (state is ProductsLoadedState) {
                  if (state.products.isEmpty) {
                    return _productsPending(state, query)
                        ? _pendingSpinner
                        : const NoResultsWidget();
                  }
                  return Flexible(
                    child: ListView.builder(
                      itemCount:
                          state.products.length + (state.remoteSourceEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.products.length) {
                          return const NoResultsWidget();
                        }
                        return MealItemCard(
                          day: _day,
                          mealEntity: state.products[index],
                          addMealType: _mealType,
                          usesImperialUnits: state.usesImperialUnits,
                        );
                      },
                    ),
                  );
                } else if (state is ProductsFailedState) {
                  return ErrorDialog(
                    errorText: S.of(context).errorFetchingProductData,
                    onRefreshPressed: _onProductsRefreshButtonPressed,
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        );
      case _SearchSource.food:
        return Column(
          children: [
            _resultsHeader(context, palette),
            BlocBuilder<FoodBloc, FoodState>(
              bloc: _foodBloc,
              builder: (context, state) {
                if (state is FoodInitial) {
                  return _foodPending(state, query)
                      ? _pendingSpinner
                      : const DefaultsResultsWidget();
                } else if (state is FoodLoadingState) {
                  return _pendingSpinner;
                } else if (state is FoodLoadedState) {
                  if (state.food.isEmpty) {
                    return _foodPending(state, query)
                        ? _pendingSpinner
                        : const NoResultsWidget();
                  }
                  return Flexible(
                    child: ListView.builder(
                      itemCount: state.food.length + (state.remoteSourceEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.food.length) {
                          return const NoResultsWidget();
                        }
                        return MealItemCard(
                          day: _day,
                          mealEntity: state.food[index],
                          addMealType: _mealType,
                          usesImperialUnits: state.usesImperialUnits,
                        );
                      },
                    ),
                  );
                } else if (state is FoodFailedState) {
                  return ErrorDialog(
                    errorText: S.of(context).errorFetchingProductData,
                    onRefreshPressed: _onFoodRefreshButtonPressed,
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        );
      case _SearchSource.recent:
        return BlocBuilder<RecentMealBloc, RecentMealState>(
          bloc: _recentMealBloc,
          builder: (context, state) {
            if (state is RecentMealInitial) {
              _recentMealBloc.add(const LoadRecentMealEvent(searchString: ""));
              return const SizedBox();
            } else if (state is RecentMealLoadingState) {
              return const Padding(
                padding: EdgeInsets.only(top: 32),
                child: CircularProgressIndicator(),
              );
            } else if (state is RecentMealLoadedState) {
              return state.recentMeals.isNotEmpty
                  ? ListView.builder(
                      itemCount: state.recentMeals.length,
                      itemBuilder: (context, index) {
                        return MealItemCard(
                          day: _day,
                          mealEntity: state.recentMeals[index],
                          addMealType: _mealType,
                          usesImperialUnits: state.usesImperialUnits,
                        );
                      },
                    )
                  : const NoResultsWidget();
            } else if (state is RecentMealFailedState) {
              return ErrorDialog(
                errorText: S.of(context).noMealsRecentlyAddedLabel,
                onRefreshPressed: _onRecentMealsRefreshButtonPressed,
              );
            }
            return const SizedBox();
          },
        );
    }
  }

  void _onBarcodeIconPressed() {
    Navigator.of(context).pushNamed(
      NavigationOptions.scannerRoute,
      arguments: ScannerScreenArguments(_day, _mealType.getIntakeType()),
    );
  }

  void _onQuickAddPressed() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => QuickAddBottomSheet(
        intakeType: _mealType.getIntakeType(),
        day: _day,
      ),
    );
  }

  void _onCustomAddButtonPressed(bool usesImperialUnits) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).createCustomDialogTitle),
          content: Text(S.of(context).createCustomDialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // close dialog
              child: Text(S.of(context).dialogCancelLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _openEditMealScreen(usesImperialUnits);
              },
              child: Text(S.of(context).buttonYesLabel),
            ),
          ],
        );
      },
    );
  }

  void _openEditMealScreen(bool usesImperialUnits) {
    Navigator.of(context).pushNamed(
      NavigationOptions.editMealRoute,
      arguments: EditMealScreenArguments(
        _day,
        MealEntity.empty(),
        _mealType.getIntakeType(),
        usesImperialUnits,
      ),
    );
  }
}

class AddMealScreenArguments {
  final AddMealType mealType;
  final DateTime day;

  AddMealScreenArguments(this.mealType, this.day);
}

enum _SearchSource { recent, all, products, food }
