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
    );
  }

  @override
  void write(BinaryWriter writer, TrackedDayDBO obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.day)
      ..writeByte(1)
      ..write(obj.calorieGoal)
      ..writeByte(2)
      ..write(obj.caloriesTracked);
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
