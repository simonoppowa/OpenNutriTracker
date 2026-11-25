import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_all_recipes_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'recipe_meal_event.dart';

part 'recipe_meal_state.dart';

/// Backs the Recipes source on the add-food screen (#1284): every saved
/// recipe, A to Z, so one whose name the user forgot is a tap away rather
/// than a search.
///
/// Follows the recipe box rather than waiting to be asked: a recipe saved,
/// edited or deleted on another screen re-runs the last query.
class RecipeMealBloc extends Bloc<RecipeMealEvent, RecipeMealState> {
  final log = Logger('RecipeMealBloc');

  final GetAllRecipesUseCase _getAllRecipesUseCase;
  final GetConfigUsecase _getConfigUsecase;

  StreamSubscription<void>? _changes;
  String _searchString = '';

  RecipeMealBloc(this._getAllRecipesUseCase, this._getConfigUsecase)
    : super(RecipeMealInitial()) {
    on<LoadRecipeMealEvent>((event, emit) async {
      _searchString = event.searchString;
      emit(RecipeMealLoadingState());
      await _load(emit);
    });
    on<_RecipesChangedEvent>((event, emit) async {
      // A refresh, not a new query: keep the list on screen while it reloads.
      if (state is RecipeMealInitial) return;
      await _load(emit);
    });
    _changes = _getAllRecipesUseCase.watch().listen(
      (_) => add(const _RecipesChangedEvent()),
    );
  }

  Future<void> _load(Emitter<RecipeMealState> emit) async {
    try {
      final config = await _getConfigUsecase.getConfig();
      final query = _searchString.trim().toLowerCase();
      final recipes =
          _getAllRecipesUseCase
              .getAll()
              .where(
                (recipe) =>
                    query.isEmpty || recipe.name.toLowerCase().contains(query),
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      emit(
        RecipeMealLoadedState(
          recipes: recipes.map((recipe) => recipe.toMealEntity()).toList(),
          usesImperialUnits: config.usesImperialFoodUnits,
        ),
      );
    } catch (error, stackTrace) {
      log.severe('Loading recipes failed', error, stackTrace);
      emit(RecipeMealFailedState());
    }
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
