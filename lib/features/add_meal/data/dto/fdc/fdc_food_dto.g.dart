// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fdc_food_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FDCFoodDTO _$FDCFoodDTOFromJson(Map<String, dynamic> json) => FDCFoodDTO(
      fdcId: (json['fdcId'] as num?)?.toDouble(),
      gtinUpc: json['gtinUpc'] as String?,
      description: json['description'] as String?,
      brandOwner: json['brandOwner'] as String?,
      brandName: json['brandName'] as String?,
      packageWeight: json['packageWeight'] as String?,
      servingSize: (json['servingSize'] as num?)?.toDouble(),
      foodNutrients: (json['foodNutrients'] as List<dynamic>)
          .map((e) => FDCFoodNutrimentDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      servingSizeUnit: json['servingSizeUnit'] as String?,
    );

Map<String, dynamic> _$FDCFoodDTOToJson(FDCFoodDTO instance) =>
    <String, dynamic>{
      'fdcId': instance.fdcId,
      'gtinUpc': instance.gtinUpc,
      'description': instance.description,
      'brandOwner': instance.brandOwner,
      'brandName': instance.brandName,
      'packageWeight': instance.packageWeight,
      'servingSize': instance.servingSize,
      'servingSizeUnit': instance.servingSizeUnit,
      'foodNutrients': instance.foodNutrients,
    };
