import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/physical_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:provider/provider.dart';

class GetPhysicalActivityUsecase {
  List<PhysicalActivityEntity> getAllPhysicalActivities(BuildContext context) {
    final physicalActivityRepository =
        Provider.of<PhysicalActivityRepository>(context, listen: false);
    return physicalActivityRepository.getAllPhysicalActivities(context);
  }
}
