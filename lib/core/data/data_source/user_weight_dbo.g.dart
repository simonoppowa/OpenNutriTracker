// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_weight_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserWeightDboAdapter extends TypeAdapter<UserWeightDbo> {
  @override
  final int typeId = 18;

  @override
  UserWeightDbo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserWeightDbo(
      fields[0] as String,
      fields[1] as double,
      fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserWeightDbo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserWeightDboAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserWeightDbo _$UserWeightDboFromJson(Map<String, dynamic> json) =>
    UserWeightDbo(
      json['id'] as String,
      (json['weight'] as num).toDouble(),
      DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$UserWeightDboToJson(UserWeightDbo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weight': instance.weight,
      'date': instance.date.toIso8601String(),
    };
