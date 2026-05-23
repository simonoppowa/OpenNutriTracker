import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
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

  MealDetailBloc(
    this._addIntakeUseCase,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
    this._getTrackedDayUsecase,
    this._productsRepository,
    this._remoteSearchCacheDataSource,
  ) : super(
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

        // Convert quantity based on selected unit
        double convertedQuantity = quantity;
        if (selectedUnit == UnitDropdownItem.serving.toString()) {
          // For serving size, multiply by the product's serving quantity
          if (event.meal.servingQuantity != null) {
            convertedQuantity = quantity * event.meal.servingQuantity!;
          }
        } else if (selectedUnit == UnitDropdownItem.oz.toString()) {
          convertedQuantity = UnitCalc.ozToG(quantity);
        } else if (selectedUnit == UnitDropdownItem.flOz.toString()) {
          convertedQuantity = UnitCalc.flOzToMl(quantity);
        }

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
  }

  void addIntake(
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
    await _addIntakeUseCase.addIntake(intakeEntity);
    _updateTrackedDay(intakeEntity, day);
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
    try {
      final fresh = await _productsRepository.getOFFProductByBarcode(code);
      await _remoteSearchCacheDataSource
          .cache(MealDBO.fromMealEntity(fresh));
    } catch (e, st) {
      log.warning(
        'Background OFF refresh failed for $code; touching cache instead',
        e,
        st,
      );
      await _remoteSearchCacheDataSource.touch(code);
    }
  }

  Future<void> _updateTrackedDay(
    IntakeEntity intakeEntity,
    DateTime day,
  ) async {
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

      await _addTrackedDayUsecase.addNewTrackedDay(
        day,
        totalKcalGoal,
        totalCarbsGoal,
        totalFatGoal,
        totalProteinGoal,
      );
    }

    _addTrackedDayUsecase.addDayCaloriesTracked(day, intakeEntity.totalKcal);
    _addTrackedDayUsecase.addDayMacrosTracked(
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
