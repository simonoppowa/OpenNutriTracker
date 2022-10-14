// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IntakeDBOAdapter extends TypeAdapter<IntakeDBO> {
  @override
  final int typeId = 0;

  @override
  IntakeDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IntakeDBO(
      unit: fields[0] as String,
      amount: fields[1] as double,
      type: fields[2] as IntakeTypeDBO,
      product: fields[3] as ProductDBO,
      dateTime: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, IntakeDBO obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.unit)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.product)
      ..writeByte(4)
      ..write(obj.dateTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntakeDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
