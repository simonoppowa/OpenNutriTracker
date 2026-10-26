import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/toggle_favourite_meal_usecase.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/meal_detail/util/hydrate_off_meal.dart';
import 'package:opennutritracker/features/meal_detail/util/meal_quantity_converter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'meal_detail_event.dart';

part 'meal_detail_state.dart';

class MealDetailBloc extends Bloc<MealDetailEvent, MealDetailState> {
  final log = Logger('MealDetailBloc');
  final AddIntakeUsecase _addIntakeUseCase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final GetTrackedDayUsecase _getTrackedDayUsecase;
  final ProductsRepository _productsRepository;
  final RemoteSearchCacheDataSource _remoteSearchCacheDataSource;

  /// Takes the background refresh's fresh record onto a favourite of the
  /// food (#1307). Left out where a test does not log a starred food.
  final ToggleFavouriteMealUsecase? _favourites;

  /// Takes a stored intake back out when the tracked-day update after it
  /// fails (#1461). Left out where a test never fails that update.
  final DeleteIntakeUsecase? _deleteIntakeUsecase;

  MealDetailBloc(
    this._addIntakeUseCase,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
    this._getTrackedDayUsecase,
    this._productsRepository,
    this._remoteSearchCacheDataSource, {
    ToggleFavouriteMealUsecase? favourites,
    DeleteIntakeUsecase? deleteIntake,
  }) : _favourites = favourites,
       _deleteIntakeUsecase = deleteIntake,
       super(
          MealDetailInitial(
            totalQuantityConverted: '100',
            selectedUnit: UnitDropdownItem.gml.toString(),
          ),
        ) {
    on<UpdateKcalEvent>((event, emit) async {
      try {
        final selectedTotalQuantity =
            event.totalQuantity ?? state.totalQuantityConverted;
        final selectedUnit = event.selectedUnit ?? state.selectedUnit;

        if (selectedUnit.isEmpty || selectedTotalQuantity.isEmpty) {
          return;
        }

        final energyPerUnit = (event.meal.nutriments.energyPerUnit ?? 0);
        final carbsPerUnit = (event.meal.nutriments.carbohydratesPerUnit ?? 0);
        final fatPerUnit = (event.meal.nutriments.fatPerUnit ?? 0);
        final proteinPerUnit = (event.meal.nutriments.proteinsPerUnit ?? 0);

        final quantity = double.parse(
          selectedTotalQuantity.replaceAll(',', '.'),
        );

        // Shared with the bulk-add screen so the two paths cannot drift.
        final convertedQuantity = convertQuantityToBaseUnit(
          quantity,
          selectedUnit,
          event.meal,
        );

        emit(
          state.copyWith(
            totalQuantityConverted: convertedQuantity.toString(),
            totalKcal: convertedQuantity * energyPerUnit,
            totalCarbs: convertedQuantity * carbsPerUnit,
            totalFat: convertedQuantity * fatPerUnit,
            totalProtein: convertedQuantity * proteinPerUnit,
            selectedUnit: selectedUnit,
          ),
        );
      } catch (e) {
        log.severe('Error calculating kcal: $e');
        Sentry.captureException(e);
      }
    });

    on<LoadDailyTotalsEvent>((event, emit) async {
      try {
        final tracked = await _getTrackedDayUsecase.getTrackedDay(event.day);
        if (tracked != null) {
          emit(
            state.copyWith(
              dayKcalConsumed: tracked.caloriesTracked,
              dayKcalGoal: tracked.calorieGoal,
            ),
          );
        } else {
          final goal = await _getKcalGoalUsecase.getKcalGoal();
          emit(
            state.copyWith(
              dayKcalConsumed: 0,
              dayKcalGoal: goal,
            ),
          );
        }
      } catch (e) {
        log.severe('Error loading daily totals: $e');
        Sentry.captureException(e);
      }
    });

    on<HydrateMealEvent>((event, emit) async {
      final meal = event.meal;
      final code = meal.code;
      if (meal.source != MealSourceEntity.off ||
          meal.detailed ||
          code == null ||
          code.isEmpty) {
        return;
      }

      emit(state.copyWith(isHydrating: true));
      try {
        // A full cache entry (from an earlier scan/hydration) lets us skip the
        // network entirely and works offline; otherwise fetch and cache it.
        // Shared with the + on a search result, which has to pick its default
        // amount from the same record.
        final full = await fetchDetailedOffMeal(
          meal,
          _remoteSearchCacheDataSource,
          _productsRepository,
        );
        emit(state.copyWith(hydratedMeal: full, isHydrating: false));
      } catch (e, st) {
        // Soft failure: keep the thin result so the user can still log
        // macros-only. The Add button is never blocked on hydration.
        log.warning('OFF hydration failed for $code', e, st);
        emit(state.copyWith(isHydrating: false));
      }
    });
  }

