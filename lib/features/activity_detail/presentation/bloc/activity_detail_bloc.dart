import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/met_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';

part 'activity_detail_event.dart';

part 'activity_detail_state.dart';

class ActivityDetailBloc
    extends Bloc<ActivityDetailEvent, ActivityDetailState> {
  final _getUserUsecase = GetUserUsecase();
  final _addUserActivityUsecase = AddUserActivityUsecase();
  final _addTrackedDayUsecase = AddTrackedDayUsecase();

  ActivityDetailBloc() : super(ActivityDetailInitial()) {
    on<LoadActivityDetailEvent>((event, emit) async {
      emit(ActivityDetailLoadingState());
      const quantityDefault = 60.0;
      final user = await _getUserUsecase.getUserData(event.context);
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

  void persistActivity(BuildContext context, String durationText,
      double totalKcalBurned, PhysicalActivityEntity activityEntity) async {
    final duration = double.parse(durationText);
    final dateTime = DateTime.now();

    final userActivityEntity = UserActivityEntity(IdGenerator.getUniqueID(),
        duration, totalKcalBurned, dateTime, activityEntity);

    _addUserActivityUsecase.addUserActivity(context, userActivityEntity);
    _persistTrackedDay(context, dateTime, totalKcalBurned);
  }

  void _persistTrackedDay(
      BuildContext context, DateTime dateTime, double caloriesBurned) async {
    if (await _addTrackedDayUsecase.hasTrackedDay(context, dateTime)) {
      _addTrackedDayUsecase.removeDayCaloriesTracked(
          context, dateTime, caloriesBurned);
    } else {
      final userEntity = await _getUserUsecase.getUserData(context);
      final totalKcalGoal = CalorieGoalCalc.getTdee(userEntity);
      _addTrackedDayUsecase.addNewTrackedDay(context, dateTime, totalKcalGoal);
    }
  }
}
