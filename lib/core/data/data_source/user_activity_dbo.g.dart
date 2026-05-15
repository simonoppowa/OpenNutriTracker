// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_activity_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserActivityDBOAdapter extends TypeAdapter<UserActivityDBO> {
  @override
  final typeId = 10;

  @override
  UserActivityDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserActivityDBO(
      fields[0] as String,
      (fields[1] as num).toDouble(),
      (fields[2] as num).toDouble(),
      fields[3] as DateTime,
      fields[4] as PhysicalActivityDBO,
      userKcal: (fields[5] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, UserActivityDBO obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.duration)
      ..writeByte(2)
      ..write(obj.burnedKcal)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.physicalActivityDBO)
      ..writeByte(5)
      ..write(obj.userKcal);
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

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserActivityDBO _$UserActivityDBOFromJson(Map<String, dynamic> json) =>
    UserActivityDBO(
      json['id'] as String,
      (json['duration'] as num).toDouble(),
      (json['burnedKcal'] as num).toDouble(),
      DateTime.parse(json['date'] as String),
      PhysicalActivityDBO.fromJson(
        json['physicalActivityDBO'] as Map<String, dynamic>,
      ),
      userKcal: (json['userKcal'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$UserActivityDBOToJson(UserActivityDBO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'duration': instance.duration,
      'burnedKcal': instance.burnedKcal,
      'date': instance.date.toIso8601String(),
      'physicalActivityDBO': instance.physicalActivityDBO,
      'userKcal': instance.userKcal,
    };
