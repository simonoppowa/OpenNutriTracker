// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipeDBOAdapter extends TypeAdapter<RecipeDBO> {
  @override
  final typeId = 16;

  @override
  RecipeDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeDBO(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      ingredients: (fields[3] as List).cast<RecipeIngredientDBO>(),
      totalWeightG: (fields[4] as num).toDouble(),
      aggregatedNutrimentsPer100: fields[5] as MealNutrimentsDBO,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      servingsCount: (fields[8] as num?)?.toInt(),
      tags: (fields[9] as List?)?.cast<String>(),
      imagePath: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeDBO obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.ingredients)
      ..writeByte(4)
      ..write(obj.totalWeightG)
      ..writeByte(5)
      ..write(obj.aggregatedNutrimentsPer100)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.servingsCount)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeDBO _$RecipeDBOFromJson(Map<String, dynamic> json) => RecipeDBO(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  ingredients: (json['ingredients'] as List<dynamic>)
      .map((e) => RecipeIngredientDBO.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalWeightG: (json['totalWeightG'] as num).toDouble(),
  aggregatedNutrimentsPer100: MealNutrimentsDBO.fromJson(
    json['aggregatedNutrimentsPer100'] as Map<String, dynamic>,
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  servingsCount: (json['servingsCount'] as num?)?.toInt(),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  imagePath: json['imagePath'] as String?,
);

Map<String, dynamic> _$RecipeDBOToJson(RecipeDBO instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'ingredients': instance.ingredients,
  'totalWeightG': instance.totalWeightG,
  'aggregatedNutrimentsPer100': instance.aggregatedNutrimentsPer100,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'servingsCount': instance.servingsCount,
  'tags': instance.tags,
  'imagePath': instance.imagePath,
};
