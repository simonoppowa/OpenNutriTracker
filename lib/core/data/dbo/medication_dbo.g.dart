// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationDBOAdapter extends TypeAdapter<MedicationDBO> {
  @override
  final typeId = 35;

  @override
  MedicationDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationDBO(
      id: fields[0] as String,
      day: fields[1] as DateTime,
      name: fields[2] as String,
      amount: (fields[3] as num).toDouble(),
      unit: fields[4] as String,
      taken: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationDBO obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.day)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.taken);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MedicationDBO _$MedicationDBOFromJson(Map<String, dynamic> json) =>
    MedicationDBO(
      id: json['id'] as String,
      day: DateTime.parse(json['day'] as String),
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      taken: json['taken'] as bool,
    );

Map<String, dynamic> _$MedicationDBOToJson(MedicationDBO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'day': instance.day.toIso8601String(),
      'name': instance.name,
      'amount': instance.amount,
      'unit': instance.unit,
      'taken': instance.taken,
    };
