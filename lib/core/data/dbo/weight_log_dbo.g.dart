// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_log_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeightLogDBOAdapter extends TypeAdapter<WeightLogDBO> {
  @override
  final typeId = 2;

  @override
  WeightLogDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeightLogDBO(
      date: fields[0] as DateTime,
      weightKg: (fields[1] as num).toDouble(),
      note: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WeightLogDBO obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.weightKg)
      ..writeByte(2)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightLogDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeightLogDBO _$WeightLogDBOFromJson(Map<String, dynamic> json) => WeightLogDBO(
  date: DateTime.parse(json['date'] as String),
  weightKg: (json['weightKg'] as num).toDouble(),
  note: json['note'] as String?,
);

Map<String, dynamic> _$WeightLogDBOToJson(WeightLogDBO instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'weightKg': instance.weightKg,
      'note': instance.note,
    };
