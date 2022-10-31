import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/bmi_calc.dart';

part 'profile_event.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserUsecase getUserUsecase = GetUserUsecase();

  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfileEvent>((event, emit) async {
      emit(ProfileLoadingState());

      final user = await getUserUsecase.getUserData(event.context);
      final userBMI = BMICalc.getBMI(user);

      emit(ProfileLoadedState(userBMI: userBMI, userEntity: user));
    });
  }
}
