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
      id: fields[0] as String,
      unit: fields[1] as String,
      amount: fields[2] as double,
      type: fields[3] as IntakeTypeDBO,
      meal: fields[4] as MealDBO,
      dateTime: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, IntakeDBO obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.unit)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.meal)
      ..writeByte(5)
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

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntakeDBO _$IntakeDBOFromJson(Map<String, dynamic> json) => IntakeDBO(
      id: json['id'] as String,
      unit: json['unit'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: $enumDecode(_$IntakeTypeDBOEnumMap, json['type']),
      meal: MealDBO.fromJson(json['meal'] as Map<String, dynamic>),
      dateTime: DateTime.parse(json['dateTime'] as String),
    );

Map<String, dynamic> _$IntakeDBOToJson(IntakeDBO instance) => <String, dynamic>{
      'id': instance.id,
      'unit': instance.unit,
      'amount': instance.amount,
      'type': _$IntakeTypeDBOEnumMap[instance.type]!,
      'meal': instance.meal,
      'dateTime': instance.dateTime.toIso8601String(),
    };

const _$IntakeTypeDBOEnumMap = {
  IntakeTypeDBO.breakfast: 'breakfast',
  IntakeTypeDBO.lunch: 'lunch',
  IntakeTypeDBO.dinner: 'dinner',
  IntakeTypeDBO.snack: 'snack',
};
