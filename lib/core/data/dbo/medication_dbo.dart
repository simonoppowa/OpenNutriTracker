import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/domain/entity/medication_entity.dart';

part 'medication_dbo.g.dart';

@HiveType(typeId: 35)
@JsonSerializable()
class MedicationDBO extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  DateTime day;
  @HiveField(2)
  String name;
  @HiveField(3)
  double amount;
  @HiveField(4)
  String unit; // 'mL', 'mg', 'mcg'
  @HiveField(5)
  bool taken;

  MedicationDBO({
    required this.id,
    required this.day,
    required this.name,
    required this.amount,
    required this.unit,
    required this.taken,
  });

  factory MedicationDBO.fromMedicationEntity(MedicationEntity entity) {
    return MedicationDBO(
      id: entity.id,
      day: entity.day,
      name: entity.name,
      amount: entity.amount,
      unit: entity.unit,
      taken: entity.taken,
    );
  }

  factory MedicationDBO.fromJson(Map<String, dynamic> json) =>
      _$MedicationDBOFromJson(json);

  Map<String, dynamic> toJson() => _$MedicationDBOToJson(this);
}
