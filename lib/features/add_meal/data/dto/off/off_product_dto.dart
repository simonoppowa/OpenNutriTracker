// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_json_helpers.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_nutriments_dto.dart';

part 'off_product_dto.g.dart';

String? _brandsFromJson(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    final parts = value
        .map((e) => e?.toString().trim())
        .whereType<String>()
        .where((e) => e.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

OFFProductNutrimentsDTO? _nutrimentsFromJson(dynamic value) {
  final map = offMapFromJson(value);
  return map == null ? null : OFFProductNutrimentsDTO.fromJson(map);
}

@JsonSerializable()
class OFFProductDTO {
  final String? code;
  final String? product_name;
  final String? product_name_en;
  final String? product_name_fr;
  final String? product_name_de;
  // OFF carries product names in many languages — these are the other
  // locales SupportedLanguage names (cs / it / sk / tr / uk / hu / es). Each
  // must also be requested in OFFConst's field lists, or OFF never sends
  // it. When the user's language is missing or blank for a particular
  // product, getLocaleName falls back as its comment describes.
  final String? product_name_cs;
  final String? product_name_it;
  final String? product_name_sk;
  final String? product_name_tr;
  final String? product_name_uk;
  final String? product_name_hu;
  final String? product_name_es;

  // Search-a-licious returns brands as a list, the v2 product endpoint as a
  // comma-separated string; normalise both to a single display string.
  @JsonKey(fromJson: _brandsFromJson)
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
  // OFF-normalised unit of serving_quantity ('g' or 'ml'). Preferred
  // source for the product's entry unit; only the v2 product endpoint
  // carries it (absent from the Search-a-licious projection).
  final String? serving_quantity_unit;

  // Open Food Facts' precomputed ranking key (a composite of scan popularity,
  // data completeness and quality). Higher is better; null/absent for sparse
  // or never-scanned products. Used to re-rank text-search results so popular,
  // well-maintained products surface first. Only present on Search-a-licious
  // results — the v2 barcode endpoint omits it, which is fine (single product).
  @JsonKey(fromJson: offNumFromJson)
  final num? popularity_key;

  // Open Food Facts country tags (e.g. `en:united-kingdom`). Used to softly
  // boost products sold in the user's country up the search ranking. Only
  // present on Search-a-licious results.
  @JsonKey(fromJson: offStringListFromJson)
  final List<String>? countries_tags;

  // A null or non-object `nutriments` reads as absent.
  @JsonKey(fromJson: _nutrimentsFromJson)
  final OFFProductNutrimentsDTO? nutriments;

  /// The product's name for [supportedLanguage], or the best stand-in.
  ///
  /// The order: the name in that language; then [knownName], the name the
  /// meal already carries (what a Recent entry or favourite was logged
  /// with, or what the search hit showed), so hydrating it doesn't swap
  /// that name for another language's; then a name in another language
  /// the app ships, English first; then OFF's `product_name`; then French.
  ///
  /// `product_name` comes that late because it is the name in the
  /// product's main language, which can be one the app doesn't offer: a
  /// Kaufland bread with a German name has a Romanian `product_name`, and
  /// an English UI showed that (#1475). Polish and Chinese have no
  /// requested field of their own, so for them `product_name` is the
  /// name in their language, as before.
  String? getLocaleName(
    SupportedLanguage supportedLanguage, {
    String? knownName,
  }) {
    final String? localeName = switch (supportedLanguage) {
      SupportedLanguage.pl || SupportedLanguage.zh => product_name,
      _ => _nameIn(supportedLanguage),
    };
    if (_present(localeName)) return localeName;
    if (_present(knownName)) return knownName;
    for (final language in SupportedLanguage.values) {
      final name = _nameIn(language);
      if (_present(name)) return name;
    }
    if (_present(product_name)) return product_name;
    if (_present(product_name_fr)) return product_name_fr;
    return null;
  }

  /// The `product_name_<language>` field, or null for a language OFF is
  /// not asked to name products in (Polish, Chinese).
  String? _nameIn(SupportedLanguage language) => switch (language) {
    SupportedLanguage.en => product_name_en,
    SupportedLanguage.de => product_name_de,
    SupportedLanguage.cs => product_name_cs,
    SupportedLanguage.it => product_name_it,
    SupportedLanguage.sk => product_name_sk,
    SupportedLanguage.tr => product_name_tr,
    SupportedLanguage.uk => product_name_uk,
    SupportedLanguage.hu => product_name_hu,
    SupportedLanguage.es => product_name_es,
    SupportedLanguage.pl || SupportedLanguage.zh => null,
  };

  static bool _present(String? name) => name != null && name.isNotEmpty;

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
    this.product_name_hu,
    this.product_name_es,
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
    this.serving_quantity_unit,
    required this.nutriments,
    this.popularity_key,
    this.countries_tags,
  });

  factory OFFProductDTO.fromJson(Map<String, dynamic> json) =>
      _$OFFProductDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OFFProductDTOToJson(this);
}
