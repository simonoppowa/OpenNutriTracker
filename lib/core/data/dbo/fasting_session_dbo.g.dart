// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fasting_session_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FastingSessionDBOAdapter extends TypeAdapter<FastingSessionDBO> {
  @override
  final typeId = 22;

  @override
  FastingSessionDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FastingSessionDBO(
      id: fields[0] as String,
      startedAt: fields[1] as DateTime,
      targetDurationMinutes: (fields[2] as num).toInt(),
      completedAt: fields[3] as DateTime?,
      cancelledAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FastingSessionDBO obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.targetDurationMinutes)
      ..writeByte(3)
      ..write(obj.completedAt)
      ..writeByte(4)
      ..write(obj.cancelledAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FastingSessionDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FastingSessionDBO _$FastingSessionDBOFromJson(Map<String, dynamic> json) =>
    FastingSessionDBO(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      targetDurationMinutes: (json['targetDurationMinutes'] as num).toInt(),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
    );

Map<String, dynamic> _$FastingSessionDBOToJson(FastingSessionDBO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startedAt': instance.startedAt.toIso8601String(),
      'targetDurationMinutes': instance.targetDurationMinutes,
      'completedAt': instance.completedAt?.toIso8601String(),
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
    };
