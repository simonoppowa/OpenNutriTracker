import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';

part 'user_activity_dbo.g.dart';

@HiveType(typeId: 10)
@JsonSerializable()
class UserActivityDBO extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double duration;
  @HiveField(2)
  final double burnedKcal;
  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final PhysicalActivityDBO physicalActivityDBO;

  /// Direct kcal value entered by the user for a Custom-type activity.
  /// When non-null this takes precedence over the MET-computed value: the
  /// aggregation layer keeps reading [burnedKcal], which is set to match
  /// [userKcal] at save time so existing daily totals stay consistent.
  /// Older diary entries written before this field existed simply carry
  /// `null` here and behave exactly as they did before.
  @HiveField(5)
  final double? userKcal;

  /// Stable id of the platform record this activity was imported from
  /// (Health Connect / Apple Health). Doubles as the dedupe key: a record
  /// whose id is already present is never imported twice. Null for every
  /// manually logged activity, which is what old rows read as.
  @HiveField(6)
  final String? externalId;

  /// The energy the exporting app or device reported for an imported
  /// workout, before the user's calorie-credit multiplier was applied.
  /// Kept so the multiplier stays inspectable after the fact; [burnedKcal]
  /// remains the value the daily budget is computed from.
  @HiveField(7)
  final double? sourceReportedKcal;

  UserActivityDBO(
    this.id,
    this.duration,
    this.burnedKcal,
    this.date,
    this.physicalActivityDBO, {
    this.userKcal,
    this.externalId,
    this.sourceReportedKcal,
  });

  factory UserActivityDBO.fromUserActivityEntity(
    UserActivityEntity userActivityEntity,
  ) {
    return UserActivityDBO(
      userActivityEntity.id,
      userActivityEntity.duration,
      userActivityEntity.burnedKcal,
      userActivityEntity.date,
      PhysicalActivityDBO.fromPhysicalActivityEntity(
        userActivityEntity.physicalActivityEntity,
      ),
      userKcal: userActivityEntity.userKcal,
      externalId: userActivityEntity.externalId,
      sourceReportedKcal: userActivityEntity.sourceReportedKcal,
    );
  }

  factory UserActivityDBO.fromJson(Map<String, dynamic> json) =>
      _$UserActivityDBOFromJson(json);

  Map<String, dynamic> toJson() => _$UserActivityDBOToJson(this);
}
