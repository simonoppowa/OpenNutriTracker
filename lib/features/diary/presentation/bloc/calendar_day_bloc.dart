import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';

part 'calendar_day_event.dart';

part 'calendar_day_state.dart';

class CalendarDayBloc extends Bloc<CalendarDayEvent, CalendarDayState> {
  final GetUserActivityUsecase _getUserActivityUsecase;
  final GetIntakeUsecase _getIntakeUsecase;
  final DeleteIntakeUsecase _deleteIntakeUsecase;
  final DeleteUserActivityUsecase _deleteUserActivityUsecase;
  final GetTrackedDayUsecase _getTrackedDayUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final UpdateIntakeUsecase _updateIntakeUsecase;
  final UpdateUserActivityUsecase _updateUserActivityUsecase;
  final GetConfigUsecase _getConfigUsecase;
  final AddConfigUsecase _addConfigUsecase;

  DateTime? _currentDay;

  CalendarDayBloc(
    this._getUserActivityUsecase,
    this._getIntakeUsecase,
    this._deleteIntakeUsecase,
    this._deleteUserActivityUsecase,
    this._getTrackedDayUsecase,
    this._addTrackedDayUsecase,
    this._updateIntakeUsecase,
    this._updateUserActivityUsecase,
    this._getConfigUsecase,
    this._addConfigUsecase,
  ) : super(CalendarDayInitial()) {
    on<LoadCalendarDayEvent>((event, emit) async {
      emit(CalendarDayLoading());
      _currentDay = event.day;
      await _loadCalendarDay(event.day, emit);
    });

    on<RefreshCalendarDayEvent>((event, emit) async {
      if (_currentDay != null) {
        emit(CalendarDayLoading());
        await _loadCalendarDay(_currentDay!, emit);
      }
    });
  }

  Future<void> _loadCalendarDay(
    DateTime day,
    Emitter<CalendarDayState> emit,
  ) async {
    // #139: when the user has a configured day-start offset, the
    // intake/activity queries need to know about it so entries logged
    // before the boundary roll into the previous day's column. The
    // follow-up to #139 adds a minutes companion that travels alongside
    // the hours value through the same call chain.
    final config = await _getConfigUsecase.getConfig();
    final dayStartOffsetHours = config.dayStartOffsetHours;
    final dayStartOffsetMinutes = config.dayStartOffsetMinutes;

    final userActivities = await _getUserActivityUsecase.getUserActivityByDay(
      day,
      dayStartOffsetHours: dayStartOffsetHours,
      dayStartOffsetMinutes: dayStartOffsetMinutes,
    );

    final breakfastIntakeList = await _getIntakeUsecase.getBreakfastIntakeByDay(
      day,
      dayStartOffsetHours: dayStartOffsetHours,
      dayStartOffsetMinutes: dayStartOffsetMinutes,
    );

    final lunchIntakeList = await _getIntakeUsecase.getLunchIntakeByDay(
      day,
      dayStartOffsetHours: dayStartOffsetHours,
      dayStartOffsetMinutes: dayStartOffsetMinutes,
    );
    final dinnerIntakeList = await _getIntakeUsecase.getDinnerIntakeByDay(
      day,
      dayStartOffsetHours: dayStartOffsetHours,
      dayStartOffsetMinutes: dayStartOffsetMinutes,
    );
    final snackIntakeList = await _getIntakeUsecase.getSnackIntakeByDay(
      day,
      dayStartOffsetHours: dayStartOffsetHours,
      dayStartOffsetMinutes: dayStartOffsetMinutes,
    );

    final trackedDayEntity = await _getTrackedDayUsecase.getTrackedDay(day);
    final configData = await _getConfigUsecase.getConfig();

    // #150: only surface per-meal targets when this calendar day has a
    // tracked daily kcal goal — otherwise the share has nothing to divide
    // and "0 / 0 kcal" reads as broken rather than helpful.
    final dailyKcalGoal = trackedDayEntity?.calorieGoal ?? 0;
    final breakfastKcalTarget = dailyKcalGoal > 0
        ? configData.targetKcalForMeal(
            ConfigEntity.mealKeyBreakfast, dailyKcalGoal)
        : 0.0;
    final lunchKcalTarget = dailyKcalGoal > 0
        ? configData.targetKcalForMeal(ConfigEntity.mealKeyLunch, dailyKcalGoal)
        : 0.0;
    final dinnerKcalTarget = dailyKcalGoal > 0
        ? configData.targetKcalForMeal(
            ConfigEntity.mealKeyDinner, dailyKcalGoal)
        : 0.0;
    final snackKcalTarget = dailyKcalGoal > 0
        ? configData.targetKcalForMeal(ConfigEntity.mealKeySnack, dailyKcalGoal)
        : 0.0;

    emit(
      CalendarDayLoaded(
        trackedDayEntity,
        userActivities,
        breakfastIntakeList,
        lunchIntakeList,
        dinnerIntakeList,
        snackIntakeList,
        breakfastKcalTarget,
        lunchKcalTarget,
        dinnerKcalTarget,
        snackKcalTarget,
        configData.mealKcalSharesPct[ConfigEntity.mealKeyBreakfast] ?? 0,
        configData.mealKcalSharesPct[ConfigEntity.mealKeyLunch] ?? 0,
        configData.mealKcalSharesPct[ConfigEntity.mealKeyDinner] ?? 0,
        configData.mealKcalSharesPct[ConfigEntity.mealKeySnack] ?? 0,
        diarySortPreferences: config.diarySortPreferences,
      ),
    );
  }

