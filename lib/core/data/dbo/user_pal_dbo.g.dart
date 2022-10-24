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
        return UserPALDBO.lightActivity;
      case 1:
        return UserPALDBO.moderateActivity;
      case 2:
        return UserPALDBO.vigorousActivity;
      default:
        return UserPALDBO.lightActivity;
    }
  }

  @override
  void write(BinaryWriter writer, UserPALDBO obj) {
    switch (obj) {
      case UserPALDBO.lightActivity:
        writer.writeByte(0);
        break;
      case UserPALDBO.moderateActivity:
        writer.writeByte(1);
        break;
      case UserPALDBO.vigorousActivity:
        writer.writeByte(2);
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
