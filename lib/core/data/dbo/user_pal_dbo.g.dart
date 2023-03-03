// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_pal_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPALDBOAdapter extends TypeAdapter<UserPALDBO> {
  @override
  final int typeId = 8;

  @override
  UserPALDBO read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserPALDBO.sedentary;
      case 1:
        return UserPALDBO.lowActive;
      case 2:
        return UserPALDBO.active;
      case 3:
        return UserPALDBO.veryActive;
      default:
        return UserPALDBO.sedentary;
    }
  }

  @override
  void write(BinaryWriter writer, UserPALDBO obj) {
    switch (obj) {
      case UserPALDBO.sedentary:
        writer.writeByte(0);
        break;
      case UserPALDBO.lowActive:
        writer.writeByte(1);
        break;
      case UserPALDBO.active:
        writer.writeByte(2);
        break;
      case UserPALDBO.veryActive:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPALDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
