import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_physical_activity_usecase.dart';

part 'activities_event.dart';

part 'activities_state.dart';

class ActivitiesBloc extends Bloc<ActivitiesEvent, ActivitiesState> {
  final log = Logger('ActivitiesBloc');

  final GetPhysicalActivityUsecase _getPhysicalActivityUsecase;

  List<PhysicalActivityEntity> physicalActivities = [];

  ActivitiesBloc(this._getPhysicalActivityUsecase)
      : super(ActivitiesInitial()) {
    on<LoadActivitiesEvent>((event, emit) async {
      emit(ActivitiesLoadingState());
      try {
        physicalActivities =
            await _getPhysicalActivityUsecase.getAllPhysicalActivities();

        emit(ActivitiesLoadedState(activities: physicalActivities));
      } catch (error) {
        log.severe(error);
        emit(ActivitiesFailedState());
      }
    });
    on<SearchActivitiesEvent>((event, emit) async {
      emit(ActivitiesLoadingState());
      try {
        final query = event.searchString;
        List<PhysicalActivityEntity> activitySuggestions = [];
        if (query == "") {
          activitySuggestions = physicalActivities;
        } else {
          final formattedQuery = query.toLowerCase();
          activitySuggestions = physicalActivities.where((activity) {
            final formattedActivityName =
                activity.getName(event.context).toLowerCase();
            final formattedActivityDescription =
                activity.getDescription(event.context).toLowerCase();
            final containsQuery =
                formattedActivityName.contains(formattedQuery) ||
                    formattedActivityDescription.contains(formattedQuery);

            return containsQuery;
          }).toList();
        }
        emit(ActivitiesLoadedState(activities: activitySuggestions));
      } catch (error) {
        log.severe(error);
        emit(ActivitiesFailedState());
      }
    });
  }
}
