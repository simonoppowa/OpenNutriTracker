import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_physical_activity_usecase.dart';

class ActivitiesBloc {
  final GetPhysicalActivityUsecase _getPhysicalActivityUsecase =
      GetPhysicalActivityUsecase();

  List<PhysicalActivityEntity> getPhysicalActivity(BuildContext context) {
    return _getPhysicalActivityUsecase.getAllPhysicalActivities(context);
  }
}
