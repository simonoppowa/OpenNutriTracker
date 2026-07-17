// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileDBOAdapter extends TypeAdapter<ProfileDBO> {
  @override
  final typeId = 20;

  @override
  ProfileDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileDBO(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[3] as DateTime,
      boxSuffix: fields[4] as String,
      imagePath: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProfileDBO obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.boxSuffix);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
