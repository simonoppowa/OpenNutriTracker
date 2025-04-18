// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_nutriments_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealNutrimentsDBOAdapter extends TypeAdapter<MealNutrimentsDBO> {
  @override
  final int typeId = 3;

  @override
  MealNutrimentsDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealNutrimentsDBO(
      energyKcal100: fields[0] as double?,
      carbohydrates100: fields[1] as double?,
      fat100: fields[2] as double?,
      proteins100: fields[3] as double?,
      sugars100: fields[4] as double?,
      saturatedFat100: fields[5] as double?,
      fiber100: fields[6] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, MealNutrimentsDBO obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.energyKcal100)
      ..writeByte(1)
      ..write(obj.carbohydrates100)
      ..writeByte(2)
      ..write(obj.fat100)
      ..writeByte(3)
      ..write(obj.proteins100)
      ..writeByte(4)
      ..write(obj.sugars100)
      ..writeByte(5)
      ..write(obj.saturatedFat100)
      ..writeByte(6)
      ..write(obj.fiber100);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealNutrimentsDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealNutrimentsDBO _$MealNutrimentsDBOFromJson(Map<String, dynamic> json) =>
    MealNutrimentsDBO(
      energyKcal100: (json['energyKcal100'] as num?)?.toDouble(),
      carbohydrates100: (json['carbohydrates100'] as num?)?.toDouble(),
      fat100: (json['fat100'] as num?)?.toDouble(),
      proteins100: (json['proteins100'] as num?)?.toDouble(),
      sugars100: (json['sugars100'] as num?)?.toDouble(),
      saturatedFat100: (json['saturatedFat100'] as num?)?.toDouble(),
      fiber100: (json['fiber100'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MealNutrimentsDBOToJson(MealNutrimentsDBO instance) =>
    <String, dynamic>{
      'energyKcal100': instance.energyKcal100,
      'carbohydrates100': instance.carbohydrates100,
      'fat100': instance.fat100,
      'proteins100': instance.proteins100,
      'sugars100': instance.sugars100,
      'saturatedFat100': instance.saturatedFat100,
      'fiber100': instance.fiber100,
    };
