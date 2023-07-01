import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';

part 'calendar_day_event.dart';

part 'calendar_day_state.dart';

class CalendarDayBloc extends Bloc<CalendarDayEvent, CalendarDayState> {
  final _getUserActivityUsecase = GetUserActivityUsecase();
  final GetIntakeUsecase _getIntakeUsecase;
  final _deleteIntakeUsecase = DeleteIntakeUsecase();
  final _deleteUserActivityUsecase = DeleteUserActivityUsecase();
  final _addTrackedDayUsecase = AddTrackedDayUsecase();
  final _getTrackedDayUsecase = GetTrackedDayUsecase();

  CalendarDayBloc(this._getIntakeUsecase) : super(CalendarDayInitial()) {
    on<LoadCalendarDayEvent>((event, emit) async {
      emit(CalendarDayLoading());
      final userActivities = await _getUserActivityUsecase.getUserActivityByDay(
          event.context, event.day);

      final breakfastIntakeList = await _getIntakeUsecase
          .getBreakfastIntakeByDay(event.day);

      final lunchIntakeList =
          await _getIntakeUsecase.getLunchIntakeByDay(event.day);
      final dinnerIntakeList = await _getIntakeUsecase.getDinnerIntakeByDay(
          event.day);
      final snackIntakeList =
          await _getIntakeUsecase.getSnackIntakeByDay(event.day);

      final trackedDayEntity =
          await _getTrackedDayUsecase.getTrackedDay(event.context, event.day);

      emit(CalendarDayLoaded(
          trackedDayEntity,
          userActivities,
          breakfastIntakeList,
          lunchIntakeList,
          dinnerIntakeList,
          snackIntakeList));
    });
  }

  Future<void> deleteIntakeItem(
      BuildContext context, IntakeEntity intakeEntity, DateTime day) async {
    await _deleteIntakeUsecase.deleteIntake(context, intakeEntity);
    await _addTrackedDayUsecase.removeDayCaloriesTracked(
        context, day, intakeEntity.totalKcal);
  }

  Future<void> deleteUserActivityItem(BuildContext context,
      UserActivityEntity activityEntity, DateTime day) async {
    await _deleteUserActivityUsecase.deleteUserActivity(
        context, activityEntity);
    await _addTrackedDayUsecase.addDayCaloriesTracked(
        context, day, activityEntity.burnedKcal);
    _addTrackedDayUsecase.reduceDayCalorieGoal(
        context, day, activityEntity.burnedKcal);
  }
}
