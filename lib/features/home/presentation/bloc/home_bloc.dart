import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetConfigUsecase _getConfigUsecase;
  final AddConfigUsecase _addConfigUsecase;
  final GetIntakeUsecase _getIntakeUsecase;
  final DeleteIntakeUsecase _deleteIntakeUsecase;
  final UpdateIntakeUsecase _updateIntakeUsecase;
  final GetUserActivityUsecase _getUserActivityUsecase;
  final DeleteUserActivityUsecase _deleteUserActivityUsecase;
  final AddTrackedDayUsecase _addTrackedDayUseCase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final UpdateUserActivityUsecase _updateUserActivityUsecase;
  final GetUserUsecase _getUserUsecase;
  final GetWaterIntakeUsecase _getWaterIntakeUsecase;
  final AddWaterIntakeUsecase _addWaterIntakeUsecase;
  final DeleteWaterIntakeUsecase _deleteWaterIntakeUsecase;

  DateTime currentDay = DateTime.now();

  HomeBloc(
    this._getConfigUsecase,
    this._addConfigUsecase,
    this._getIntakeUsecase,
    this._deleteIntakeUsecase,
    this._updateIntakeUsecase,
    this._getUserActivityUsecase,
    this._deleteUserActivityUsecase,
    this._addTrackedDayUseCase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
    this._updateUserActivityUsecase,
    this._getUserUsecase,
    this._getWaterIntakeUsecase,
    this._addWaterIntakeUsecase,
    this._deleteWaterIntakeUsecase,
  ) : super(HomeInitial()) {
    on<LoadItemsEvent>((event, emit) async {
      emit(HomeLoadingState());

      final configData = await _getConfigUsecase.getConfig();
      final dayStartOffsetHours = configData.dayStartOffsetHours;
      final dayStartOffsetMinutes = configData.dayStartOffsetMinutes;
      // #139: the bloc's "current day" is the logical day, so day-change
      // detection on app resume respects the user's configured boundary.
      // The follow-up to #139 routes the boundary through total minutes
      // so a 04:30 setting is honoured exactly.
      currentDay = DayBoundaryCalc.currentLogicalDayMinutes(
        configData.dayStartOffsetTotalMinutes,
      );
      final usesImperialUnits = configData.usesImperialFoodUnits;
      final bodyWeightUnit = configData.bodyWeightUnit;
      final showDisclaimerDialog = !configData.hasAcceptedDisclaimer;
      final showMealMacros = configData.showMealMacros;
      final showActivityTracking = configData.showActivityTracking;

      final breakfastIntakeList = await _getIntakeUsecase
          .getTodayBreakfastIntake(
            dayStartOffsetHours: dayStartOffsetHours,
            dayStartOffsetMinutes: dayStartOffsetMinutes,
          );
      final totalBreakfastKcal = getTotalKcal(breakfastIntakeList);
      final totalBreakfastCarbs = getTotalCarbs(breakfastIntakeList);
      final totalBreakfastFats = getTotalFats(breakfastIntakeList);
      final totalBreakfastProteins = getTotalProteins(breakfastIntakeList);

      final lunchIntakeList = await _getIntakeUsecase.getTodayLunchIntake(
        dayStartOffsetHours: dayStartOffsetHours,
        dayStartOffsetMinutes: dayStartOffsetMinutes,
      );
      final totalLunchKcal = getTotalKcal(lunchIntakeList);
      final totalLunchCarbs = getTotalCarbs(lunchIntakeList);
      final totalLunchFats = getTotalFats(lunchIntakeList);
      final totalLunchProteins = getTotalProteins(lunchIntakeList);

      final dinnerIntakeList = await _getIntakeUsecase.getTodayDinnerIntake(
        dayStartOffsetHours: dayStartOffsetHours,
        dayStartOffsetMinutes: dayStartOffsetMinutes,
      );
      final totalDinnerKcal = getTotalKcal(dinnerIntakeList);
      final totalDinnerCarbs = getTotalCarbs(dinnerIntakeList);
      final totalDinnerFats = getTotalFats(dinnerIntakeList);
      final totalDinnerProteins = getTotalProteins(dinnerIntakeList);

      final snackIntakeList = await _getIntakeUsecase.getTodaySnackIntake(
        dayStartOffsetHours: dayStartOffsetHours,
        dayStartOffsetMinutes: dayStartOffsetMinutes,
      );
      final totalSnackKcal = getTotalKcal(snackIntakeList);
      final totalSnackCarbs = getTotalCarbs(snackIntakeList);
      final totalSnackFats = getTotalFats(snackIntakeList);
      final totalSnackProteins = getTotalProteins(snackIntakeList);

      final totalKcalIntake =
          totalBreakfastKcal +
          totalLunchKcal +
          totalDinnerKcal +
          totalSnackKcal;
      final totalCarbsIntake =
          totalBreakfastCarbs +
          totalLunchCarbs +
          totalDinnerCarbs +
          totalSnackCarbs;
      final totalFatsIntake =
          totalBreakfastFats +
          totalLunchFats +
          totalDinnerFats +
          totalSnackFats;
      final totalProteinsIntake =
          totalBreakfastProteins +
          totalLunchProteins +
          totalDinnerProteins +
          totalSnackProteins;

      final userActivities = await _getUserActivityUsecase.getTodayUserActivity(
        dayStartOffsetHours: dayStartOffsetHours,
        dayStartOffsetMinutes: dayStartOffsetMinutes,
      );
      final totalKcalActivities = userActivities
          .map((activity) => activity.burnedKcal)
          .toList()
          .sum;

      final waterIntakes = await _getWaterIntakeUsecase.getTodayEntries(
        dayStartOffsetTotalMinutes: configData.dayStartOffsetTotalMinutes,
      );
      final totalWaterMl = waterIntakes
          .map((entry) => entry.amountMl)
          .fold<int>(0, (sum, ml) => sum + ml);

      final user = await _getUserUsecase.getUserData();
      final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal(
        userEntity: user,
      );
      final totalCarbsGoal = await _getMacroGoalUsecase.getCarbsGoal(
        totalKcalGoal,
      );
      final totalFatsGoal = await _getMacroGoalUsecase.getFatsGoal(
        totalKcalGoal,
      );
      final totalProteinsGoal = await _getMacroGoalUsecase.getProteinsGoal(
        totalKcalGoal,
      );

      final totalKcalLeft = CalorieGoalCalc.getDailyKcalLeft(
        totalKcalGoal,
        totalKcalIntake,
      );

      // #150: derive recommended per-meal kcal targets from the saved share.
      final breakfastKcalTarget = configData.targetKcalForMeal(
        ConfigEntity.mealKeyBreakfast,
        totalKcalGoal,
      );
      final lunchKcalTarget = configData.targetKcalForMeal(
        ConfigEntity.mealKeyLunch,
        totalKcalGoal,
      );
      final dinnerKcalTarget = configData.targetKcalForMeal(
        ConfigEntity.mealKeyDinner,
        totalKcalGoal,
      );
      final snackKcalTarget = configData.targetKcalForMeal(
        ConfigEntity.mealKeySnack,
        totalKcalGoal,
      );

      emit(
        HomeLoadedState(
          showDisclaimerDialog: showDisclaimerDialog,
          totalKcalDaily: totalKcalGoal,
          totalKcalLeft: totalKcalLeft,
          totalKcalSupplied: totalKcalIntake,
          totalKcalBurned: totalKcalActivities,
          totalCarbsIntake: totalCarbsIntake,
          totalFatsIntake: totalFatsIntake,
          totalCarbsGoal: totalCarbsGoal,
          totalFatsGoal: totalFatsGoal,
          totalProteinsGoal: totalProteinsGoal,
          totalProteinsIntake: totalProteinsIntake,
          breakfastIntakeList: breakfastIntakeList,
          lunchIntakeList: lunchIntakeList,
          dinnerIntakeList: dinnerIntakeList,
          snackIntakeList: snackIntakeList,
          userActivityList: userActivities,
          usesImperialUnits: usesImperialUnits,
          bodyWeightUnit: bodyWeightUnit,
          showActivityTracking: showActivityTracking,
          showMealMacros: showMealMacros,
          userWeightKg: user.weightKG,
          breakfastKcalTarget: breakfastKcalTarget,
          lunchKcalTarget: lunchKcalTarget,
          dinnerKcalTarget: dinnerKcalTarget,
          snackKcalTarget: snackKcalTarget,
          breakfastSharePct:
              configData.mealKcalSharesPct[ConfigEntity.mealKeyBreakfast] ?? 0,
          lunchSharePct:
              configData.mealKcalSharesPct[ConfigEntity.mealKeyLunch] ?? 0,
          dinnerSharePct:
              configData.mealKcalSharesPct[ConfigEntity.mealKeyDinner] ?? 0,
          snackSharePct:
              configData.mealKcalSharesPct[ConfigEntity.mealKeySnack] ?? 0,
          userGender: user.gender,
          userCaloriesProfile: user.caloriesProfile,
          waterMlToday: totalWaterMl,
          waterGoalMl: configData.effectiveDailyWaterGoalMl(
            user.gender,
            caloriesProfile: user.caloriesProfile,
          ),
          waterIntakes: waterIntakes,
        ),
      );
    });
  }

  double getTotalKcal(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalKcal).toList().sum;

  double getTotalCarbs(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalCarbsGram).toList().sum;

  double getTotalFats(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalFatsGram).toList().sum;

  double getTotalProteins(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalProteinsGram).toList().sum;

  void saveConfigData(bool acceptedDisclaimer) async {
    _addConfigUsecase.setConfigDisclaimer(acceptedDisclaimer);
  }

  Future<void> updateIntakeItem(
    String intakeId,
    Map<String, dynamic> fields,
  ) async {
    final dateTime = await _currentLogicalDay();
    // Get old intake values
    final oldIntakeObject = await _getIntakeUsecase.getIntakeById(intakeId);
    if (oldIntakeObject == null) return;
    final newIntakeObject = await _updateIntakeUsecase.updateIntake(
      intakeId,
      fields,
    );
    if (newIntakeObject == null) return;
    if (oldIntakeObject.amount > newIntakeObject.amount) {
      // Amounts shrunk
      await _addTrackedDayUseCase.removeDayCaloriesTracked(
        dateTime,
        oldIntakeObject.totalKcal - newIntakeObject.totalKcal,
      );
      await _addTrackedDayUseCase.removeDayMacrosTracked(
        dateTime,
        carbsTracked:
            oldIntakeObject.totalCarbsGram - newIntakeObject.totalCarbsGram,
        fatTracked:
            oldIntakeObject.totalFatsGram - newIntakeObject.totalFatsGram,
        proteinTracked:
            oldIntakeObject.totalProteinsGram -
            newIntakeObject.totalProteinsGram,
      );
    } else if (newIntakeObject.amount > oldIntakeObject.amount) {
      // Amounts gained
      await _addTrackedDayUseCase.addDayCaloriesTracked(
        dateTime,
        newIntakeObject.totalKcal - oldIntakeObject.totalKcal,
      );
      await _addTrackedDayUseCase.addDayMacrosTracked(
        dateTime,
        carbsTracked:
            newIntakeObject.totalCarbsGram - oldIntakeObject.totalCarbsGram,
        fatTracked:
            newIntakeObject.totalFatsGram - oldIntakeObject.totalFatsGram,
        proteinTracked:
            newIntakeObject.totalProteinsGram -
            oldIntakeObject.totalProteinsGram,
      );
    }
    _updateDiaryPage(dateTime);
  }

  Future<void> deleteIntakeItem(IntakeEntity intakeEntity) async {
    final dateTime = await _currentLogicalDay();
    await _deleteIntakeUsecase.deleteIntake(intakeEntity);
    await _addTrackedDayUseCase.removeDayCaloriesTracked(
      dateTime,
      intakeEntity.totalKcal,
    );
    await _addTrackedDayUseCase.removeDayMacrosTracked(
      dateTime,
      carbsTracked: intakeEntity.totalCarbsGram,
      fatTracked: intakeEntity.totalFatsGram,
      proteinTracked: intakeEntity.totalProteinsGram,
    );

    _updateDiaryPage(dateTime);
  }

  Future<void> deleteUserActivityItem(UserActivityEntity activityEntity) async {
    final dateTime = await _currentLogicalDay();
    await _deleteUserActivityUsecase.deleteUserActivity(activityEntity);
    _addTrackedDayUseCase.reduceDayCalorieGoal(
      dateTime,
      activityEntity.burnedKcal,
    );

    final carbsAmount = MacroCalc.getTotalCarbsGoal(activityEntity.burnedKcal);
    final fatAmount = MacroCalc.getTotalFatsGoal(activityEntity.burnedKcal);
    final proteinAmount = MacroCalc.getTotalProteinsGoal(
      activityEntity.burnedKcal,
    );

    _addTrackedDayUseCase.reduceDayMacroGoals(
      dateTime,
      carbsAmount: carbsAmount,
      fatAmount: fatAmount,
      proteinAmount: proteinAmount,
    );
    _updateDiaryPage(dateTime);
    add(
      const LoadItemsEvent(),
    ); // #208: Reload home page to remove activity indicator
  }

  Future<void> updateUserActivityItem(
    UserActivityEntity activityEntity,
    double newDuration,
  ) async {
    final dateTime = await _currentLogicalDay();
    final newActivity = await _updateUserActivityUsecase.updateUserActivity(
      activityEntity,
      newDuration,
    );
    assert(newActivity != null);
    final kcalDiff = newActivity!.burnedKcal - activityEntity.burnedKcal;
    if (kcalDiff > 0) {
      _addTrackedDayUseCase.increaseDayCalorieGoal(dateTime, kcalDiff);
      _addTrackedDayUseCase.increaseDayMacroGoals(
        dateTime,
        carbsAmount: MacroCalc.getTotalCarbsGoal(kcalDiff),
        fatAmount: MacroCalc.getTotalFatsGoal(kcalDiff),
        proteinAmount: MacroCalc.getTotalProteinsGoal(kcalDiff),
      );
    } else if (kcalDiff < 0) {
      _addTrackedDayUseCase.reduceDayCalorieGoal(dateTime, kcalDiff.abs());
      _addTrackedDayUseCase.reduceDayMacroGoals(
        dateTime,
        carbsAmount: MacroCalc.getTotalCarbsGoal(kcalDiff.abs()),
        fatAmount: MacroCalc.getTotalFatsGoal(kcalDiff.abs()),
        proteinAmount: MacroCalc.getTotalProteinsGoal(kcalDiff.abs()),
      );
    }
    _updateDiaryPage(dateTime);
  }

  Future<void> _updateDiaryPage(DateTime day) async {
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  }

  /// Logs a single water intake entry and reloads the home view so the
  /// chip updates immediately. The dialog itself only owns the slider
  /// value; persistence and recomputation flow back through the bloc.
  Future<void> addWaterIntake(int amountMl) async {
    if (amountMl <= 0) return;
    final entry = WaterIntakeEntity(
      id: 'water-${DateTime.now().microsecondsSinceEpoch}',
      dateTime: DateTime.now(),
      amountMl: amountMl,
    );
    await _addWaterIntakeUsecase.addEntry(entry);
    add(const LoadItemsEvent());
  }

  /// Rolls back the most recent water entry for the configured logical
  /// day. Returns whether anything was deleted, so the dialog can react
  /// without re-reading state.
  Future<bool> undoLastWaterIntake() async {
    final config = await _getConfigUsecase.getConfig();
    final entries = await _getWaterIntakeUsecase.getTodayEntries(
      dayStartOffsetTotalMinutes: config.dayStartOffsetTotalMinutes,
    );
    if (entries.isEmpty) return false;
    entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _deleteWaterIntakeUsecase.deleteEntry(entries.last.id);
    add(const LoadItemsEvent());
    return true;
  }

  /// #139: tracked-day deltas (calories, macros) must land on the
  /// user's logical "today" — for someone on a 04:30 boundary, a 02:00
  /// edit still updates yesterday's totals. We resolve the offset on
  /// each call so the most recent setting wins without needing the
  /// bloc to cache it explicitly. The follow-up to #139 reads the
  /// total-minutes value so the minute component (0-59) is honoured.
  Future<DateTime> _currentLogicalDay() async {
    final config = await _getConfigUsecase.getConfig();
    return DayBoundaryCalc.currentLogicalDayMinutes(
      config.dayStartOffsetTotalMinutes,
    );
  }
}
