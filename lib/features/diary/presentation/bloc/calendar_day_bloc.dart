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

  DateTime? _currentDay;

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
      DateTime day, Emitter<CalendarDayState> emit) async {
    final userActivities =
        await _getUserActivityUsecase.getUserActivityByDay(day);

    final breakfastIntakeList =
        await _getIntakeUsecase.getBreakfastIntakeByDay(day);

    final lunchIntakeList = await _getIntakeUsecase.getLunchIntakeByDay(day);
    final dinnerIntakeList = await _getIntakeUsecase.getDinnerIntakeByDay(day);
    final snackIntakeList = await _getIntakeUsecase.getSnackIntakeByDay(day);

    final trackedDayEntity = await _getTrackedDayUsecase.getTrackedDay(day);

    emit(CalendarDayLoaded(
        trackedDayEntity,
        userActivities,
        breakfastIntakeList,
        lunchIntakeList,
        dinnerIntakeList,
        snackIntakeList));
  }

  Future<void> deleteIntakeItem(
      BuildContext context, IntakeEntity intakeEntity, DateTime day) async {
    await _deleteIntakeUsecase.deleteIntake(intakeEntity);
    await _addTrackedDayUsecase.removeDayCaloriesTracked(
        day, intakeEntity.totalKcal);
    await _addTrackedDayUsecase.removeDayMacrosTracked(day,
        carbsTracked: intakeEntity.totalCarbsGram,
        fatTracked: intakeEntity.totalFatsGram,
        proteinTracked: intakeEntity.totalProteinsGram);
  }

  Future<void> deleteUserActivityItem(BuildContext context,
      UserActivityEntity activityEntity, DateTime day) async {
    await _deleteUserActivityUsecase.deleteUserActivity(activityEntity);
    _addTrackedDayUsecase.reduceDayCalorieGoal(day, activityEntity.burnedKcal);

    final carbsAmount = MacroCalc.getTotalCarbsGoal(activityEntity.burnedKcal);
    final fatAmount = MacroCalc.getTotalFatsGoal(activityEntity.burnedKcal);
    final proteinAmount =
        MacroCalc.getTotalProteinsGoal(activityEntity.burnedKcal);

    _addTrackedDayUsecase.reduceDayMacroGoals(day,
        carbsAmount: carbsAmount,
        fatAmount: fatAmount,
        proteinAmount: proteinAmount);
    _updateDiaryPage(day);
  }

  Future<void> _updateDiaryPage(DateTime day) async {
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(LoadCalendarDayEvent(day));
  }
}
