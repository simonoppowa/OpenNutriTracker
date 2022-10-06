// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_nutriments_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductNutrimentsDBOAdapter extends TypeAdapter<ProductNutrimentsDBO> {
  @override
  final int typeId = 3;

  @override
  ProductNutrimentsDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductNutrimentsDBO(
      energyKcal100: fields[0] as double?,
      energyPerUnit: fields[1] as double?,
      carbohydrates100g: fields[2] as double?,
      carbohydratesPerUnit: fields[3] as double?,
      fat100g: fields[4] as double?,
      fatPerUnit: fields[5] as double?,
      proteins100g: fields[6] as double?,
      proteinsPerUnit: fields[7] as double?,
      sugars100g: fields[8] as double?,
      saturatedFat100g: fields[9] as double?,
      fiber100g: fields[10] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductNutrimentsDBO obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.energyKcal100)
      ..writeByte(1)
      ..write(obj.energyPerUnit)
      ..writeByte(2)
      ..write(obj.carbohydrates100g)
      ..writeByte(3)
      ..write(obj.carbohydratesPerUnit)
      ..writeByte(4)
      ..write(obj.fat100g)
      ..writeByte(5)
      ..write(obj.fatPerUnit)
      ..writeByte(6)
      ..write(obj.proteins100g)
      ..writeByte(7)
      ..write(obj.proteinsPerUnit)
      ..writeByte(8)
      ..write(obj.sugars100g)
      ..writeByte(9)
      ..write(obj.saturatedFat100g)
      ..writeByte(10)
      ..write(obj.fiber100g);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductNutrimentsDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