  /// Returns a future so callers writing more than one intake can await
  /// each in turn. The tracked-day totals are accumulated with a
  /// read-modify-write (`TrackedDayDataSource.addDayCaloriesTracked`), so
  /// overlapping calls interleave their reads and silently lose updates —
  /// a batch logged concurrently under-counts the day.
  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity type,
    MealEntity meal,
    DateTime day,
  ) async {
    final quantity = double.parse(amountText.replaceAll(',', '.'));

    final intakeEntity = IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: unit,
      amount: quantity,
      type: type,
      meal: meal,
      dateTime: day,
    );
    // Write the intake immediately so the Home/Diary refresh that
    // follows on the caller side picks it up. The cache refresh happens
    // in the background — the user shouldn't wait for an OFF round-trip
    // (up to 60 s timeout) before seeing their item logged. Stale meal
    // data in the intake is fine; nutrition values rarely change, and
    // the cache update means the next search shows the freshest data.
    // The entry and its row together, so no reconciliation counts the
    // entry before the row has it (#1317).
    //
    // All or nothing (#1461): a failure after the intake is stored takes it
    // back out and puts the day's totals back to what they were, so the
    // caller's retry starts from where the first attempt did instead of
    // logging the food a second time.
    await withTrackedDayLockOnProfile(() async {
      await _addIntakeUseCase.addIntake(intakeEntity);
      TrackedDayEntity? before;
      try {
        await _updateTrackedDay(
          intakeEntity,
          day,
          onBefore: (totals) => before = totals,
        );
      } catch (e, st) {
        await _rollBackIntake(intakeEntity, day, before, e, st);
        rethrow;
      }
    });
    unawaited(_refreshCacheForSelectedMeal(meal));
  }

  /// Best-effort cache refresh after the user logs a meal. For OFF items
  /// with a barcode, attempts a fresh lookup and overwrites the cache
  /// entry with the result. For everything else (FDC, custom, no
  /// barcode), just touches the cache timestamp so the entry doesn't
  /// age out of the 90-day TTL window.
  Future<void> _refreshCacheForSelectedMeal(MealEntity meal) async {
    final code = meal.code;
    if (code == null || code.isEmpty) return;

    if (meal.source != MealSourceEntity.off) {
      await _remoteSearchCacheDataSource.touch(code);
      return;
    }
    final MealEntity fresh;
    try {
      // The logged name stands in where OFF has none in the app's
      // language, so the cache and a favourite keep it (#1475).
      fresh = await _productsRepository.getOFFProductByBarcode(
        code,
        knownName: meal.name,
      );
      await _remoteSearchCacheDataSource.cache(MealDBO.fromMealEntity(fresh));
    } catch (e, st) {
      log.warning(
        'Background OFF refresh failed for $code; touching cache instead',
        e,
        st,
      );
      await _remoteSearchCacheDataSource.touch(code);
      return;
    }
    // A favourite on the food would otherwise keep logging and exporting
    // the figures it was starred with, when the app has just fetched newer
    // ones — as the scanner's live lookup does.
    try {
      await _favourites?.refreshDetailedSnapshot(fresh);
    } catch (e, st) {
      log.warning('Could not refresh a favourite on $code', e, st);
    }
  }

  /// Undoes a half-written [addIntake]: the day's totals back to [before],
  /// then the intake itself. Inside the same lock as the write, so nothing
  /// else saw the half-written state.
  ///
  /// The totals are written back whole rather than subtracted step by step.
  /// The data source changes the cached day record before it saves, so a
  /// save that throws can leave the increment in memory, where the next
  /// save (a subtraction included) would persist it. Writing back the values
  /// read before the update does not depend on how far the update got.
  ///
  /// Best effort. A rollback that fails too is logged and left; the caller
  /// still gets the original error, which is the one that explains what
  /// happened.
  Future<void> _rollBackIntake(
    IntakeEntity intakeEntity,
    DateTime day,
    TrackedDayEntity? before,
    Object error,
    StackTrace stackTrace,
  ) async {
    log.warning(
      'Tracked-day update failed; rolling back the intake',
      error,
      stackTrace,
    );
    try {
      if (before != null) {
        await _addTrackedDayUsecase.reconcileDayTracked(
          day,
          before.caloriesTracked,
          before.carbsTracked ?? 0,
          before.fatTracked ?? 0,
          before.proteinTracked ?? 0,
        );
      }
      await _deleteIntakeUsecase?.deleteIntake(intakeEntity);
    } catch (e, st) {
      log.severe('Rolling back a failed intake save failed', e, st);
    }
  }

  /// Adds [intakeEntity] to the day's totals, handing [onBefore] the totals
  /// as they stood before anything was added. Creating the day's row comes
  /// first and is not undone: an empty row is what the day would have had
  /// anyway.
  Future<void> _updateTrackedDay(
    IntakeEntity intakeEntity,
    DateTime day, {
    required void Function(TrackedDayEntity totals) onBefore,
  }) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (!hasTrackedDay) {
      final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
      final totalCarbsGoal = await _getMacroGoalUsecase.getCarbsGoal(
        totalKcalGoal,
      );
      final totalFatGoal = await _getMacroGoalUsecase.getFatsGoal(
        totalKcalGoal,
      );
      final totalProteinGoal = await _getMacroGoalUsecase.getProteinsGoal(
        totalKcalGoal,
      );

      await _addTrackedDayUsecase.addNewTrackedDayIfAbsent(
        day,
        totalKcalGoal,
        totalCarbsGoal,
        totalFatGoal,
        totalProteinGoal,
      );
    }

    final totals = await _getTrackedDayUsecase.getTrackedDay(day);
    if (totals != null) onBefore(totals);

    await _addTrackedDayUsecase.addDayCaloriesTracked(
      day,
      intakeEntity.totalKcal,
    );
    await _addTrackedDayUsecase.addDayMacrosTracked(
      day,
      carbsTracked: intakeEntity.totalCarbsGram,
      fatTracked: intakeEntity.totalFatsGram,
      proteinTracked: intakeEntity.totalProteinsGram,
    );
  }
}

enum UnitDropdownItem {
  g,
  ml,
  gml,
  oz,
  flOz,
  serving;

  UnitDropdownItem fromString(String value) {
    switch (value) {
      case 'g':
        return UnitDropdownItem.g;
      case 'ml':
        return UnitDropdownItem.ml;
      case 'g/ml':
        return UnitDropdownItem.gml;
      case 'oz':
        return UnitDropdownItem.oz;
      case 'fl oz' || 'fl.oz':
        return UnitDropdownItem.flOz;
      case 'serving':
        return UnitDropdownItem.serving;
      default:
        return UnitDropdownItem.gml;
    }
  }

  @override
  String toString() {
    switch (this) {
      case UnitDropdownItem.g:
        return 'g';
      case UnitDropdownItem.ml:
        return 'ml';
      case UnitDropdownItem.gml:
        return 'g/ml';
      case UnitDropdownItem.oz:
        return 'oz';
      case UnitDropdownItem.flOz:
        return 'fl.oz';
      case UnitDropdownItem.serving:
        return 'serving';
    }
  }
}
