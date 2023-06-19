// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fdc_food_nutriment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FDCFoodNutriment _$FDCFoodNutrimentFromJson(Map<String, dynamic> json) =>
    FDCFoodNutriment(
      nutrientId: json['nutrientId'] as int?,
      value: (json['value'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FDCFoodNutrimentToJson(FDCFoodNutriment instance) =>
    <String, dynamic>{
      'nutrientId': instance.nutrientId,
      'value': instance.value,
    };
