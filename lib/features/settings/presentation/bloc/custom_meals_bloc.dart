import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/merge_custom_meals_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/other_profile_diaries_usecase.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
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
  final FavouriteMealRepository _favouriteMealRepository; // #1307
  final OtherProfileDiariesUsecase _otherProfileDiaries; // #1421

  CustomMealsBloc(
    this._customMealDataSource,
    this._getIntakeUsecase,
    this._deleteIntakeUsecase,
    this._addTrackedDayUsecase,
    this._mergeCustomMealsUseCase,
    this._favouriteMealRepository,
    this._otherProfileDiaries,
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
        final deleted = await withTrackedDayLockOnProfile(() async {
          // A starred meal stays on Favourites as its snapshot; bring that
          // up to the version being deleted first.
          await _favouriteMealRepository.keepLatestCustomMealSnapshot(
            event.mealKey,
          );

          // The library is shared, so the entries every profile logged
          // with the meal go with it (#1421). The meal leaves the library
          // last: a delete that fails part-way can be run again.
          await _deleteEntriesOf(
            event.mealKey,
            await _getIntakeUsecase.getCustomMealIntakes(),
            _deleteIntakeUsecase.deleteIntake,
            _addTrackedDayUsecase,
          );
          await _otherProfileDiaries.forEachLoggingCustomMeal(
            event.mealKey,
            (intakeRepository, addTrackedDayUsecase) async => _deleteEntriesOf(
              event.mealKey,
              await intakeRepository.getCustomMealIntakes(),
              intakeRepository.deleteIntake,
              addTrackedDayUsecase,
            ),
          );
          await _customMealDataSource.deleteCustomMeal(event.mealKey);
          return true;
        });
        if (deleted != true) return;
        add(LoadCustomMealsEvent());
      } catch (error) {
        log.severe(error);
        emit(CustomMealsFailedState());
      }
    });

    on<MergeCustomMealsEvent>((event, emit) async {
      emit(CustomMealsLoadingState());
      try {
        final result = await withTrackedDayLockOnProfile(
          () => _mergeCustomMealsUseCase
              .merge(loserKey: event.loserKey, winnerKey: event.winnerKey)
              .then((result) => result),
        );
        if (result == null) return;
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

  /// Deletes the entries in [customIntakes] logged as [mealKey] and takes
  /// them off their days' totals.
  static Future<void> _deleteEntriesOf(
    String mealKey,
    List<IntakeEntity> customIntakes,
    Future<void> Function(IntakeEntity intake) deleteIntake,
    AddTrackedDayUsecase addTrackedDayUsecase,
  ) async {
    final toDelete = customIntakes
        .where((intake) => (intake.meal.code ?? intake.meal.name) == mealKey)
        .toList();
    for (final intake in toDelete) {
      await deleteIntake(intake);
      await addTrackedDayUsecase.removeDayCaloriesTracked(
        intake.dateTime,
        intake.totalKcal,
      );
      await addTrackedDayUsecase.removeDayMacrosTracked(
        intake.dateTime,
        carbsTracked: intake.totalCarbsGram,
        fatTracked: intake.totalFatsGram,
        proteinTracked: intake.totalProteinsGram,
      );
    }
  }
}
