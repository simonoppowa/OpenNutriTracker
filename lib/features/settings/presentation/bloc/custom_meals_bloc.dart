import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/merge_custom_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'custom_meals_event.dart';
part 'custom_meals_state.dart';

class CustomMealsBloc extends Bloc<CustomMealsEvent, CustomMealsState> {
  final log = Logger('CustomMealsBloc');

  final CustomMealDataSource _customMealDataSource;
  final GetIntakeUsecase _getIntakeUsecase;
  final DeleteIntakeUsecase _deleteIntakeUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final MergeCustomMealsUseCase _mergeCustomMealsUseCase;

  CustomMealsBloc(
    this._customMealDataSource,
    this._getIntakeUsecase,
    this._deleteIntakeUsecase,
    this._addTrackedDayUsecase,
    this._mergeCustomMealsUseCase,
  ) : super(CustomMealsInitial()) {
    on<LoadCustomMealsEvent>((event, emit) async {
      emit(CustomMealsLoadingState());
      try {
        final meals = _customMealDataSource
            .getAllCustomMeals()
            .map(MealEntity.fromMealDBO)
            .toList();
        emit(CustomMealsLoadedState(meals: meals));
      } catch (error) {
        log.severe(error);
        emit(CustomMealsFailedState());
      }
    });

    on<DeleteCustomMealEvent>((event, emit) async {
      emit(CustomMealsLoadingState());
      try {
        // Remove the template from the dedicated custom meal box.
        await _customMealDataSource.deleteCustomMeal(event.mealKey);

        // Cascade: remove all diary entries that used this custom meal.
        final allCustom = await _getIntakeUsecase.getCustomMealIntakes();
        final toDelete = allCustom
            .where((intake) => (intake.meal.code ?? intake.meal.name) == event.mealKey)
            .toList();
        for (final intake in toDelete) {
          await _deleteIntakeUsecase.deleteIntake(intake);
          await _addTrackedDayUsecase.removeDayCaloriesTracked(
            intake.dateTime,
            intake.totalKcal,
          );
          await _addTrackedDayUsecase.removeDayMacrosTracked(
            intake.dateTime,
            carbsTracked: intake.totalCarbsGram,
            fatTracked: intake.totalFatsGram,
            proteinTracked: intake.totalProteinsGram,
          );
        }
        add(LoadCustomMealsEvent());
      } catch (error) {
        log.severe(error);
        emit(CustomMealsFailedState());
      }
    });

    on<MergeCustomMealsEvent>((event, emit) async {
      emit(CustomMealsLoadingState());
      try {
        final result = await _mergeCustomMealsUseCase.merge(
          loserKey: event.loserKey,
          winnerKey: event.winnerKey,
        );
        final meals = _customMealDataSource
            .getAllCustomMeals()
            .map(MealEntity.fromMealDBO)
            .toList();
        emit(
          CustomMealsMergedState(
            meals: meals,
            rewrittenIntakeCount: result.rewrittenIntakeCount,
            winnerDisplayName: result.winnerDisplayName,
          ),
        );
      } catch (error) {
        log.severe(error);
        emit(CustomMealsFailedState());
      }
    });
  }
}
