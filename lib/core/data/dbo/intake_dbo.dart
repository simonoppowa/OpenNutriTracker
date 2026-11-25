import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/logged_time.dart';

part 'intake_dbo.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class IntakeDBO extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String unit;
  @HiveField(2)
  double amount;
  @HiveField(3)
  IntakeTypeDBO type;

  @HiveField(4)
  MealDBO meal;

  @HiveField(5)
  DateTime dateTime;

  /// The UTC offset, in minutes, of the zone [dateTime] was logged in
  /// (#1309); see [LoggedTime]. Null for entries stored before it was
  /// recorded, and for a UTC day label.
  ///
  /// Not exported: [toJson] writes [dateTime] as that zone's clock
  /// instead, which a restore reads back on the same day anywhere.
  @HiveField(6)
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? loggedUtcOffsetMinutes;

  IntakeDBO({
    required this.id,
    required this.unit,
    required this.amount,
    required this.type,
    required this.meal,
    required this.dateTime,
    this.loggedUtcOffsetMinutes,
  });

  /// [dateTime] on the clock of the zone it was logged in, as a local
  /// time: the day the Diary lists this entry on, wherever it is read.
  DateTime get loggedDateTime =>
      LoggedTime.localWallClock(dateTime, loggedUtcOffsetMinutes);

  /// The same clock for day keys, without a lookup of the current zone.
  DateTime get loggedWallClock =>
      LoggedTime.wallClock(dateTime, loggedUtcOffsetMinutes);

  factory IntakeDBO.fromIntakeEntity(IntakeEntity entity) {
    return IntakeDBO(
      id: entity.id,
      unit: entity.unit,
      amount: entity.amount,
      type: IntakeTypeDBO.fromIntakeTypeEntity(entity.type),
      meal: MealDBO.fromMealEntity(entity.meal),
      dateTime: entity.dateTime,
      loggedUtcOffsetMinutes: LoggedTime.offsetOf(entity.dateTime),
    );
  }

  factory IntakeDBO.fromJson(Map<String, dynamic> json) =>
      _$IntakeDBOFromJson(json);

  Map<String, dynamic> toJson() =>
      _$IntakeDBOToJson(this)..['dateTime'] = loggedDateTime.toIso8601String();
}
