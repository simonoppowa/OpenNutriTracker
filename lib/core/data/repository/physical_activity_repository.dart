import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/data_source/physical_activity_data_source.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';

class PhysicalActivityRepository {
  final PhysicalActivityDataSource physicalActivityDataSource =
      PhysicalActivityDataSource();

  Future<List<PhysicalActivityEntity>> getAllPhysicalActivities(
      BuildContext context) async {
    final physicalActivitiesDBOList =
        physicalActivityDataSource.getPhysicalActivityList(context);
    return physicalActivitiesDBOList
        .map((dbo) => PhysicalActivityEntity.fromPhysicalActivityDBO(dbo))
        .toList();
  }
}
