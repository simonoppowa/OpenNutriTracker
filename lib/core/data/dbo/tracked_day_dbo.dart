import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';

part 'tracked_day_dbo.g.dart';

@HiveType(typeId: 9)
@JsonSerializable()
class TrackedDayDBO extends HiveObject {
  @HiveField(0)
  DateTime day;
  @HiveField(1)
  double calorieGoal;
  @HiveField(2)
  double caloriesTracked;
  @HiveField(3)
  double? carbsGoal;
  @HiveField(4)
  double? carbsTracked;
  @HiveField(5)
  double? fatGoal;
  @HiveField(6)
  double? fatTracked;
  @HiveField(7)
  double? proteinGoal;
  @HiveField(8)
  double? proteinTracked;

  // #173: user-configurable per-nutrient goals for the three "extras"
  // people kept asking to plan against. Null means "use the default
  // reference value"; a non-null value means the user has set their own
  // target via Settings → Calculations.
  @HiveField(9)
  double? fibreGoal;
  @HiveField(10)
  double? satFatGoal;
  @HiveField(11)
  double? sugarsGoal;

  TrackedDayDBO({
    required this.day,
    required this.calorieGoal,
    required this.caloriesTracked,
    this.carbsGoal,
    this.carbsTracked,
    this.fatGoal,
    this.fatTracked,
    this.proteinGoal,
    this.proteinTracked,
    this.fibreGoal,
    this.satFatGoal,
    this.sugarsGoal,
  });

  factory TrackedDayDBO.fromTrackedDayEntity(TrackedDayEntity entity) {
    return TrackedDayDBO(
      day: entity.day,
      calorieGoal: entity.calorieGoal,
      caloriesTracked: entity.caloriesTracked,
      carbsGoal: entity.carbsGoal,
      carbsTracked: entity.carbsTracked,
      fatGoal: entity.fatGoal,
      fatTracked: entity.fatTracked,
      proteinGoal: entity.proteinGoal,
      proteinTracked: entity.proteinTracked,
      fibreGoal: entity.fibreGoal,
      satFatGoal: entity.satFatGoal,
      sugarsGoal: entity.sugarsGoal,
    );
  }

  factory TrackedDayDBO.fromJson(Map<String, dynamic> json) =>
      _$TrackedDayDBOFromJson(json);

  Map<String, dynamic> toJson() => _$TrackedDayDBOToJson(this);
}
