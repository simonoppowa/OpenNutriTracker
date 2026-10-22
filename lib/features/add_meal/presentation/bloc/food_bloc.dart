import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/search_debounce.dart';

part 'food_event.dart';

part 'food_state.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final log = Logger('FoodBloc');

  final SearchProductsUseCase _searchProductUseCase;
  final GetConfigUsecase _getConfigUsecase;

  String _searchString = "";

  /// The last query whose results actually made it to the UI. See
  /// [ProductsBloc] — only a successful emit registers here, so failed or
  /// restart-cancelled runs never block a retype of the same query.
  String? _completedQuery;

  /// See [ProductsBloc]: only the latest search run of any event may emit.
  int _generation = 0;

  FoodBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(FoodInitial()) {
    on<LoadFoodEvent>(
      (event, emit) => _loadFood(event.searchString, emit, force: true),
    );
    on<SearchFoodInputChangedEvent>(
      (event, emit) => _loadFood(event.searchString, emit),
      transformer: debounceRestartable(searchDebounceDuration),
    );
    // Retry re-runs the last query through the normal path, so the result
    // carries the unit preference and provider-failure flag like any other
    // search. Blank to the spinner first: Retry needs visible feedback even
    // when the failed results are still on screen.
    on<RefreshFoodEvent>((event, emit) async {
      if (_searchString.trim().length >= minQueryLength) {
        emit(FoodLoadingState());
      }
      await _loadFood(_searchString, emit, force: true);
    });
  }

  /// Shared search routine for the immediate and debounced events. See
  /// [ProductsBloc] for the rationale behind [force], the min-length
  /// guard, the no-blank behaviour, and the completed-query dedup.
  Future<void> _loadFood(
    String searchString,
    Emitter<FoodState> emit, {
    bool force = false,
  }) async {
    if (searchString.trim().length < minQueryLength) {
      // Supersedes any search still in flight: its results would replace
      // the reset below.
      _generation++;
      _searchString = searchString;
      _completedQuery = null;
      if (state is! FoodInitial) emit(FoodInitial());
      return;
    }
    if (!force && searchString == _completedQuery) {
      return;
    }
    // Bumped only for a run that actually searches: a skipped duplicate
    // must not orphan the in-flight run it deferred to.
    final run = ++_generation;
    _searchString = searchString;
    // See ProductsBloc: keep visible results during a refinement, but an
    // empty list blanks to the spinner rather than a premature "no results".
    final current = state;
    if (current is! FoodLoadedState || current.food.isEmpty) {
      emit(FoodLoadingState());
    }
    try {
      final result = await _searchProductUseCase.searchFDCFoodByString(
        searchString,
      );
      final config = await _getConfigUsecase.getConfig();
      // See ProductsBloc: a newer run of any event type supersedes this one.
      if (emit.isDone || run != _generation) return;
      emit(
        FoodLoadedState(
          food: result.meals,
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
      if (!emit.isDone) emit(FoodFailedState());
    }
  }
}
