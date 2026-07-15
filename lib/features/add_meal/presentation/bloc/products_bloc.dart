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

  ProductsBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(ProductsInitial()) {
    on<LoadProductsEvent>(
      (event, emit) => _loadProducts(event.searchString, emit, force: true),
    );
    on<SearchInputChangedEvent>(
      (event, emit) => _loadProducts(event.searchString, emit),
      transformer: debounceRestartable(searchDebounceDuration),
    );
    on<RefreshProductsEvent>((event, emit) async {
      if (_searchString.trim().isEmpty) {
        _completedQuery = null;
        emit(ProductsInitial());
        return;
      }
      emit(ProductsLoadingState());
      try {
        final result = await _searchProductUseCase.searchOFFProductsByString(
          _searchString,
        );
        if (emit.isDone) return;
        emit(ProductsLoadedState(
          products: result.meals,
          remoteSourceEmpty: result.remoteSourceEmpty,
          query: _searchString,
        ));
        _completedQuery = _searchString;
      } catch (error) {
        log.severe(error);
        _completedQuery = null;
        emit(ProductsFailedState());
      }
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
      _searchString = searchString;
      _completedQuery = null;
      if (state is! ProductsInitial) emit(ProductsInitial());
      return;
    }
    // Skip when this exact query's results are already on screen.
    if (!force && searchString == _completedQuery) {
      return;
    }
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
      // would be a no-op, so this run must not register as completed.
      if (emit.isDone) return;
      emit(
        ProductsLoadedState(
          products: result.meals,
          usesImperialUnits: config.usesImperialFoodUnits,
          remoteSourceEmpty: result.remoteSourceEmpty,
          query: searchString,
        ),
      );
      _completedQuery = searchString;
    } catch (error) {
      log.severe(error);
      _completedQuery = null;
      if (!emit.isDone) emit(ProductsFailedState());
    }
  }
}
