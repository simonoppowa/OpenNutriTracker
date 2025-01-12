// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sp_fdc_food_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpFdcFoodDTO _$SpFdcFoodDTOFromJson(Map<String, dynamic> json) => SpFdcFoodDTO(
      fdcId: (json['fdc_id'] as num?)?.toInt(),
      descriptionEn: json['description_en'] as String?,
      descriptionDe: json['description_de'] as String?,
      nutrients: (json['fdc_nutrients'] as List<dynamic>)
          .map((e) => FDCFoodNutrimentDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      portions: (json['fdc_portions'] as List<dynamic>)
          .map((e) => SpFdcPortionDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SpFdcFoodDTOToJson(SpFdcFoodDTO instance) =>
    <String, dynamic>{
      'fdc_id': instance.fdcId,
      'description_en': instance.descriptionEn,
      'description_de': instance.descriptionDe,
      'fdc_nutrients': instance.nutrients,
      'fdc_portions': instance.portions,
    };
