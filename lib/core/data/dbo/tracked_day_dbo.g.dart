// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracked_day_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrackedDayDBOAdapter extends TypeAdapter<TrackedDayDBO> {
  @override
  final typeId = 9;

  @override
  TrackedDayDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackedDayDBO(
      day: fields[0] as DateTime,
      calorieGoal: (fields[1] as num).toDouble(),
      caloriesTracked: (fields[2] as num).toDouble(),
      carbsGoal: (fields[3] as num?)?.toDouble(),
      carbsTracked: (fields[4] as num?)?.toDouble(),
      fatGoal: (fields[5] as num?)?.toDouble(),
      fatTracked: (fields[6] as num?)?.toDouble(),
      proteinGoal: (fields[7] as num?)?.toDouble(),
      proteinTracked: (fields[8] as num?)?.toDouble(),
      fibreGoal: (fields[9] as num?)?.toDouble(),
      satFatGoal: (fields[10] as num?)?.toDouble(),
      sugarsGoal: (fields[11] as num?)?.toDouble(),
      sodiumGoal: (fields[12] as num?)?.toDouble(),
      calciumGoal: (fields[13] as num?)?.toDouble(),
      ironGoal: (fields[14] as num?)?.toDouble(),
      potassiumGoal: (fields[15] as num?)?.toDouble(),
      vitaminDGoal: (fields[16] as num?)?.toDouble(),
      vitaminB12Goal: (fields[17] as num?)?.toDouble(),
      magnesiumGoal: (fields[18] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, TrackedDayDBO obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.day)
      ..writeByte(1)
      ..write(obj.calorieGoal)
      ..writeByte(2)
      ..write(obj.caloriesTracked)
      ..writeByte(3)
      ..write(obj.carbsGoal)
      ..writeByte(4)
      ..write(obj.carbsTracked)
      ..writeByte(5)
      ..write(obj.fatGoal)
      ..writeByte(6)
      ..write(obj.fatTracked)
      ..writeByte(7)
      ..write(obj.proteinGoal)
      ..writeByte(8)
      ..write(obj.proteinTracked)
      ..writeByte(9)
      ..write(obj.fibreGoal)
      ..writeByte(10)
      ..write(obj.satFatGoal)
      ..writeByte(11)
      ..write(obj.sugarsGoal)
      ..writeByte(12)
      ..write(obj.sodiumGoal)
      ..writeByte(13)
      ..write(obj.calciumGoal)
      ..writeByte(14)
      ..write(obj.ironGoal)
      ..writeByte(15)
      ..write(obj.potassiumGoal)
      ..writeByte(16)
      ..write(obj.vitaminDGoal)
      ..writeByte(17)
      ..write(obj.vitaminB12Goal)
      ..writeByte(18)
      ..write(obj.magnesiumGoal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackedDayDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackedDayDBO _$TrackedDayDBOFromJson(Map<String, dynamic> json) =>
    TrackedDayDBO(
      day: DateTime.parse(json['day'] as String),
      calorieGoal: (json['calorieGoal'] as num).toDouble(),
      caloriesTracked: (json['caloriesTracked'] as num).toDouble(),
      carbsGoal: (json['carbsGoal'] as num?)?.toDouble(),
      carbsTracked: (json['carbsTracked'] as num?)?.toDouble(),
      fatGoal: (json['fatGoal'] as num?)?.toDouble(),
      fatTracked: (json['fatTracked'] as num?)?.toDouble(),
      proteinGoal: (json['proteinGoal'] as num?)?.toDouble(),
      proteinTracked: (json['proteinTracked'] as num?)?.toDouble(),
      fibreGoal: (json['fibreGoal'] as num?)?.toDouble(),
      satFatGoal: (json['satFatGoal'] as num?)?.toDouble(),
      sugarsGoal: (json['sugarsGoal'] as num?)?.toDouble(),
      sodiumGoal: (json['sodiumGoal'] as num?)?.toDouble(),
      calciumGoal: (json['calciumGoal'] as num?)?.toDouble(),
      ironGoal: (json['ironGoal'] as num?)?.toDouble(),
      potassiumGoal: (json['potassiumGoal'] as num?)?.toDouble(),
      vitaminDGoal: (json['vitaminDGoal'] as num?)?.toDouble(),
      vitaminB12Goal: (json['vitaminB12Goal'] as num?)?.toDouble(),
      magnesiumGoal: (json['magnesiumGoal'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TrackedDayDBOToJson(TrackedDayDBO instance) =>
    <String, dynamic>{
      'day': instance.day.toIso8601String(),
      'calorieGoal': instance.calorieGoal,
      'caloriesTracked': instance.caloriesTracked,
      'carbsGoal': instance.carbsGoal,
      'carbsTracked': instance.carbsTracked,
      'fatGoal': instance.fatGoal,
      'fatTracked': instance.fatTracked,
      'proteinGoal': instance.proteinGoal,
      'proteinTracked': instance.proteinTracked,
      'fibreGoal': instance.fibreGoal,
      'satFatGoal': instance.satFatGoal,
      'sugarsGoal': instance.sugarsGoal,
      'sodiumGoal': instance.sodiumGoal,
      'calciumGoal': instance.calciumGoal,
      'ironGoal': instance.ironGoal,
      'potassiumGoal': instance.potassiumGoal,
      'vitaminDGoal': instance.vitaminDGoal,
      'vitaminB12Goal': instance.vitaminB12Goal,
      'magnesiumGoal': instance.magnesiumGoal,
    };
