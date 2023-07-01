import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/tdee_calc.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_data_mask_entity.dart';

part 'onboarding_event.dart';

part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final userSelection = UserDataSelectionEntity();
  final AddUserUsecase _addUserUsecase;

  OnboardingBloc(this._addUserUsecase) : super(OnboardingInitialState()) {
    on<LoadOnboardingEvent>((event, emit) async {
      emit(OnboardingLoadingState());

      emit(OnboardingLoadedState());
    });
  }

  void addOnboardingUserData(
      BuildContext context, UserEntity userEntity) async {
    _addUserUsecase.addUser(context, userEntity);
  }

  double? getOverviewCalorieGoal() {
    final userEntity = userSelection.toUserEntity();
    double? calorieGoal;
    if (userEntity != null) {
      calorieGoal = TDEECalc.getTDEEKcalIOM2006(userEntity);
    }
    return calorieGoal;
  }
}