  /// Persist the user's sort choice for a single meal section. The diary
  /// reads the updated map back on the next `LoadCalendarDayEvent` (which
  /// fires after the user navigates away and returns), so we don't need to
  /// re-emit here — the widget keeps its own optimistic copy in the
  /// meantime.
  Future<void> setDiarySortPreference(String mealKey, int sortIndex) async {
    await _addConfigUsecase.setDiarySortPreference(mealKey, sortIndex);
  }

  Future<void> deleteIntakeItem(
    BuildContext context,
    IntakeEntity intakeEntity,
    DateTime day,
  ) async {
    await _deleteIntakeUsecase.deleteIntake(intakeEntity);
    await _addTrackedDayUsecase.removeDayCaloriesTracked(
      day,
      intakeEntity.totalKcal,
    );
    await _addTrackedDayUsecase.removeDayMacrosTracked(
      day,
      carbsTracked: intakeEntity.totalCarbsGram,
      fatTracked: intakeEntity.totalFatsGram,
      proteinTracked: intakeEntity.totalProteinsGram,
    );
  }

  Future<void> updateIntakeItem(
    String intakeId,
    Map<String, dynamic> fields,
    DateTime day,
  ) async {
    final oldIntake = await _getIntakeUsecase.getIntakeById(intakeId);
    assert(oldIntake != null);
    final newIntake = await _updateIntakeUsecase.updateIntake(intakeId, fields);
    assert(newIntake != null);
    if (oldIntake!.amount > newIntake!.amount) {
      await _addTrackedDayUsecase.removeDayCaloriesTracked(
        day,
        oldIntake.totalKcal - newIntake.totalKcal,
      );
      await _addTrackedDayUsecase.removeDayMacrosTracked(
        day,
        carbsTracked: oldIntake.totalCarbsGram - newIntake.totalCarbsGram,
        fatTracked: oldIntake.totalFatsGram - newIntake.totalFatsGram,
        proteinTracked: oldIntake.totalProteinsGram - newIntake.totalProteinsGram,
      );
    } else if (newIntake.amount > oldIntake.amount) {
      await _addTrackedDayUsecase.addDayCaloriesTracked(
        day,
        newIntake.totalKcal - oldIntake.totalKcal,
      );
      await _addTrackedDayUsecase.addDayMacrosTracked(
        day,
        carbsTracked: newIntake.totalCarbsGram - oldIntake.totalCarbsGram,
        fatTracked: newIntake.totalFatsGram - oldIntake.totalFatsGram,
        proteinTracked: newIntake.totalProteinsGram - oldIntake.totalProteinsGram,
      );
    }
  }

  Future<void> deleteUserActivityItem(
    BuildContext context,
    UserActivityEntity activityEntity,
    DateTime day,
  ) async {
    await _deleteUserActivityUsecase.deleteUserActivity(activityEntity);
    _addTrackedDayUsecase.reduceDayCalorieGoal(day, activityEntity.burnedKcal);

    final carbsAmount = MacroCalc.getTotalCarbsGoal(activityEntity.burnedKcal);
    final fatAmount = MacroCalc.getTotalFatsGoal(activityEntity.burnedKcal);
    final proteinAmount = MacroCalc.getTotalProteinsGoal(
      activityEntity.burnedKcal,
    );

    _addTrackedDayUsecase.reduceDayMacroGoals(
      day,
      carbsAmount: carbsAmount,
      fatAmount: fatAmount,
      proteinAmount: proteinAmount,
    );
    _updateDiaryPage(day);
  }

  Future<void> updateUserActivityItem(
    UserActivityEntity activityEntity,
    double newDuration,
    DateTime day,
  ) async {
    final newActivity = await _updateUserActivityUsecase.updateUserActivity(
      activityEntity,
      newDuration,
    );
    assert(newActivity != null);
    final kcalDiff = newActivity!.burnedKcal - activityEntity.burnedKcal;
    if (kcalDiff > 0) {
      await _addTrackedDayUsecase.increaseDayCalorieGoal(day, kcalDiff);
      await _addTrackedDayUsecase.increaseDayMacroGoals(
        day,
        carbsAmount: MacroCalc.getTotalCarbsGoal(kcalDiff),
        fatAmount: MacroCalc.getTotalFatsGoal(kcalDiff),
        proteinAmount: MacroCalc.getTotalProteinsGoal(kcalDiff),
      );
    } else if (kcalDiff < 0) {
      await _addTrackedDayUsecase.reduceDayCalorieGoal(day, kcalDiff.abs());
      await _addTrackedDayUsecase.reduceDayMacroGoals(
        day,
        carbsAmount: MacroCalc.getTotalCarbsGoal(kcalDiff.abs()),
        fatAmount: MacroCalc.getTotalFatsGoal(kcalDiff.abs()),
        proteinAmount: MacroCalc.getTotalProteinsGoal(kcalDiff.abs()),
      );
    }
  }

  Future<void> _updateDiaryPage(DateTime day) async {
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(LoadCalendarDayEvent(day));
  }
}
