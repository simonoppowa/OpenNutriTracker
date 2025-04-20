// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealDBOAdapter extends TypeAdapter<MealDBO> {
  @override
  final int typeId = 1;

  @override
  MealDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealDBO(
      code: fields[0] as String?,
      name: fields[1] as String?,
      brands: fields[2] as String?,
      thumbnailImageUrl: fields[3] as String?,
      mainImageUrl: fields[4] as String?,
      url: fields[5] as String?,
      mealQuantity: fields[6] as String?,
      mealUnit: fields[7] as String?,
      servingQuantity: fields[8] as double?,
      servingUnit: fields[9] as String?,
      servingSize: fields[12] as String?,
      nutriments: fields[11] as MealNutrimentsDBO,
      source: fields[10] as MealSourceDBO,
    );
  }

  @override
  void write(BinaryWriter writer, MealDBO obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.brands)
      ..writeByte(3)
      ..write(obj.thumbnailImageUrl)
      ..writeByte(4)
      ..write(obj.mainImageUrl)
      ..writeByte(5)
      ..write(obj.url)
      ..writeByte(6)
      ..write(obj.mealQuantity)
      ..writeByte(7)
      ..write(obj.mealUnit)
      ..writeByte(8)
      ..write(obj.servingQuantity)
      ..writeByte(9)
      ..write(obj.servingUnit)
      ..writeByte(12)
      ..write(obj.servingSize)
      ..writeByte(10)
      ..write(obj.source)
      ..writeByte(11)
      ..write(obj.nutriments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealSourceDBOAdapter extends TypeAdapter<MealSourceDBO> {
  @override
  final int typeId = 14;

  @override
  MealSourceDBO read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MealSourceDBO.unknown;
      case 1:
        return MealSourceDBO.custom;
      case 2:
        return MealSourceDBO.off;
      case 3:
        return MealSourceDBO.fdc;
      default:
        return MealSourceDBO.unknown;
    }
  }

  @override
  void write(BinaryWriter writer, MealSourceDBO obj) {
    switch (obj) {
      case MealSourceDBO.unknown:
        writer.writeByte(0);
        break;
      case MealSourceDBO.custom:
        writer.writeByte(1);
        break;
      case MealSourceDBO.off:
        writer.writeByte(2);
        break;
      case MealSourceDBO.fdc:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealSourceDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealDBO _$MealDBOFromJson(Map<String, dynamic> json) => MealDBO(
      code: json['code'] as String?,
      name: json['name'] as String?,
      brands: json['brands'] as String?,
      thumbnailImageUrl: json['thumbnailImageUrl'] as String?,
      mainImageUrl: json['mainImageUrl'] as String?,
      url: json['url'] as String?,
      mealQuantity: json['mealQuantity'] as String?,
      mealUnit: json['mealUnit'] as String?,
      servingQuantity: (json['servingQuantity'] as num?)?.toDouble(),
      servingUnit: json['servingUnit'] as String?,
      servingSize: json['servingSize'] as String?,
      nutriments: MealNutrimentsDBO.fromJson(
          json['nutriments'] as Map<String, dynamic>),
      source: $enumDecode(_$MealSourceDBOEnumMap, json['source']),
    );

Map<String, dynamic> _$MealDBOToJson(MealDBO instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'brands': instance.brands,
      'thumbnailImageUrl': instance.thumbnailImageUrl,
      'mainImageUrl': instance.mainImageUrl,
      'url': instance.url,
      'mealQuantity': instance.mealQuantity,
      'mealUnit': instance.mealUnit,
      'servingQuantity': instance.servingQuantity,
      'servingUnit': instance.servingUnit,
      'servingSize': instance.servingSize,
      'source': _$MealSourceDBOEnumMap[instance.source]!,
      'nutriments': instance.nutriments,
    };

const _$MealSourceDBOEnumMap = {
  MealSourceDBO.unknown: 'unknown',
  MealSourceDBO.custom: 'custom',
  MealSourceDBO.off: 'off',
  MealSourceDBO.fdc: 'fdc',
};
