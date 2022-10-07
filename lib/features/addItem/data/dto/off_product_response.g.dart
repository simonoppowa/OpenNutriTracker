// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'off_product_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OFFProductResponse _$OFFProductResponseFromJson(Map<String, dynamic> json) =>
    OFFProductResponse(
      status: json['status'] as int,
      status_verbose: json['status_verbose'] as String,
      product: OFFProduct.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OFFProductResponseToJson(OFFProductResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'status_verbose': instance.status_verbose,
      'product': instance.product,
    };
