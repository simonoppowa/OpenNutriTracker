import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';

class PhysicalActivityFixtures {
  static const PhysicalActivityEntity moderateBicycling =
      PhysicalActivityEntity(
          "01015",
          "Bicycling, moderate speed",
          "Bicycling at a moderate speed on flat terrain",
          8.0,
          [],
          PhysicalActivityTypeEntity.bicycling);

  static const PhysicalActivityEntity lightDancing = PhysicalActivityEntity(
      "03015",
      "Dancing, light effort",
      "Dancing with light effort, e.g., slow ballroom dancing",
      4.0,
      [],
      PhysicalActivityTypeEntity.dancing);

  static const PhysicalActivityEntity vigorousRunning = PhysicalActivityEntity(
      "12150",
      "Running, vigorous effort",
      "Running at a fast pace",
      12.0,
      [],
      PhysicalActivityTypeEntity.running);
}
