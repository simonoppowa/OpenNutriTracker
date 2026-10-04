import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_favourite_meals_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/toggle_favourite_meal_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'favourite_toggle_event.dart';

part 'favourite_toggle_state.dart';

/// Backs one star (#1307): whether its meal is a favourite, and flipping it.
///
/// Each star has its own, so the same food shown on a search result and on
/// its detail page stays in step through the box rather than through the
/// widget tree — the detail page is a separate route.
class FavouriteToggleBloc
    extends Bloc<FavouriteToggleEvent, FavouriteToggleState> {
  final log = Logger('FavouriteToggleBloc');

  final GetFavouriteMealsUsecase _getFavouriteMealsUsecase;
  final ToggleFavouriteMealUsecase _toggleFavouriteMealUsecase;

  StreamSubscription<void>? _changes;
  MealEntity? _meal;

  FavouriteToggleBloc(
    this._getFavouriteMealsUsecase,
    this._toggleFavouriteMealUsecase,
  ) : super(const FavouriteToggleState()) {
    on<LoadFavouriteStatusEvent>((event, emit) async {
      _meal = event.meal;
      await _refresh(emit);
    });
    on<ToggleFavouriteEvent>((event, emit) async {
      _meal = event.meal;
      try {
        final isFavourite = await _toggleFavouriteMealUsecase.toggle(
          event.meal,
        );
        emit(FavouriteToggleState(isFavourite: isFavourite));
      } catch (error) {
        log.severe(error);
      }
    });
    on<_FavouritesChangedEvent>((event, emit) => _refresh(emit));
    _changes = _getFavouriteMealsUsecase.watchFavourites().listen(
      (_) => add(const _FavouritesChangedEvent()),
    );
  }

  Future<void> _refresh(Emitter<FavouriteToggleState> emit) async {
    final meal = _meal;
    if (meal == null) return;
    try {
      final isFavourite = await _getFavouriteMealsUsecase.isFavourite(meal);
      emit(FavouriteToggleState(isFavourite: isFavourite));
    } catch (error) {
      log.severe(error);
    }
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
