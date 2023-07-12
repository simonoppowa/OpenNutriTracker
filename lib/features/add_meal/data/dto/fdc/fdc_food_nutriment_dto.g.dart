// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fdc_food_nutriment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FDCFoodNutrimentDTO _$FDCFoodNutrimentDTOFromJson(Map<String, dynamic> json) =>
    FDCFoodNutrimentDTO(
      nutrientId: json['nutrient_id'] as int?,
      amount: (json['amount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FDCFoodNutrimentDTOToJson(
        FDCFoodNutrimentDTO instance) =>
    <String, dynamic>{
      'nutrient_id': instance.nutrientId,
      'amount': instance.amount,
    };
