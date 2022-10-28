import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetIntakeUsecase getIntakeUsecase = GetIntakeUsecase();
  final GetUserUsecase getUserUsecase = GetUserUsecase();

  HomeBloc() : super(HomeInitial()) {
    on<LoadItemsEvent>((event, emit) async {
      emit(HomeLoadingState());

      final user = await getUserUsecase.getUserData(event.context);
      final breakfastIntakeList =
          await getIntakeUsecase.getTodayBreakfastIntake(event.context);
      final totalBreakfastKcal =
          breakfastIntakeList.map((intake) => intake.totalKcal).toList().sum;
      final lunchIntakeList =
          await getIntakeUsecase.getTodayLunchIntake(event.context);
      final totalLunchKcal =
          lunchIntakeList.map((intake) => intake.totalKcal).toList().sum;
      final dinnerIntakeList =
          await getIntakeUsecase.getTodayDinnerIntake(event.context);
      final totalDinnerKcal =
          dinnerIntakeList.map((intake) => intake.totalKcal).toList().sum;
      final snackIntakeList =
          await getIntakeUsecase.getTodaySnackIntake(event.context);
      final totalSnackKcal =
          snackIntakeList.map((intake) => intake.totalKcal).toList().sum;
      final totalKcalIntake = totalBreakfastKcal +
          totalLunchKcal +
          totalDinnerKcal +
          totalSnackKcal;

      emit(HomeLoadedState(
          totalKcalSupplied: totalKcalIntake,
          breakfastIntakeList: breakfastIntakeList,
          lunchIntakeList: lunchIntakeList,
          dinnerIntakeList: dinnerIntakeList,
          snackIntakeList: snackIntakeList));
    });
  }
}
