import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_favourite_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'favourite_meal_event.dart';

part 'favourite_meal_state.dart';

/// Backs the Favourites source on the add-food screen (#1307).
///
/// Follows the boxes rather than waiting to be asked: a star toggled on the
/// detail page or on a search result, or a starred custom meal or recipe
/// edited from there, re-runs the last query, so the list is already current
/// when the user comes back to it.
class FavouriteMealBloc extends Bloc<FavouriteMealEvent, FavouriteMealState> {
  final log = Logger('FavouriteMealBloc');

  final GetFavouriteMealsUsecase _getFavouriteMealsUsecase;
  final GetConfigUsecase _getConfigUsecase;

  StreamSubscription<void>? _changes;
  String _searchString = '';

  FavouriteMealBloc(this._getFavouriteMealsUsecase, this._getConfigUsecase)
    : super(FavouriteMealInitial()) {
    on<LoadFavouriteMealEvent>((event, emit) async {
      _searchString = event.searchString;
      emit(FavouriteMealLoadingState());
      await _load(emit);
    });
    on<_FavouritesChangedEvent>((event, emit) async {
      // A refresh, not a new query: keep the list on screen while it reloads.
      if (state is FavouriteMealInitial) return;
      await _load(emit);
    });
    _changes = _getFavouriteMealsUsecase.watchFavourites().listen(
      (_) => add(const _FavouritesChangedEvent()),
    );
  }

  Future<void> _load(Emitter<FavouriteMealState> emit) async {
    try {
      final config = await _getConfigUsecase.getConfig();
      final favourites = await _getFavouriteMealsUsecase.getAllFavourites();
      final query = _searchString.trim().toLowerCase();
      emit(
        FavouriteMealLoadedState(
          favourites: query.isEmpty
              ? favourites
              : favourites.where(_matches(query)).toList(),
          usesImperialUnits: config.usesImperialFoodUnits,
        ),
      );
    } catch (error) {
      log.severe(error);
      emit(FavouriteMealFailedState());
    }
  }

  bool Function(MealEntity) _matches(String query) =>
      (meal) =>
          (meal.name?.toLowerCase().contains(query) ?? false) ||
          (meal.brands?.toLowerCase().contains(query) ?? false);

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
