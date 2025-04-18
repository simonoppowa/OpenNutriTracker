import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';

part 'physical_activity_dbo.g.dart';

/// A physical activity with it's measured MET value by the
/// '2011 Compendium of Physical Activities'
/// https://pubmed.ncbi.nlm.nih.gov/21681120/
/// by Ainsworth et al.
@HiveType(typeId: 11)
@JsonSerializable()
class PhysicalActivityDBO {
  @HiveField(1)
  final String code;
  @HiveField(2)
  final String specificActivity;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final double mets;

  @HiveField(5)
  final List<String> tags;

  @HiveField(6)
  final PhysicalActivityTypeDBO type;

  PhysicalActivityDBO(this.code, this.specificActivity, this.description,
      this.mets, this.tags, this.type);

  factory PhysicalActivityDBO.fromPhysicalActivityEntity(
      PhysicalActivityEntity entity) {
    return PhysicalActivityDBO(
        entity.code,
        entity.specificActivity,
        entity.description,
        entity.mets,
        entity.tags,
        PhysicalActivityTypeDBO.fromPhysicalActivityTypeEntity(entity.type));
  }

  factory PhysicalActivityDBO.fromJson(Map<String, dynamic> json) =>
      _$PhysicalActivityDBOFromJson(json);

  Map<String, dynamic> toJson() => _$PhysicalActivityDBOToJson(this);
}

@HiveType(typeId: 12)
enum PhysicalActivityTypeDBO {
  @HiveField(1)
  bicycling,
  @HiveField(2)
  conditioningExercise,
  @HiveField(3)
  dancing,
  @HiveField(4)
  running,
  @HiveField(5)
  sport,
  @HiveField(6)
  waterActivities,
  @HiveField(7)
  winterActivities;

  factory PhysicalActivityTypeDBO.fromPhysicalActivityTypeEntity(
      PhysicalActivityTypeEntity entityType) {
    PhysicalActivityTypeDBO typeDBO;
    switch (entityType) {
      case PhysicalActivityTypeEntity.bicycling:
        typeDBO = PhysicalActivityTypeDBO.bicycling;
        break;
      case PhysicalActivityTypeEntity.conditioningExercise:
        typeDBO = PhysicalActivityTypeDBO.conditioningExercise;
        break;
      case PhysicalActivityTypeEntity.dancing:
        typeDBO = PhysicalActivityTypeDBO.dancing;
        break;
      case PhysicalActivityTypeEntity.running:
        typeDBO = PhysicalActivityTypeDBO.running;
        break;
      case PhysicalActivityTypeEntity.sport:
        typeDBO = PhysicalActivityTypeDBO.sport;
        break;
      case PhysicalActivityTypeEntity.waterActivities:
        typeDBO = PhysicalActivityTypeDBO.waterActivities;
        break;
      case PhysicalActivityTypeEntity.winterActivities:
        typeDBO = PhysicalActivityTypeDBO.winterActivities;
        break;
    }
    return typeDBO;
  }
}
