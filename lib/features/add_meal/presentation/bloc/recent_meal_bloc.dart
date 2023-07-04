import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'recent_meal_event.dart';

part 'recent_meal_state.dart';

class RecentMealBloc extends Bloc<RecentMealEvent, RecentMealState> {
  final log = Logger('RecentMealBloc');

  final GetIntakeUsecase _getIntakeUsecase;

  RecentMealBloc(this._getIntakeUsecase) : super(RecentMealInitial()) {
    on<LoadRecentMealEvent>((event, emit) async {
      emit(RecentMealLoadingState());

      try {
        final recentIntake =
            await _getIntakeUsecase.getRecentIntake();
        emit(RecentMealLoadedState(
            recentMeals:
                recentIntake.map((intake) => intake.meal).toList()));
      } catch (error) {
        log.severe(error);
        emit(RecentMealFailedState());
      }
    });
  }
}
