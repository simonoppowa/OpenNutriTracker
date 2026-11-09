import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'recent_meal_event.dart';

part 'recent_meal_state.dart';

class RecentMealBloc extends Bloc<RecentMealEvent, RecentMealState> {
  final log = Logger('RecentMealBloc');

  final Future<List<MealEntity>> Function() _loadRecentMeals;
  final GetConfigUsecase _getConfigUsecase;

  /// The recent history and unit preference from the last read of storage.
  /// Loading recents copies and sorts the whole intake box, so keystrokes
  /// filter this snapshot in memory instead of re-reading it per character.
  /// Kept as a future so a keystroke that arrives while a load is still
  /// running waits for that load rather than starting a second one.
  Future<_RecentSnapshot>? _snapshot;

  /// The add-meal Recently list: the foods this profile logged.
  RecentMealBloc(
    GetIntakeUsecase getIntakeUsecase,
    GetConfigUsecase getConfigUsecase,
  ) : this.fromSource(
        () async => [
          for (final intake in await getIntakeUsecase.getRecentIntake())
            intake.meal,
        ],
        getConfigUsecase,
      );

  /// A recent list read from [loadRecentMeals] instead of the intake log,
  /// such as the recipe ingredient picker's (#516). It is called once per
  /// load, with the newest food first.
  RecentMealBloc.fromSource(
    Future<List<MealEntity>> Function() loadRecentMeals,
    this._getConfigUsecase,
  ) : _loadRecentMeals = loadRecentMeals,
      super(RecentMealInitial()) {
    on<LoadRecentMealEvent>((event, emit) async {
      _snapshot = null;
      await _emitFiltered(event.searchString, emit);
    });
    // Newest keystroke wins: an older one still waiting on the first load
    // must not overwrite the newer filter when that load completes.
    on<RecentMealSearchChangedEvent>(
      (event, emit) => _emitFiltered(event.searchString, emit),
      transformer: restartable(),
    );
  }

  Future<void> _emitFiltered(
    String searchString,
    Emitter<RecentMealState> emit,
  ) async {
    // Only blank to the spinner when storage actually has to be read; an
    // in-memory filter is instant and would just flicker.
    if (_snapshot == null) emit(RecentMealLoadingState());
    try {
      final snapshot = await (_snapshot ??= _loadSnapshot());
      if (emit.isDone) return;
      final query = searchString.toLowerCase();
      final matches = query.isEmpty
          ? snapshot.meals
          : snapshot.meals.where(matchesSearchString(query));
      emit(
        RecentMealLoadedState(
          recentMeals: matches.toList(),
          usesImperialUnits: snapshot.usesImperialUnits,
        ),
      );
    } catch (error) {
      log.severe(error);
      // Forget the failed read so Retry (or the next keystroke) tries again.
      _snapshot = null;
      if (!emit.isDone) emit(RecentMealFailedState());
    }
  }

  Future<_RecentSnapshot> _loadSnapshot() async {
    final config = await _getConfigUsecase.getConfig();
    final recentMeals = await _loadRecentMeals();
    return _RecentSnapshot(recentMeals, config.usesImperialFoodUnits);
  }

  bool Function(MealEntity) matchesSearchString(String searchString) {
    return (meal) =>
        (meal.name?.toLowerCase().contains(searchString) ?? false) ||
        (meal.brands?.toLowerCase().contains(searchString) ?? false);
  }
}

class _RecentSnapshot {
  final List<MealEntity> meals;
  final bool usesImperialUnits;

  const _RecentSnapshot(this.meals, this.usesImperialUnits);
}
