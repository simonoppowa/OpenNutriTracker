// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fdc_food.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FDCFood _$FDCFoodFromJson(Map<String, dynamic> json) => FDCFood(
      fdcId: (json['fdcId'] as num?)?.toDouble(),
      gtinUpc: json['gtinUpc'] as String?,
      description: json['description'] as String?,
      brandOwner: json['brandOwner'] as String?,
      brandName: json['brandName'] as String?,
      packageWeight: json['packageWeight'] as String?,
      servingSize: (json['servingSize'] as num?)?.toDouble(),
      foodNutrients: (json['foodNutrients'] as List<dynamic>)
          .map((e) => FDCFoodNutriment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FDCFoodToJson(FDCFood instance) => <String, dynamic>{
      'fdcId': instance.fdcId,
      'gtinUpc': instance.gtinUpc,
      'description': instance.description,
      'brandOwner': instance.brandOwner,
      'brandName': instance.brandName,
      'packageWeight': instance.packageWeight,
      'servingSize': instance.servingSize,
      'foodNutrients': instance.foodNutrients,
    };
