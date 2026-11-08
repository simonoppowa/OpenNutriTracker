// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'off_product_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OFFProductResponseDTO _$OFFProductResponseDTOFromJson(
  Map<String, dynamic> json,
) => OFFProductResponseDTO(
  status: offIntFromJson(json['status']),
  status_verbose: json['status_verbose'] as String?,
  product: OFFProductResponseDTO._productFromJson(json['product']),
);

Map<String, dynamic> _$OFFProductResponseDTOToJson(
  OFFProductResponseDTO instance,
) => <String, dynamic>{
  'status': instance.status,
  'status_verbose': instance.status_verbose,
  'product': instance.product,
};
