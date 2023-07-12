// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'off_product_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OFFProductResponseDTO _$OFFProductResponseDTOFromJson(
        Map<String, dynamic> json) =>
    OFFProductResponseDTO(
      status: json['status'] as int,
      status_verbose: json['status_verbose'] as String,
      product: OFFProductDTO.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OFFProductResponseDTOToJson(
        OFFProductResponseDTO instance) =>
    <String, dynamic>{
      'status': instance.status,
      'status_verbose': instance.status_verbose,
      'product': instance.product,
    };
