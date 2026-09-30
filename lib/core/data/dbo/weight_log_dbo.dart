import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';

part 'weight_log_dbo.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class WeightLogDBO extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  double weightKg;
  @HiveField(2)
  String? note;
  // Platform record id when the reading was imported from Health Connect /
  // Apple Health; null for a weight the user entered. The importer never
  // overwrites an entry without one.
  @HiveField(3)
  String? externalId;

  WeightLogDBO({
    required this.date,
    required this.weightKg,
    this.note,
    this.externalId,
  });

  factory WeightLogDBO.fromWeightLogEntity(WeightLogEntity entity) {
    return WeightLogDBO(
      date: entity.date,
      weightKg: entity.weightKg,
      note: entity.note,
      externalId: entity.externalId,
    );
  }

  factory WeightLogDBO.fromJson(Map<String, dynamic> json) =>
      _$WeightLogDBOFromJson(json);

  Map<String, dynamic> toJson() => _$WeightLogDBOToJson(this);
}
