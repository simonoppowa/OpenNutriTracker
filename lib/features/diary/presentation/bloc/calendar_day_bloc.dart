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
  final GetUserActivityUsecase _getUserActivityUsecase;
  final GetIntakeUsecase _getIntakeUsecase;
  final DeleteIntakeUsecase _deleteIntakeUsecase;
  final DeleteUserActivityUsecase _deleteUserActivityUsecase;
  final GetTrackedDayUsecase _getTrackedDayUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;

  CalendarDayBloc(
      this._getUserActivityUsecase,
      this._getIntakeUsecase,
      this._deleteIntakeUsecase,
      this._deleteUserActivityUsecase,
      this._getTrackedDayUsecase,
      this._addTrackedDayUsecase)
      : super(CalendarDayInitial()) {
    on<LoadCalendarDayEvent>((event, emit) async {
      emit(CalendarDayLoading());
      final userActivities =
          await _getUserActivityUsecase.getUserActivityByDay(event.day);

      final breakfastIntakeList =
          await _getIntakeUsecase.getBreakfastIntakeByDay(event.day);

      final lunchIntakeList =
          await _getIntakeUsecase.getLunchIntakeByDay(event.day);
      final dinnerIntakeList =
          await _getIntakeUsecase.getDinnerIntakeByDay(event.day);
      final snackIntakeList =
          await _getIntakeUsecase.getSnackIntakeByDay(event.day);

      final trackedDayEntity =
          await _getTrackedDayUsecase.getTrackedDay(event.day);

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
    await _deleteIntakeUsecase.deleteIntake(intakeEntity);
    await _addTrackedDayUsecase.removeDayCaloriesTracked(
        day, intakeEntity.totalKcal);
  }

  Future<void> deleteUserActivityItem(BuildContext context,
      UserActivityEntity activityEntity, DateTime day) async {
    await _deleteUserActivityUsecase.deleteUserActivity(
        activityEntity);
    await _addTrackedDayUsecase.addDayCaloriesTracked(
        day, activityEntity.burnedKcal);
    _addTrackedDayUsecase.reduceDayCalorieGoal(day, activityEntity.burnedKcal);
  }
}
