// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'off_word_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OFFWordResponseDTO _$OFFWordResponseDTOFromJson(Map<String, dynamic> json) =>
    OFFWordResponseDTO(
      count: json['count'],
      page: json['page'],
      page_count: json['page_count'] as int?,
      page_size: json['page_size'] as int?,
      products: (json['products'] as List<dynamic>)
          .map((e) => OFFProductDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OFFWordResponseDTOToJson(OFFWordResponseDTO instance) =>
    <String, dynamic>{
      'count': instance.count,
      'page': instance.page,
      'page_count': instance.page_count,
      'page_size': instance.page_size,
      'products': instance.products,
    };
