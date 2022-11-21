import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/tdee_calc.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final _getIntakeUsecase = GetIntakeUsecase();
  final _getUserActivityUsecase = GetUserActivityUsecase();
  final _getUserUsecase = GetUserUsecase();

  HomeBloc() : super(HomeInitial()) {
    on<LoadItemsEvent>((event, emit) async {
      emit(HomeLoadingState());

      final breakfastIntakeList =
          await _getIntakeUsecase.getTodayBreakfastIntake(event.context);
      final totalBreakfastKcal =
          breakfastIntakeList.map((intake) => intake.totalKcal).toList().sum;
      final lunchIntakeList =
          await _getIntakeUsecase.getTodayLunchIntake(event.context);
      final totalLunchKcal =
          lunchIntakeList.map((intake) => intake.totalKcal).toList().sum;
      final dinnerIntakeList =
          await _getIntakeUsecase.getTodayDinnerIntake(event.context);
      final totalDinnerKcal =
          dinnerIntakeList.map((intake) => intake.totalKcal).toList().sum;
      final snackIntakeList =
          await _getIntakeUsecase.getTodaySnackIntake(event.context);
      final totalSnackKcal =
          snackIntakeList.map((intake) => intake.totalKcal).toList().sum;
      final totalKcalIntake = totalBreakfastKcal +
          totalLunchKcal +
          totalDinnerKcal +
          totalSnackKcal;

      final userActivities =
          await _getUserActivityUsecase.getTodayUserActivity(event.context);
      final totalKcalActivities =
          userActivities.map((activity) => activity.burnedKcal).toList().sum;

      final user = await _getUserUsecase.getUserData(event.context);
      final totalKcalDaily = TDEECalc.getTDEEKcalIOM2006(user);
      final totalKcalLeft =
          totalKcalDaily - totalKcalIntake + totalKcalActivities;

      emit(HomeLoadedState(
          totalKcalDaily: totalKcalDaily,
          totalKcalLeft: totalKcalLeft,
          totalKcalSupplied: totalKcalIntake,
          totalKcalBurned: totalKcalActivities,
          breakfastIntakeList: breakfastIntakeList,
          lunchIntakeList: lunchIntakeList,
          dinnerIntakeList: dinnerIntakeList,
          snackIntakeList: snackIntakeList,
          userActivityList: userActivities));
    });
  }
}
