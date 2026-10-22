// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourite_meal_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FavouriteMealDBOAdapter extends TypeAdapter<FavouriteMealDBO> {
  @override
  final typeId = 23;

  @override
  FavouriteMealDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavouriteMealDBO(
      meal: fields[0] as MealDBO,
      addedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FavouriteMealDBO obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.meal)
      ..writeByte(1)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavouriteMealDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavouriteMealDBO _$FavouriteMealDBOFromJson(Map<String, dynamic> json) =>
    FavouriteMealDBO(
      meal: MealDBO.fromJson(json['meal'] as Map<String, dynamic>),
      addedAt: DateTime.parse(json['addedAt'] as String),
    );

Map<String, dynamic> _$FavouriteMealDBOToJson(FavouriteMealDBO instance) =>
    <String, dynamic>{
      'meal': instance.meal,
      'addedAt': instance.addedAt.toIso8601String(),
    };
