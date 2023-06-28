import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final _getConfigUsecase = GetConfigUsecase();
  final _addConfigUsecase = AddConfigUsecase();
  final _getIntakeUsecase = GetIntakeUsecase();
  final _deleteIntakeUsecase = DeleteIntakeUsecase();
  final _getUserActivityUsecase = GetUserActivityUsecase();
  final _deleteUserActivityUsecase = DeleteUserActivityUsecase();
  final _getUserUsecase = GetUserUsecase();
  final _addTrackedDayUseCase = AddTrackedDayUsecase();

  HomeBloc() : super(HomeInitial()) {
    on<LoadItemsEvent>((event, emit) async {
      emit(HomeLoadingState());

      final configData = await _getConfigUsecase.getConfig(event.context);
      final showDisclaimerDialog = !configData.hasAcceptedDisclaimer;

      final breakfastIntakeList =
          await _getIntakeUsecase.getTodayBreakfastIntake(event.context);
      final totalBreakfastKcal = getTotalKcal(breakfastIntakeList);
      final totalBreakfastCarbs = getTotalCarbs(breakfastIntakeList);
      final totalBreakfastFats = getTotalFats(breakfastIntakeList);
      final totalBreakfastProteins = getTotalProteins(breakfastIntakeList);

      final lunchIntakeList =
          await _getIntakeUsecase.getTodayLunchIntake(event.context);
      final totalLunchKcal = getTotalKcal(lunchIntakeList);
      final totalLunchCarbs = getTotalCarbs(lunchIntakeList);
      final totalLunchFats = getTotalFats(lunchIntakeList);
      final totalLunchProteins = getTotalProteins(lunchIntakeList);

      final dinnerIntakeList =
          await _getIntakeUsecase.getTodayDinnerIntake(event.context);
      final totalDinnerKcal = getTotalKcal(dinnerIntakeList);
      final totalDinnerCarbs = getTotalCarbs(dinnerIntakeList);
      final totalDinnerFats = getTotalFats(dinnerIntakeList);
      final totalDinnerProteins = getTotalProteins(dinnerIntakeList);

      final snackIntakeList =
          await _getIntakeUsecase.getTodaySnackIntake(event.context);
      final totalSnackKcal = getTotalKcal(snackIntakeList);
      final totalSnackCarbs = getTotalCarbs(snackIntakeList);
      final totalSnackFats = getTotalFats(snackIntakeList);
      final totalSnackProteins = getTotalProteins(snackIntakeList);

      final totalKcalIntake = totalBreakfastKcal +
          totalLunchKcal +
          totalDinnerKcal +
          totalSnackKcal;
      final totalCarbsIntake = totalBreakfastCarbs +
          totalLunchCarbs +
          totalDinnerCarbs +
          totalSnackCarbs;
      final totalFatsIntake = totalBreakfastFats +
          totalLunchFats +
          totalDinnerFats +
          totalSnackFats;
      final totalProteinsIntake = totalBreakfastProteins +
          totalLunchProteins +
          totalDinnerProteins +
          totalSnackProteins;

      final userActivities =
          await _getUserActivityUsecase.getTodayUserActivity(event.context);
      final totalKcalActivities =
          userActivities.map((activity) => activity.burnedKcal).toList().sum;

      final user = await _getUserUsecase.getUserData(event.context);
      final totalKcalGoal =
          CalorieGoalCalc.getTotalKcalGoal(user, totalKcalActivities);
      final totalCarbsGoal = MacroCalc.getTotalCarbsGoal(totalKcalGoal);
      final totalFatsGoal = MacroCalc.getTotalFatsGoal(totalKcalGoal);
      final totalProteinsGoal = MacroCalc.getTotalProteinsGoal(totalKcalGoal);

      final totalKcalLeft =
          CalorieGoalCalc.getDailyKcalLeft(totalKcalGoal, totalKcalIntake);

      emit(HomeLoadedState(
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
          userActivityList: userActivities));
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

  void saveConfigData(BuildContext context, bool acceptedDisclaimer) async {
    _addConfigUsecase.setConfigDisclaimer(context, acceptedDisclaimer);
  }

  Future<void> deleteIntakeItem(
      BuildContext context, IntakeEntity intakeEntity) async {
    final dateTime = DateTime.now();
    await _deleteIntakeUsecase.deleteIntake(context, intakeEntity);
    await _addTrackedDayUseCase.removeDayCaloriesTracked(
        context, dateTime, intakeEntity.totalKcal);
  }

  Future<void> deleteUserActivityItem(
      BuildContext context, UserActivityEntity activityEntity) async {
    final dateTime = DateTime.now();
    await _deleteUserActivityUsecase.deleteUserActivity(
        context, activityEntity);
    await _addTrackedDayUseCase.addDayCaloriesTracked(
        context, dateTime, activityEntity.burnedKcal);
    _addTrackedDayUseCase.reduceDayCalorieGoal(
        context, dateTime, activityEntity.burnedKcal);
  }
}
