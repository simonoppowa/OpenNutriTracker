// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracked_day_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrackedDayDBOAdapter extends TypeAdapter<TrackedDayDBO> {
  @override
  final int typeId = 9;

  @override
  TrackedDayDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackedDayDBO(
      day: fields[0] as DateTime,
      calorieGoal: fields[1] as double,
      caloriesTracked: fields[2] as double,
      carbsGoal: fields[3] as double?,
      carbsTracked: fields[4] as double?,
      fatGoal: fields[5] as double?,
      fatTracked: fields[6] as double?,
      proteinGoal: fields[7] as double?,
      proteinTracked: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, TrackedDayDBO obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.day)
      ..writeByte(1)
      ..write(obj.calorieGoal)
      ..writeByte(2)
      ..write(obj.caloriesTracked)
      ..writeByte(3)
      ..write(obj.carbsGoal)
      ..writeByte(4)
      ..write(obj.carbsTracked)
      ..writeByte(5)
      ..write(obj.fatGoal)
      ..writeByte(6)
      ..write(obj.fatTracked)
      ..writeByte(7)
      ..write(obj.proteinGoal)
      ..writeByte(8)
      ..write(obj.proteinTracked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackedDayDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackedDayDBO _$TrackedDayDBOFromJson(Map<String, dynamic> json) =>
    TrackedDayDBO(
      day: DateTime.parse(json['day'] as String),
      calorieGoal: (json['calorieGoal'] as num).toDouble(),
      caloriesTracked: (json['caloriesTracked'] as num).toDouble(),
      carbsGoal: (json['carbsGoal'] as num?)?.toDouble(),
      carbsTracked: (json['carbsTracked'] as num?)?.toDouble(),
      fatGoal: (json['fatGoal'] as num?)?.toDouble(),
      fatTracked: (json['fatTracked'] as num?)?.toDouble(),
      proteinGoal: (json['proteinGoal'] as num?)?.toDouble(),
      proteinTracked: (json['proteinTracked'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TrackedDayDBOToJson(TrackedDayDBO instance) =>
    <String, dynamic>{
      'day': instance.day.toIso8601String(),
      'calorieGoal': instance.calorieGoal,
      'caloriesTracked': instance.caloriesTracked,
      'carbsGoal': instance.carbsGoal,
      'carbsTracked': instance.carbsTracked,
      'fatGoal': instance.fatGoal,
      'fatTracked': instance.fatTracked,
      'proteinGoal': instance.proteinGoal,
      'proteinTracked': instance.proteinTracked,
    };
