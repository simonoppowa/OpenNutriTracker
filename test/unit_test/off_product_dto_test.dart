// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_nutriments_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';

void main() {
  group('OFFProductDTO getLocaleName', () {
    test('Case 1: English Language - Valid Name', () {
      final product = OFFProductDTO(
        code: '123 - testValue',
        product_name: 'Name - testValue',
        product_name_en: 'English Name - testValue',
        product_name_fr: 'Nom Français - testValue',
        product_name_de: 'Deutscher Name - testValue',
        brands: 'Brand - testValue',
        image_front_thumb_url: 'thumb - testValue',
        image_front_url: 'front - testValue',
        image_ingredients_url: 'ingredients - testValue',
        image_nutrition_url: 'nutrition - testValue',
        image_url: 'image - testValue',
        url: 'url - testValue',
        quantity: '100g - testValue',
        product_quantity: '100 - testValue',
        serving_quantity: '50 - testValue',
        serving_size: '50g - testValue',
        nutriments: OFFProductNutrimentsDTO(
          energy_kcal_100g: 1,
          carbohydrates_100g: 1,
          fat_100g: 1,
          proteins_100g: 1,
          sugars_100g: 1,
          saturated_fat_100g: 1,
          fiber_100g: 1,
        ),
      );

      final result = product.getLocaleName(SupportedLanguage.en);

      expect(result, equals('English Name - testValue'));
    });

    test('Case 2: Deutscher Language - Valid Name', () {
      final product = OFFProductDTO(
        code: '123 - testValue',
        product_name: 'Default Name - testValue',
        product_name_en: 'English Name - testValue',
        product_name_fr: 'Nom Français - testValue',
        product_name_de: 'Deutscher Name - testValue',
        brands: 'Brand - testValue',
        image_front_thumb_url: 'thumb - testValue',
        image_front_url: 'front - testValue',
        image_ingredients_url: 'ingredients - testValue',
        image_nutrition_url: 'nutrition - testValue',
        image_url: 'image - testValue',
        url: 'url - testValue',
        quantity: '100g - testValue',
        product_quantity: '100 - testValue',
        serving_quantity: '50 - testValue',
        serving_size: '50g - testValue',
        nutriments: OFFProductNutrimentsDTO(
          energy_kcal_100g: 1,
          carbohydrates_100g: 1,
          fat_100g: 1,
          proteins_100g: 1,
          sugars_100g: 1,
          saturated_fat_100g: 1,
          fiber_100g: 1
        ),
      );

      final result = product.getLocaleName(SupportedLanguage.de);

      expect(result, equals('Deutscher Name - testValue'));
    });

    test('Case 3: English Language - Null Name', () {
      final product = _buildProduct(
        product_name: 'Default Name - testValue',
        product_name_en: null,
        product_name_fr: 'Nom Français - testValue',
        product_name_de: 'Deutscher Name - testValue',
      );

      final result = product.getLocaleName(SupportedLanguage.en);

      expect(result, equals('Default Name - testValue'));
    });

    test('Case 4: English Language - Empty Name', () {
      final product = _buildProduct(
        product_name: 'Default Name - testValue',
        product_name_en: '',
        product_name_fr: 'Nom Français - testValue',
        product_name_de: 'Deutscher Name - testValue',
      );

      final result = product.getLocaleName(SupportedLanguage.en);

      expect(result, equals('Default Name - testValue'));
    });

    test('Case 5: Polish Language - returns product_name', () {
      final product = _buildProduct(
        product_name: 'Default Name - testValue',
        product_name_en: 'English Name - testValue',
        product_name_de: 'Deutscher Name - testValue',
      );

      final result = product.getLocaleName(SupportedLanguage.pl);

      expect(result, equals('Default Name - testValue'));
    });

    test('Case 6: Chinese Language - returns product_name', () {
      final product = _buildProduct(
        product_name: 'Default Name - testValue',
        product_name_en: 'English Name - testValue',
        product_name_de: 'Deutscher Name - testValue',
      );

      final result = product.getLocaleName(SupportedLanguage.zh);

      expect(result, equals('Default Name - testValue'));
    });

    test('Case 7: All names null - returns null', () {
      final product = _buildProduct();

      final result = product.getLocaleName(SupportedLanguage.en);

      expect(result, isNull);
    });

    test('Case 8: English fallback walks chain to product_name_fr', () {
      // product_name_en is null, product_name is null — the implementation's
      // fallback chain `product_name ?? product_name_en ?? product_name_fr ?? product_name_de`
      // should return the French name.
      final product = _buildProduct(
        product_name_fr: 'Nom Français - testValue',
        product_name_de: 'Deutscher Name - testValue',
      );

      final result = product.getLocaleName(SupportedLanguage.en);

      expect(result, equals('Nom Français - testValue'));
    });

    test('Case 9: Czech locale returns product_name_cs when present', () {
      final product = _buildProduct(product_name_cs: 'Český název');
      expect(product.getLocaleName(SupportedLanguage.cs),
          equals('Český název'));
    });

    test('Case 10: Italian locale returns product_name_it when present', () {
      final product = _buildProduct(product_name_it: 'Nome italiano');
      expect(product.getLocaleName(SupportedLanguage.it),
          equals('Nome italiano'));
    });

    test('Case 11: Turkish locale returns product_name_tr when present', () {
      final product = _buildProduct(product_name_tr: 'Türkçe isim');
      expect(product.getLocaleName(SupportedLanguage.tr),
          equals('Türkçe isim'));
    });

    test('Case 12: Ukrainian locale returns product_name_uk when present', () {
      final product = _buildProduct(product_name_uk: 'Українська назва');
      expect(product.getLocaleName(SupportedLanguage.uk),
          equals('Українська назва'));
    });

    test(
        'Case 13: Czech locale falls back through product_name when '
        'product_name_cs is null', () {
      final product = _buildProduct(product_name: 'Default name');
      expect(product.getLocaleName(SupportedLanguage.cs),
          equals('Default name'));
    });
  });

  group('OFFProductDTO.fromJson brands coercion', () {
    test('Search-a-licious returns brands as a list; joined to a string', () {
      final product = OFFProductDTO.fromJson({
        'code': '1',
        'brands': ['Gerber', 'Yogurt Melts'],
      });
      expect(product.brands, 'Gerber, Yogurt Melts');
    });

    test('v2 returns brands as a comma-separated string; kept as-is', () {
      final product = OFFProductDTO.fromJson({
        'code': '1',
        'brands': 'Nutella',
      });
      expect(product.brands, 'Nutella');
    });

    test('null / empty brands normalise to null', () {
      expect(OFFProductDTO.fromJson({'code': '1'}).brands, isNull);
      expect(OFFProductDTO.fromJson({'code': '1', 'brands': ''}).brands, isNull);
      expect(
        OFFProductDTO.fromJson({'code': '1', 'brands': <dynamic>[]}).brands,
        isNull,
      );
    });

    test('blank entries in a brands list are dropped', () {
      final product = OFFProductDTO.fromJson({
        'code': '1',
        'brands': ['', '  ', 'Real'],
      });
      expect(product.brands, 'Real');
    });
  });

  group('OFFWordResponseDTO.fromJson Search-a-licious envelope', () {
    test('maps the hits array onto products and reads page metadata', () {
      final response = OFFWordResponseDTO.fromJson({
        'count': 631,
        'page': 1,
        'page_size': 2,
        'page_count': 316,
        'hits': [
          {'code': '111', 'product_name': 'A', 'brands': ['X']},
          {'code': '222', 'product_name': 'B'},
        ],
      });

      expect(response.products, hasLength(2));
      expect(response.products.first.code, '111');
      expect(response.products.first.brands, 'X');
      expect(response.count, 631);
      expect(response.page_count, 316);
    });
  });

  // #1153: OFF's nutrient id for niacin is `vitamin-pp`, so the API emits
  // `vitamin-pp_100g` and never `niacin_100g`. A missing `@JsonKey` here made
  // every OFF product read niacin as null, silently dropping the value from
  // the daily figure. Locking the mapping in so a future rename doesn't
  // regress it back to nothing.
  group('OFFProductNutrimentsDTO.fromJson niacin mapping', () {
    test('reads niacin from vitamin-pp_100g', () {
      final nutriments = OFFProductNutrimentsDTO.fromJson({
        'vitamin-pp_100g': 12.5,
      });

      expect(nutriments.niacin_100g, 12.5);
    });

    test('leaves niacin null when vitamin-pp_100g is absent', () {
      final nutriments = OFFProductNutrimentsDTO.fromJson(<String, dynamic>{});

      expect(nutriments.niacin_100g, isNull);
    });

    test('does NOT read the historical, absent niacin_100g key', () {
      final nutriments = OFFProductNutrimentsDTO.fromJson({
        'niacin_100g': 99.9,
      });

      expect(nutriments.niacin_100g, isNull);
    });
  });
}

OFFProductDTO _buildProduct({
  String? product_name,
  String? product_name_en,
  String? product_name_fr,
  String? product_name_de,
  String? product_name_cs,
  String? product_name_it,
  String? product_name_tr,
  String? product_name_uk,
}) {
  return OFFProductDTO(
    code: '123',
    product_name: product_name,
    product_name_en: product_name_en,
    product_name_fr: product_name_fr,
    product_name_de: product_name_de,
    product_name_cs: product_name_cs,
    product_name_it: product_name_it,
    product_name_tr: product_name_tr,
    product_name_uk: product_name_uk,
    brands: null,
    image_front_thumb_url: null,
    image_front_url: null,
    image_ingredients_url: null,
    image_nutrition_url: null,
    image_url: null,
    url: null,
    quantity: null,
    product_quantity: null,
    serving_quantity: null,
    serving_size: null,
    nutriments: null,
  );
}
