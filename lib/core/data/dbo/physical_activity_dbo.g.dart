// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_activity_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PhysicalActivityDBOAdapter extends TypeAdapter<PhysicalActivityDBO> {
  @override
  final int typeId = 11;

  @override
  PhysicalActivityDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhysicalActivityDBO(
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
      fields[4] as double,
      (fields[5] as List).cast<String>(),
      fields[6] as PhysicalActivityTypeDBO,
    );
  }

  @override
  void write(BinaryWriter writer, PhysicalActivityDBO obj) {
    writer
      ..writeByte(6)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.specificActivity)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.mets)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhysicalActivityDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PhysicalActivityTypeDBOAdapter
    extends TypeAdapter<PhysicalActivityTypeDBO> {
  @override
  final int typeId = 12;

  @override
  PhysicalActivityTypeDBO read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 1:
        return PhysicalActivityTypeDBO.bicycling;
      case 2:
        return PhysicalActivityTypeDBO.conditioningExercise;
      case 3:
        return PhysicalActivityTypeDBO.dancing;
      case 4:
        return PhysicalActivityTypeDBO.running;
      case 5:
        return PhysicalActivityTypeDBO.sport;
      case 6:
        return PhysicalActivityTypeDBO.waterActivities;
      case 7:
        return PhysicalActivityTypeDBO.winterActivities;
      default:
        return PhysicalActivityTypeDBO.bicycling;
    }
  }

  @override
  void write(BinaryWriter writer, PhysicalActivityTypeDBO obj) {
    switch (obj) {
      case PhysicalActivityTypeDBO.bicycling:
        writer.writeByte(1);
        break;
      case PhysicalActivityTypeDBO.conditioningExercise:
        writer.writeByte(2);
        break;
      case PhysicalActivityTypeDBO.dancing:
        writer.writeByte(3);
        break;
      case PhysicalActivityTypeDBO.running:
        writer.writeByte(4);
        break;
      case PhysicalActivityTypeDBO.sport:
        writer.writeByte(5);
        break;
      case PhysicalActivityTypeDBO.waterActivities:
        writer.writeByte(6);
        break;
      case PhysicalActivityTypeDBO.winterActivities:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhysicalActivityTypeDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhysicalActivityDBO _$PhysicalActivityDBOFromJson(Map<String, dynamic> json) =>
    PhysicalActivityDBO(
      json['code'] as String,
      json['specificActivity'] as String,
      json['description'] as String,
      (json['mets'] as num).toDouble(),
      (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      $enumDecode(_$PhysicalActivityTypeDBOEnumMap, json['type']),
    );

Map<String, dynamic> _$PhysicalActivityDBOToJson(
        PhysicalActivityDBO instance) =>
    <String, dynamic>{
      'code': instance.code,
      'specificActivity': instance.specificActivity,
      'description': instance.description,
      'mets': instance.mets,
      'tags': instance.tags,
      'type': _$PhysicalActivityTypeDBOEnumMap[instance.type]!,
    };

const _$PhysicalActivityTypeDBOEnumMap = {
  PhysicalActivityTypeDBO.bicycling: 'bicycling',
  PhysicalActivityTypeDBO.conditioningExercise: 'conditioningExercise',
  PhysicalActivityTypeDBO.dancing: 'dancing',
  PhysicalActivityTypeDBO.running: 'running',
  PhysicalActivityTypeDBO.sport: 'sport',
  PhysicalActivityTypeDBO.waterActivities: 'waterActivities',
  PhysicalActivityTypeDBO.winterActivities: 'winterActivities',
};
