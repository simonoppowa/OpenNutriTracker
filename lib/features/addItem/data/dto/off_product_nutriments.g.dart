// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'off_product_nutriments.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OFFProductNutriments _$OFFProductNutrimentsFromJson(
        Map<String, dynamic> json) =>
    OFFProductNutriments(
      energy_unit: json['energy_unit'] as String?,
      energy_kcal: (json['energy-kcal'] as num?)?.toDouble(),
      energy_kcal_100g: (json['energy-kcal_100g'] as num?)?.toDouble(),
      energy_kcal_serving: (json['energy-kcal_serving'] as num?)?.toDouble(),
      energy_kcal_unit: json['energy-kcal_unit'] as String?,
      energy_kcal_value: (json['energy-kcal_value'] as num?)?.toDouble(),
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble(),
      carbohydrates_100g: (json['carbohydrates_100g'] as num?)?.toDouble(),
      carbohydrates_serving:
          (json['carbohydrates_serving'] as num?)?.toDouble(),
      carbohydrates_value: (json['carbohydrates_value'] as num?)?.toDouble(),
      carbohydrates_unit: json['carbohydrates_unit'] as String?,
      fat: (json['fat'] as num?)?.toDouble(),
      fat_100g: (json['fat_100g'] as num?)?.toDouble(),
      fat_serving: (json['fat_serving'] as num?)?.toDouble(),
      fat_value: (json['fat_value'] as num?)?.toDouble(),
      fat_unit: json['fat_unit'] as String?,
      proteins: (json['proteins'] as num?)?.toDouble(),
      proteins_100g: (json['proteins_100g'] as num?)?.toDouble(),
      proteins_serving: (json['proteins_serving'] as num?)?.toDouble(),
      proteins_value: (json['proteins_value'] as num?)?.toDouble(),
      proteins_unit: json['proteins_unit'] as String?,
    );

Map<String, dynamic> _$OFFProductNutrimentsToJson(
        OFFProductNutriments instance) =>
    <String, dynamic>{
      'energy-kcal': instance.energy_kcal,
      'energy_unit': instance.energy_unit,
      'energy-kcal_100g': instance.energy_kcal_100g,
      'energy-kcal_serving': instance.energy_kcal_serving,
      'energy-kcal_value': instance.energy_kcal_value,
      'energy-kcal_unit': instance.energy_kcal_unit,
      'carbohydrates': instance.carbohydrates,
      'carbohydrates_100g': instance.carbohydrates_100g,
      'carbohydrates_serving': instance.carbohydrates_serving,
      'carbohydrates_value': instance.carbohydrates_value,
      'carbohydrates_unit': instance.carbohydrates_unit,
      'fat': instance.fat,
      'fat_100g': instance.fat_100g,
      'fat_serving': instance.fat_serving,
      'fat_value': instance.fat_value,
      'fat_unit': instance.fat_unit,
      'proteins': instance.proteins,
      'proteins_100g': instance.proteins_100g,
      'proteins_serving': instance.proteins_serving,
      'proteins_value': instance.proteins_value,
      'proteins_unit': instance.proteins_unit,
    };
