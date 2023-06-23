import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/physical_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';

class GetPhysicalActivityUsecase {
  final _physicalActivityRepository = PhysicalActivityRepository();

  Future<List<PhysicalActivityEntity>> getAllPhysicalActivities(
      BuildContext context) async {
    return await _physicalActivityRepository.getAllPhysicalActivities(context);
  }
}
