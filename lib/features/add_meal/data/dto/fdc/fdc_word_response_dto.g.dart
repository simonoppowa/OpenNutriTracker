// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fdc_word_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FDCWordResponseDTO _$FDCWordResponseDTOFromJson(Map<String, dynamic> json) =>
    FDCWordResponseDTO(
      totalHits: json['totalHits'] as int?,
      currentPage: json['currentPage'] as int?,
      foods: (json['foods'] as List<dynamic>)
          .map((e) => FDCFoodDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FDCWordResponseDTOToJson(FDCWordResponseDTO instance) =>
    <String, dynamic>{
      'totalHits': instance.totalHits,
      'currentPage': instance.currentPage,
      'foods': instance.foods,
    };
