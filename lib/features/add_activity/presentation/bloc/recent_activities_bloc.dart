import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';

part 'recent_activities_event.dart';

part 'recent_activities_state.dart';

class RecentActivitiesBloc
    extends Bloc<RecentActivitiesEvent, RecentActivitiesState> {
  final log = Logger('RecentActivitiesEvent');

  final GetUserActivityUsecase _getUserActivityUsecase;

  RecentActivitiesBloc(this._getUserActivityUsecase)
      : super(RecentActivitiesInitial()) {
    on<LoadRecentActivitiesEvent>((event, emit) async {
      emit(RecentActivitiesLoadingState());
      try {
        final recentUserActivities =
            await _getUserActivityUsecase.getRecentUserActivity();
        emit(RecentActivitiesLoadedState(
            recentActivities: recentUserActivities
                .map((activity) => activity.physicalActivityEntity)
                .toList()));
      } catch (error) {
        log.severe(error);
        emit(RecentActivitiesFailedState());
      }
    });
  }
}
