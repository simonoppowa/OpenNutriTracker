import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_data_mask_entity.dart';

part 'onboarding_event.dart';

part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final userSelection = UserDataMaskEntity();
  final AddUserUsecase _addUserUsecase;
  final AddConfigUsecase _addConfigUsecase;

  OnboardingBloc(this._addUserUsecase, this._addConfigUsecase)
      : super(OnboardingInitialState()) {
    on<LoadOnboardingEvent>((event, emit) async {
      emit(OnboardingLoadingState());

      emit(OnboardingLoadedState());
    });
  }

  void saveOnboardingData(BuildContext context, UserEntity userEntity,
      bool hasAcceptedDataCollection) async {
    _addUserUsecase.addUser(userEntity);
    _addConfigUsecase
        .setConfigHasAcceptedAnonymousData(hasAcceptedDataCollection);
  }

  double? getOverviewCalorieGoal() {
    final userEntity = userSelection.toUserEntity();
    double? calorieGoal;
    if (userEntity != null) {
      calorieGoal = CalorieGoalCalc.getTotalKcalGoal(userEntity, 0);
    }
    return calorieGoal;
  }

  double? getOverviewCarbsGoal() {
    final userEntity = userSelection.toUserEntity();
    final calorieGoal = getOverviewCalorieGoal();
    double? carbsGoal;
    if (userEntity != null && calorieGoal != null) {
      carbsGoal = MacroCalc.getTotalCarbsGoal(calorieGoal);
    }
    return carbsGoal;
  }

  double? getOverviewFatGoal() {
    final userEntity = userSelection.toUserEntity();
    final calorieGoal = getOverviewCalorieGoal();
    double? fatGoal;
    if (userEntity != null && calorieGoal != null) {
      fatGoal = MacroCalc.getTotalFatsGoal(calorieGoal);
    }
    return fatGoal;
  }

  double? getOverviewProteinGoal() {
    final userEntity = userSelection.toUserEntity();
    final calorieGoal = getOverviewCalorieGoal();
    double? proteinGoal;
    if (userEntity != null && calorieGoal != null) {
      proteinGoal = MacroCalc.getTotalProteinsGoal(calorieGoal);
    }
    return proteinGoal;
  }
}
