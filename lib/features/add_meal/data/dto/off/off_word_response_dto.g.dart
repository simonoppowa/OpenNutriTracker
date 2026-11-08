// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'off_word_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OFFWordResponseDTO _$OFFWordResponseDTOFromJson(Map<String, dynamic> json) =>
    OFFWordResponseDTO(
      count: json['count'],
      page: json['page'],
      page_count: offIntFromJson(json['page_count']),
      page_size: offIntFromJson(json['page_size']),
      products: offProductsFromJson(
        OFFWordResponseDTO._matchesFromEitherKey(json, 'hits'),
      ),
    );

Map<String, dynamic> _$OFFWordResponseDTOToJson(OFFWordResponseDTO instance) =>
    <String, dynamic>{
      'count': instance.count,
      'page': instance.page,
      'page_count': instance.page_count,
      'page_size': instance.page_size,
      'hits': instance.products,
    };
