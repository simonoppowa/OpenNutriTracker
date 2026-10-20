import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_favourite_meals_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/toggle_favourite_meal_usecase.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
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
    // One write at a time, toggles and hydrations in the same queue
    // (`sequential()` queues per registration, so they share one). Each
    // toggle reads the stored state before writing it: a double tap run side
    // by side would read before the first write landed and star the meal
    // twice. A hydration run beside a pending star would find nothing
    // starred yet and do nothing, leaving the thin record stored for good.
    on<FavouriteWriteEvent>((event, emit) async {
      switch (event) {
        case ToggleFavouriteEvent():
          await _toggle(event, emit);
        case FavouriteMealHydratedEvent():
          try {
            await _toggleFavouriteMealUsecase.refreshDetailedSnapshot(
              event.meal,
            );
          } catch (error) {
            log.severe(error);
          }
      }
    }, transformer: sequential());
    on<_FavouritesChangedEvent>((event, emit) => _refresh(emit));
    _changes = _getFavouriteMealsUsecase.watchFavourites().listen(
      (_) => add(const _FavouritesChangedEvent()),
    );
  }

  Future<void> _toggle(
    ToggleFavouriteEvent event,
    Emitter<FavouriteToggleState> emit,
  ) async {
    _meal ??= event.meal;
    try {
      final isFavourite = await _toggleFavouriteMealUsecase.toggle(
        event.meal,
        startedOn: event.startedOn,
      );
      if (isFavourite == null) {
        // A profile switch overtook the tap and nothing was written; show
        // the star as the now-active profile has it.
        await _refresh(emit);
        return;
      }
      // A recycled row may have been handed another food while the write
      // was pending; that food's own load says how its star shows.
      if (_isBound(event.meal)) {
        emit(FavouriteToggleState(isFavourite: isFavourite));
      }
    } catch (error) {
      log.severe(error);
    }
  }

  Future<void> _refresh(Emitter<FavouriteToggleState> emit) async {
    final meal = _meal;
    if (meal == null) return;
    try {
      final isFavourite = await _getFavouriteMealsUsecase.isFavourite(meal);
      // Dropped when the row was rebound during the read.
      if (_isBound(meal)) {
        emit(FavouriteToggleState(isFavourite: isFavourite));
      }
    } catch (error) {
      log.severe(error);
    }
  }

  /// Whether [meal] is the food this star shows now, compared by favourite
  /// key as the button compares a recycled row's food.
  bool _isBound(MealEntity meal) {
    final bound = _meal;
    return bound != null &&
        FavouriteMealRepository.keyOf(bound) ==
            FavouriteMealRepository.keyOf(meal);
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
