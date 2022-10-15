import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetIntakeUsecase getIntakeUsecase = GetIntakeUsecase();

  HomeBloc() : super(HomeInitial()) {
    on<LoadItemsEvent>((event, emit) async {
      emit(HomeLoadingState());

      final breakfastIntakeList =
          await getIntakeUsecase.getTodayBreakfastIntake(event.context);

      emit(HomeLoadedState(breakfastIntakeList: breakfastIntakeList));
    });
  }
}
