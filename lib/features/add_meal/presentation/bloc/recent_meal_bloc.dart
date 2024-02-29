import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
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
        final recentIntake = await _getIntakeUsecase.getRecentIntake();
        final searchString = (event.searchString ?? "").toLowerCase();

        if (searchString.isEmpty) {
          emit(RecentMealLoadedState(
              recentMeals: recentIntake.map((intake) => intake.meal).toList()));
        } else {
          emit(RecentMealLoadedState(
              recentMeals: recentIntake
                  .where(matchesSearchString(searchString))
                  .map((intake) => intake.meal)
                  .toList()));
        }
      } catch (error) {
        log.severe(error);
        emit(RecentMealFailedState());
      }
    });
  }

  bool Function(IntakeEntity) matchesSearchString(String searchString) {
    return (intake) =>
    (intake.meal.name?.toLowerCase().contains(searchString) ?? false) ||
        (intake.meal.brands?.toLowerCase().contains(searchString) ?? false);
  }

}
