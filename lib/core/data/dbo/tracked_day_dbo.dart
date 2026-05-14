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

  // #173: user-configurable per-nutrient goals. Null means "use the
  // default reference value"; a non-null value means the user has set
  // their own target via Settings → Calculations.
  //
  // Unit convention (preserved across DBO / Entity / panel):
  //   fibreGoal, satFatGoal, sugarsGoal               — grams
  //   sodiumGoal, calciumGoal, ironGoal,
  //   potassiumGoal, magnesiumGoal, vitaminB12Goal    — milligrams
  //   vitaminDGoal                                    — micrograms
  // The diary panel renders each row in its own native unit, so storing
  // the goal in the same unit avoids any conversion math at read time.
  @HiveField(9)
  double? fibreGoal;
  @HiveField(10)
  double? satFatGoal;
  @HiveField(11)
  double? sugarsGoal;

  // Follow-up to #173: extend planning to the rest of the panel's
  // nutrients so every row the user sees can carry a personal target.
  // The three D / B12 / Mg fields are accepted on this branch but will
  // only render once #160's expansion follow-up rebases through and
  // adds those panel rows.
  @HiveField(12)
  double? sodiumGoal;
  @HiveField(13)
  double? calciumGoal;
  @HiveField(14)
  double? ironGoal;
  @HiveField(15)
  double? potassiumGoal;
  @HiveField(16)
  double? vitaminDGoal;
  @HiveField(17)
  double? vitaminB12Goal;
  @HiveField(18)
  double? magnesiumGoal;

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
    this.sodiumGoal,
    this.calciumGoal,
    this.ironGoal,
    this.potassiumGoal,
    this.vitaminDGoal,
    this.vitaminB12Goal,
    this.magnesiumGoal,
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
      sodiumGoal: entity.sodiumGoal,
      calciumGoal: entity.calciumGoal,
      ironGoal: entity.ironGoal,
      potassiumGoal: entity.potassiumGoal,
      vitaminDGoal: entity.vitaminDGoal,
      vitaminB12Goal: entity.vitaminB12Goal,
      magnesiumGoal: entity.magnesiumGoal,
    );
  }

  factory TrackedDayDBO.fromJson(Map<String, dynamic> json) =>
      _$TrackedDayDBOFromJson(json);

  Map<String, dynamic> toJson() => _$TrackedDayDBOToJson(this);
}
