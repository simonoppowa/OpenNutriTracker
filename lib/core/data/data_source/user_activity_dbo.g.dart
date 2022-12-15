// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_activity_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserActivityDBOAdapter extends TypeAdapter<UserActivityDBO> {
  @override
  final int typeId = 10;

  @override
  UserActivityDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserActivityDBO(
      fields[0] as String,
      fields[1] as double,
      fields[2] as double,
      fields[3] as DateTime,
      fields[4] as PhysicalActivityDBO,
    );
  }

  @override
  void write(BinaryWriter writer, UserActivityDBO obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.duration)
      ..writeByte(2)
      ..write(obj.burnedKcal)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.physicalActivityDBO);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserActivityDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
