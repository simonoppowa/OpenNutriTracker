import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/search_debounce.dart';

part 'products_event.dart';

part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final log = Logger('ProductsBloc');

  final SearchProductsUseCase _searchProductUseCase;
  final GetConfigUsecase _getConfigUsecase;

  String _searchString = "";

  /// The last query whose results actually made it to the UI. Only ever
  /// set after a successful emit — a search that failed, or was cancelled
  /// mid-flight by the restartable transformer, must not count as done,
  /// otherwise typing the same query again is silently dropped (the
  /// "search only triggers sometimes" bug).
  String? _completedQuery;

  /// Bumped by every search run. The restartable transformer only cancels
  /// runs of its own event type, so a Retry or submit still awaiting a
  /// provider could otherwise land after a newer search and replace its
  /// results with ones for the old query. A run emits only while it is
  /// still the latest.
  int _generation = 0;

  ProductsBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(ProductsInitial()) {
    on<LoadProductsEvent>(
      (event, emit) => _loadProducts(event.searchString, emit, force: true),
    );
    on<SearchInputChangedEvent>(
      (event, emit) => _loadProducts(event.searchString, emit),
      transformer: debounceRestartable(searchDebounceDuration),
    );
    // Retry re-runs the last query through the normal path, so the result
    // carries the unit preference and provider-failure flag like any other
    // search. Blank to the spinner first: Retry needs visible feedback even
    // when the failed results are still on screen.
    on<RefreshProductsEvent>((event, emit) async {
      if (_searchString.trim().length >= minQueryLength) {
        emit(ProductsLoadingState());
      }
      await _loadProducts(_searchString, emit, force: true);
    });
  }

  /// Shared search routine for the immediate and debounced events.
  ///
  /// [force] runs even when the query is unchanged — set on the immediate
  /// path so an explicit submit always re-queries the remote source. A
  /// fresh search keeps any existing results on screen rather than
  /// blanking to a spinner, so typing doesn't flicker.
  Future<void> _loadProducts(
    String searchString,
    Emitter<ProductsState> emit, {
    bool force = false,
  }) async {
    // Sub-threshold queries (blank included) query nothing — not even
    // local sources. Chip taps and tab switches re-submit the current
    // field text, so this is the single guard keeping a too-short input
    // from triggering a search. Reset to Initial so the "start typing"
    // default widget shows.
    if (searchString.trim().length < minQueryLength) {
      // Supersedes any search still in flight: its results would replace
      // the reset below.
      _generation++;
      _searchString = searchString;
      _completedQuery = null;
      if (state is! ProductsInitial) emit(ProductsInitial());
      return;
    }
    // Skip when this exact query's results are already on screen.
    if (!force && searchString == _completedQuery) {
      return;
    }
    // Bumped only for a run that actually searches: a skipped duplicate
    // must not orphan the in-flight run it deferred to.
    final run = ++_generation;
    _searchString = searchString;
    // The no-blank rule keeps existing results visible while a refinement
    // is in flight — but only when there are results to keep. An empty
    // list would render as a premature "no results", so blank to the
    // spinner instead.
    final current = state;
    if (current is! ProductsLoadedState || current.products.isEmpty) {
      emit(ProductsLoadingState());
    }
    try {
      final result = await _searchProductUseCase.searchOFFProductsByString(
        searchString,
      );
      final config = await _getConfigUsecase.getConfig();
      // Cancelled by a newer debounced event while awaiting: the emit below
      // would be a no-op, so this run must not register as completed. A
      // newer run of another event type (submit, Retry, typing) is not
      // cancelled by the transformer, so the generation check drops it too.
      if (emit.isDone || run != _generation) return;
      emit(
        ProductsLoadedState(
          products: result.meals,
          usesImperialUnits: config.usesImperialFoodUnits,
          remoteSourceEmpty: result.remoteSourceEmpty,
          remoteSourceFailed: result.remoteSourceFailed,
          query: searchString,
        ),
      );
      _completedQuery = searchString;
    } catch (error) {
      if (run != _generation) return;
      log.severe(error);
      _completedQuery = null;
      if (!emit.isDone) emit(ProductsFailedState());
    }
  }
}
