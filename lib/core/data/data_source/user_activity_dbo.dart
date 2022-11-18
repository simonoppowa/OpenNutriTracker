import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';

part 'user_activity_dbo.g.dart';

@HiveType(typeId: 10)
class UserActivityDBO {
  @HiveField(0)
  final double duration;
  @HiveField(1)
  final double burnedKcal;
  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final PhysicalActivityDBO physicalActivityDBO;

  UserActivityDBO(
      this.duration, this.burnedKcal, this.date, this.physicalActivityDBO);

  factory UserActivityDBO.toUserActivityEntity(
      UserActivityEntity userActivityEntity) {
    return UserActivityDBO(
        userActivityEntity.duration,
        userActivityEntity.burnedKcal,
        userActivityEntity.date,
        PhysicalActivityDBO.fromPhysicalActivityEntity(
            userActivityEntity.physicalActivityEntity));
  }
}
