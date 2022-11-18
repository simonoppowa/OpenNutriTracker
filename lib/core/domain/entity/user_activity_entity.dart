import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';

class UserActivityEntity {
  final double duration;
  final double burnedKcal;
  final DateTime date;

  final PhysicalActivityEntity physicalActivityEntity;

  UserActivityEntity(this.duration, this.burnedKcal, this.date, this.physicalActivityEntity);
}
