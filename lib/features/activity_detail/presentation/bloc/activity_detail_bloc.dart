import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/calc/met_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';

part 'activity_detail_event.dart';

part 'activity_detail_state.dart';

class ActivityDetailBloc
    extends Bloc<ActivityDetailEvent, ActivityDetailState> {
  final GetUserUsecase _getUserUsecase;
  final AddUserActivityUsecase _addUserActivityUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;

  ActivityDetailBloc(
      this._getUserUsecase,
      this._addUserActivityUsecase,
      this._addTrackedDayUsecase,
      this._getKcalGoalUsecase,
      this._getMacroGoalUsecase)
      : super(ActivityDetailInitial()) {
    on<LoadActivityDetailEvent>((event, emit) async {
      emit(ActivityDetailLoadingState());
      const quantityDefault = 60.0;
      final user = await _getUserUsecase.getUserData();
      final totalBurnedKcal =
          getTotalKcalBurned(user, event.physicalActivity, quantityDefault);

      emit(ActivityDetailLoadedState(
          totalBurnedKcal, user, quantityDefault.toInt()));
    });
  }

  double getTotalKcalBurned(UserEntity user,
      PhysicalActivityEntity physicalActivity, double duration) {
    return METCalc.getTotalBurnedKcal(user, physicalActivity, duration);
  }

  void persistActivity(
      BuildContext context,
      String durationText,
      double totalKcalBurned,
      PhysicalActivityEntity activityEntity,
      DateTime day) async {
    final duration = double.parse(durationText);

    final userActivityEntity = UserActivityEntity(IdGenerator.getUniqueID(),
        duration, totalKcalBurned, day, activityEntity);

    await _addUserActivityUsecase.addUserActivity(userActivityEntity);
    _updateTrackedDay(day, totalKcalBurned);
  }

  void _updateTrackedDay(DateTime day, double caloriesBurned) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (!hasTrackedDay) {
      // If the tracked day does not exist, create a new one
      final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal(
          totalKcalActivitiesParam: 0); // Exclude persisted activities
      final totalCarbsGoal =
          await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
      final totalFatGoal =
          await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
      final totalProteinGoal =
          await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);

      await _addTrackedDayUsecase.addNewTrackedDay(
          day, totalKcalGoal, totalCarbsGoal, totalFatGoal, totalProteinGoal);
    }

    final carbsIncrease = MacroCalc.getTotalCarbsGoal(caloriesBurned);
    final fatIncrease = MacroCalc.getTotalFatsGoal(caloriesBurned);
    final proteinIncrease = MacroCalc.getTotalProteinsGoal(caloriesBurned);

    _addTrackedDayUsecase.increaseDayCalorieGoal(day, caloriesBurned);
    _addTrackedDayUsecase.increaseDayMacroGoals(day,
        carbsAmount: carbsIncrease,
        fatAmount: fatIncrease,
        proteinAmount: proteinIncrease);
  }
}
