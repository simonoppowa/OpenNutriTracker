// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_nutriments_dto.dart';

part 'off_product_dto.g.dart';

@JsonSerializable()
class OFFProductDTO {
  final String? code;
  final String? product_name;
  final String? product_name_en;
  final String? product_name_fr;
  final String? product_name_de;
  // OFF carries product names in many languages — these five cover the
  // remaining locales the ONT UI ships in (cs / it / sk / tr / uk). When any
  // are missing or blank for a particular product the lookup falls
  // through to product_name / product_name_en / etc as before.
  final String? product_name_cs;
  final String? product_name_it;
  final String? product_name_sk;
  final String? product_name_tr;
  final String? product_name_uk;

  final String? brands;

  final String? image_front_thumb_url;
  final String? image_front_url;
  final String? image_ingredients_url;
  final String? image_nutrition_url;
  final String? image_url;

  final String? url;

  final String? quantity;
  final dynamic product_quantity; // Can either be int or String
  final dynamic serving_quantity; // Can either be int or String
  final String? serving_size; // E.g. 2 Tbsp (32 g)

  final OFFProductNutrimentsDTO? nutriments;

  String? getLocaleName(SupportedLanguage supportedLanguage) {
    String? localeName;
    switch (supportedLanguage) {
      case SupportedLanguage.en:
        localeName = product_name_en;
        break;
      case SupportedLanguage.de:
        localeName = product_name_de;
        break;
      case SupportedLanguage.cs:
        localeName = product_name_cs;
        break;
      case SupportedLanguage.it:
        localeName = product_name_it;
        break;
      case SupportedLanguage.sk:
        localeName = product_name_sk;
        break;
      case SupportedLanguage.tr:
        localeName = product_name_tr;
        break;
      case SupportedLanguage.uk:
        localeName = product_name_uk;
        break;
      case SupportedLanguage.pl:
      case SupportedLanguage.zh:
        // OFF doesn't surface separate `product_name_pl` / `_zh` fields
        // for most products; the unsuffixed product_name covers them in
        // practice.
        localeName = product_name;
        break;
    }

    // If local language is not available, return available language
    if (localeName == null || localeName.isEmpty) {
      localeName =
          product_name ?? product_name_en ?? product_name_fr ?? product_name_de;
    }
    return localeName;
  }

  OFFProductDTO({
    required this.code,
    required this.product_name,
    required this.product_name_en,
    required this.product_name_fr,
    required this.product_name_de,
    this.product_name_cs,
    this.product_name_it,
    this.product_name_sk,
    this.product_name_tr,
    this.product_name_uk,
    required this.brands,
    required this.image_front_thumb_url,
    required this.image_front_url,
    required this.image_ingredients_url,
    required this.image_nutrition_url,
    required this.image_url,
    required this.url,
    required this.quantity,
    required this.product_quantity,
    required this.serving_quantity,
    required this.serving_size,
    required this.nutriments,
  });

  factory OFFProductDTO.fromJson(Map<String, dynamic> json) =>
      _$OFFProductDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OFFProductDTOToJson(this);
}
