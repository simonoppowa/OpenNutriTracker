import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/bmi_calc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:provider/provider.dart';

part 'profile_event.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserUsecase _getUserUsecase;
  final AddUserUsecase _addUserUsecase;

  ProfileBloc(this._getUserUsecase, this._addUserUsecase)
      : super(ProfileInitial()) {
    on<LoadProfileEvent>((event, emit) async {
      emit(ProfileLoadingState());

      final user = await _getUserUsecase.getUserData();
      final userBMIValue = BMICalc.getBMI(user);
      final userBMIEntity = UserBMIEntity(
          bmiValue: userBMIValue,
          nutritionalStatus: BMICalc.getNutritionalStatus(userBMIValue));

      emit(ProfileLoadedState(userBMI: userBMIEntity, userEntity: user));
    });
  }

  void updateUser(BuildContext context, UserEntity userEntity) {
    _addUserUsecase.addUser(userEntity);

    // Refresh Profile
    add(LoadProfileEvent(context: context));
    // Refresh Home Page
    Provider.of<HomeBloc>(context, listen: false)
        .add(LoadItemsEvent(context: context));
    // Refresh Diary Page
    Provider.of<DiaryBloc>(context, listen: false)
        .add(LoadDiaryYearEvent(context));
  }
}
