// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fdc_food_nutriment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FDCFoodNutriment _$FDCFoodNutrimentFromJson(Map<String, dynamic> json) =>
    FDCFoodNutriment(
      nutrientId: json['nutrient_id'] as int?,
      amount: (json['amount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FDCFoodNutrimentToJson(FDCFoodNutriment instance) =>
    <String, dynamic>{
      'nutrient_id': instance.nutrientId,
      'amount': instance.amount,
    };
