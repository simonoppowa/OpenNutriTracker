// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_nutriments_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealNutrimentsDBOAdapter extends TypeAdapter<MealNutrimentsDBO> {
  @override
  final typeId = 3;

  @override
  MealNutrimentsDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealNutrimentsDBO(
      energyKcal100: (fields[0] as num?)?.toDouble(),
      carbohydrates100: (fields[1] as num?)?.toDouble(),
      fat100: (fields[2] as num?)?.toDouble(),
      proteins100: (fields[3] as num?)?.toDouble(),
      sugars100: (fields[4] as num?)?.toDouble(),
      saturatedFat100: (fields[5] as num?)?.toDouble(),
      fiber100: (fields[6] as num?)?.toDouble(),
      monounsaturatedFat100: (fields[7] as num?)?.toDouble(),
      polyunsaturatedFat100: (fields[8] as num?)?.toDouble(),
      transFat100: (fields[9] as num?)?.toDouble(),
      cholesterol100: (fields[10] as num?)?.toDouble(),
      sodium100: (fields[11] as num?)?.toDouble(),
      potassium100: (fields[12] as num?)?.toDouble(),
      magnesium100: (fields[13] as num?)?.toDouble(),
      calcium100: (fields[14] as num?)?.toDouble(),
      iron100: (fields[15] as num?)?.toDouble(),
      zinc100: (fields[16] as num?)?.toDouble(),
      phosphorus100: (fields[17] as num?)?.toDouble(),
      vitaminA100: (fields[18] as num?)?.toDouble(),
      vitaminC100: (fields[19] as num?)?.toDouble(),
      vitaminD100: (fields[20] as num?)?.toDouble(),
      vitaminB6100: (fields[21] as num?)?.toDouble(),
      vitaminB12100: (fields[22] as num?)?.toDouble(),
      niacin100: (fields[23] as num?)?.toDouble(),
      vitaminE100: (fields[100] as num?)?.toDouble(),
      vitaminK100: (fields[101] as num?)?.toDouble(),
      thiamin100: (fields[102] as num?)?.toDouble(),
      riboflavin100: (fields[103] as num?)?.toDouble(),
      pantothenicAcid100: (fields[104] as num?)?.toDouble(),
      biotin100: (fields[105] as num?)?.toDouble(),
      folate100: (fields[106] as num?)?.toDouble(),
      iodine100: (fields[107] as num?)?.toDouble(),
      selenium100: (fields[108] as num?)?.toDouble(),
      copper100: (fields[109] as num?)?.toDouble(),
      manganese100: (fields[110] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, MealNutrimentsDBO obj) {
    writer
      ..writeByte(35)
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
      ..write(obj.fiber100)
      ..writeByte(7)
      ..write(obj.monounsaturatedFat100)
      ..writeByte(8)
      ..write(obj.polyunsaturatedFat100)
      ..writeByte(9)
      ..write(obj.transFat100)
      ..writeByte(10)
      ..write(obj.cholesterol100)
      ..writeByte(11)
      ..write(obj.sodium100)
      ..writeByte(12)
      ..write(obj.potassium100)
      ..writeByte(13)
      ..write(obj.magnesium100)
      ..writeByte(14)
      ..write(obj.calcium100)
      ..writeByte(15)
      ..write(obj.iron100)
      ..writeByte(16)
      ..write(obj.zinc100)
      ..writeByte(17)
      ..write(obj.phosphorus100)
      ..writeByte(18)
      ..write(obj.vitaminA100)
      ..writeByte(19)
      ..write(obj.vitaminC100)
      ..writeByte(20)
      ..write(obj.vitaminD100)
      ..writeByte(21)
      ..write(obj.vitaminB6100)
      ..writeByte(22)
      ..write(obj.vitaminB12100)
      ..writeByte(23)
      ..write(obj.niacin100)
      ..writeByte(100)
      ..write(obj.vitaminE100)
      ..writeByte(101)
      ..write(obj.vitaminK100)
      ..writeByte(102)
      ..write(obj.thiamin100)
      ..writeByte(103)
      ..write(obj.riboflavin100)
      ..writeByte(104)
      ..write(obj.pantothenicAcid100)
      ..writeByte(105)
      ..write(obj.biotin100)
      ..writeByte(106)
      ..write(obj.folate100)
      ..writeByte(107)
      ..write(obj.iodine100)
      ..writeByte(108)
      ..write(obj.selenium100)
      ..writeByte(109)
      ..write(obj.copper100)
      ..writeByte(110)
      ..write(obj.manganese100);
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

MealNutrimentsDBO _$MealNutrimentsDBOFromJson(
  Map<String, dynamic> json,
) => MealNutrimentsDBO(
  energyKcal100: (json['energyKcal100'] as num?)?.toDouble(),
  carbohydrates100: (json['carbohydrates100'] as num?)?.toDouble(),
  fat100: (json['fat100'] as num?)?.toDouble(),
  proteins100: (json['proteins100'] as num?)?.toDouble(),
  sugars100: (json['sugars100'] as num?)?.toDouble(),
  saturatedFat100: (json['saturatedFat100'] as num?)?.toDouble(),
  fiber100: (json['fiber100'] as num?)?.toDouble(),
  monounsaturatedFat100: (json['monounsaturatedFat100'] as num?)?.toDouble(),
  polyunsaturatedFat100: (json['polyunsaturatedFat100'] as num?)?.toDouble(),
  transFat100: (json['transFat100'] as num?)?.toDouble(),
  cholesterol100: (json['cholesterol100'] as num?)?.toDouble(),
  sodium100: (json['sodium100'] as num?)?.toDouble(),
  potassium100: (json['potassium100'] as num?)?.toDouble(),
  magnesium100: (json['magnesium100'] as num?)?.toDouble(),
  calcium100: (json['calcium100'] as num?)?.toDouble(),
  iron100: (json['iron100'] as num?)?.toDouble(),
  zinc100: (json['zinc100'] as num?)?.toDouble(),
  phosphorus100: (json['phosphorus100'] as num?)?.toDouble(),
  vitaminA100: (json['vitaminA100'] as num?)?.toDouble(),
  vitaminC100: (json['vitaminC100'] as num?)?.toDouble(),
  vitaminD100: (json['vitaminD100'] as num?)?.toDouble(),
  vitaminB6100: (json['vitaminB6100'] as num?)?.toDouble(),
  vitaminB12100: (json['vitaminB12100'] as num?)?.toDouble(),
  niacin100: (json['niacin100'] as num?)?.toDouble(),
  vitaminE100: (json['vitaminE100'] as num?)?.toDouble(),
  vitaminK100: (json['vitaminK100'] as num?)?.toDouble(),
  thiamin100: (json['thiamin100'] as num?)?.toDouble(),
  riboflavin100: (json['riboflavin100'] as num?)?.toDouble(),
  pantothenicAcid100: (json['pantothenicAcid100'] as num?)?.toDouble(),
  biotin100: (json['biotin100'] as num?)?.toDouble(),
  folate100: (json['folate100'] as num?)?.toDouble(),
  iodine100: (json['iodine100'] as num?)?.toDouble(),
  selenium100: (json['selenium100'] as num?)?.toDouble(),
  copper100: (json['copper100'] as num?)?.toDouble(),
  manganese100: (json['manganese100'] as num?)?.toDouble(),
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
      'monounsaturatedFat100': instance.monounsaturatedFat100,
      'polyunsaturatedFat100': instance.polyunsaturatedFat100,
      'transFat100': instance.transFat100,
      'cholesterol100': instance.cholesterol100,
      'sodium100': instance.sodium100,
      'potassium100': instance.potassium100,
      'magnesium100': instance.magnesium100,
      'calcium100': instance.calcium100,
      'iron100': instance.iron100,
      'zinc100': instance.zinc100,
      'phosphorus100': instance.phosphorus100,
      'vitaminA100': instance.vitaminA100,
      'vitaminC100': instance.vitaminC100,
      'vitaminD100': instance.vitaminD100,
      'vitaminB6100': instance.vitaminB6100,
      'vitaminB12100': instance.vitaminB12100,
      'niacin100': instance.niacin100,
      'vitaminE100': instance.vitaminE100,
      'vitaminK100': instance.vitaminK100,
      'thiamin100': instance.thiamin100,
      'riboflavin100': instance.riboflavin100,
      'pantothenicAcid100': instance.pantothenicAcid100,
      'biotin100': instance.biotin100,
      'folate100': instance.folate100,
      'iodine100': instance.iodine100,
      'selenium100': instance.selenium100,
      'copper100': instance.copper100,
      'manganese100': instance.manganese100,
    };
