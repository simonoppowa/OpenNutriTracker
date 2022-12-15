import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/met_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';

part 'activity_detail_event.dart';

part 'activity_detail_state.dart';

class ActivityDetailBloc
    extends Bloc<ActivityDetailEvent, ActivityDetailState> {
  final _getUserUsecase = GetUserUsecase();
  final _addUserActivityUsecase = AddUserActivityUsecase();

  ActivityDetailBloc() : super(ActivityDetailInitial()) {
    on<LoadActivityDetailEvent>((event, emit) async {
      emit(ActivityDetailLoadingState());
      const quantityDefault = 60.0;
      final user = await _getUserUsecase.getUserData(event.context);
      final totalBurnedKcal =
          getTotalKcalBurned(user, event.physicalActivity, quantityDefault);

      emit(ActivityDetailLoadedState(
          totalBurnedKcal, user, quantityDefault.toInt()));
    });
  }

  double getTotalKcalBurned(UserEntity user,
      PhysicalActivityEntity physicalActivity, double duration) {
    return METCalc.getTotalBurnedKcal(user, physicalActivity, duration);
  }

  void persistActivity(BuildContext context, String durationText,
      double totalKcalBurned, PhysicalActivityEntity activityEntity) {
    final duration = double.parse(durationText);

    final userActivityEntity = UserActivityEntity(IdGenerator.getUniqueID(),
        duration, totalKcalBurned, DateTime.now(), activityEntity);

    _addUserActivityUsecase.addUserActivity(context, userActivityEntity);
  }
}
