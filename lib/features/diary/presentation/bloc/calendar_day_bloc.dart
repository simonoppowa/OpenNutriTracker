import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';

part 'calendar_day_event.dart';

part 'calendar_day_state.dart';

class CalendarDayBloc extends Bloc<CalendarDayEvent, CalendarDayState> {
  final _getUserActivityUsecase = GetUserActivityUsecase();
  final _getIntakeUsecase = GetIntakeUsecase();

  CalendarDayBloc() : super(CalendarDayInitial()) {
    on<LoadCalendarDayEvent>((event, emit) async {
      emit(CalendarDayLoading());
      final userActivities = await _getUserActivityUsecase.getUserActivityByDay(
          event.context, event.day);

      final breakfastIntakeList = await _getIntakeUsecase
          .getBreakfastIntakeByDay(event.context, event.day);

      final lunchIntakeList =
          await _getIntakeUsecase.getLunchIntakeByDay(event.context, event.day);
      final dinnerIntakeList = await _getIntakeUsecase.getDinnerIntakeByDay(
          event.context, event.day);
      final snackIntakeList =
          await _getIntakeUsecase.getSnackIntakeByDay(event.context, event.day);

      emit(CalendarDayLoaded(
          event.trackedDayEntity,
          userActivities,
          breakfastIntakeList,
          lunchIntakeList,
          dinnerIntakeList,
          snackIntakeList));
    });
  }
}
