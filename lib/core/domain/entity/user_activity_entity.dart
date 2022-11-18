import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';

class UserActivityEntity {
  final double duration;
  final double burnedKcal;
  final DateTime date;

  final PhysicalActivityEntity physicalActivityEntity;

  UserActivityEntity(
      this.duration, this.burnedKcal, this.date, this.physicalActivityEntity);

  factory UserActivityEntity.fromUserActivityDBO(UserActivityDBO activityDBO) {
    return UserActivityEntity(
        activityDBO.duration,
        activityDBO.burnedKcal,
        activityDBO.date,
        PhysicalActivityEntity.fromPhysicalActivityDBO(
            activityDBO.physicalActivityDBO));
  }
}
