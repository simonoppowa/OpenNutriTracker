// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_type_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IntakeTypeDBOAdapter extends TypeAdapter<IntakeTypeDBO> {
  @override
  final int typeId = 4;

  @override
  IntakeTypeDBO read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return IntakeTypeDBO.breakfast;
      case 1:
        return IntakeTypeDBO.lunch;
      case 2:
        return IntakeTypeDBO.dinner;
      case 3:
        return IntakeTypeDBO.snack;
      default:
        return IntakeTypeDBO.breakfast;
    }
  }

  @override
  void write(BinaryWriter writer, IntakeTypeDBO obj) {
    switch (obj) {
      case IntakeTypeDBO.breakfast:
        writer.writeByte(0);
        break;
      case IntakeTypeDBO.lunch:
        writer.writeByte(1);
        break;
      case IntakeTypeDBO.dinner:
        writer.writeByte(2);
        break;
      case IntakeTypeDBO.snack:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntakeTypeDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
