// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'off_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OFFProduct _$OFFProductFromJson(Map<String, dynamic> json) => OFFProduct(
      code: json['code'] as String?,
      product_name: json['product_name'] as String?,
      product_name_de: json['product_name_de'] as String?,
      product_name_en: json['product_name_en'] as String?,
      brands: json['brands'] as String?,
      image_front_thumb_url: json['image_front_thumb_url'] as String?,
      image_front_url: json['image_front_url'] as String?,
      image_ingredients_url: json['image_ingredients_url'] as String?,
      image_nutrition_url: json['image_nutrition_url'] as String?,
      image_url: json['image_url'] as String?,
      quantity: json['quantity'] as String?,
      product_quantity: json['product_quantity'],
      serving_quantity: json['serving_quantity'],
      serving_size: json['serving_size'] as String?,
    );

Map<String, dynamic> _$OFFProductToJson(OFFProduct instance) =>
    <String, dynamic>{
      'code': instance.code,
      'product_name': instance.product_name,
      'product_name_de': instance.product_name_de,
      'product_name_en': instance.product_name_en,
      'brands': instance.brands,
      'image_front_thumb_url': instance.image_front_thumb_url,
      'image_front_url': instance.image_front_url,
      'image_ingredients_url': instance.image_ingredients_url,
      'image_nutrition_url': instance.image_nutrition_url,
      'image_url': instance.image_url,
      'quantity': instance.quantity,
      'product_quantity': instance.product_quantity,
      'serving_quantity': instance.serving_quantity,
      'serving_size': instance.serving_size,
    };
