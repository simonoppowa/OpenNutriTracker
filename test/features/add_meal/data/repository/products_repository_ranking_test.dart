import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/off_country.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_nutriments_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';

// Builds a plausible product so it survives the consistency filter. The name
// carries the relevance position so assertions can read the final order back.
// [atwaterConsistent] false declares 100 kcal against macros that imply ~33,
// which is physically plausible (passes _keepIfConsistent) but Atwater-
// incoherent (>25% energy gap), so it should be demoted in ranking.
OFFProductDTO _p(
  String name, {
  num? popularity,
  bool atwaterConsistent = true,
  List<String>? countries,
}) =>
    OFFProductDTO(
      code: name,
      product_name: name,
      product_name_en: name,
      product_name_fr: null,
      product_name_de: null,
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
      popularity_key: popularity,
      countries_tags: countries,
      nutriments: atwaterConsistent
          ? OFFProductNutrimentsDTO(
              energy_kcal_100g: 100,
              carbohydrates_100g: 10,
              fat_100g: 5,
              proteins_100g: 5,
              sugars_100g: 2,
              saturated_fat_100g: 1,
              fiber_100g: 1,
            )
          : OFFProductNutrimentsDTO(
              energy_kcal_100g: 100, // declared, but macros imply ~33 kcal
              carbohydrates_100g: 5,
              fat_100g: 1,
              proteins_100g: 1,
              sugars_100g: 1,
              saturated_fat_100g: 0,
              fiber_100g: 0,
            ),
    );

class _FakeOffDataSource extends OFFDataSource {
  final OFFWordResponseDTO response;
  _FakeOffDataSource(this.response);
  @override
  Future<OFFWordResponseDTO> fetchSearchWordResults(String searchString) async =>
      response;
}

ProductsRepository _repoReturning(List<OFFProductDTO> productsInRelevanceOrder) {
  final response = OFFWordResponseDTO(
    count: productsInRelevanceOrder.length,
    page: 1,
    page_count: 1,
    page_size: productsInRelevanceOrder.length,
    products: productsInRelevanceOrder,
  );
  return ProductsRepository(
    _FakeOffDataSource(response),
    FDCDataSource(),
    SpFoodDataSource(),
  );
}

void main() {
  group('ProductsRepository OFF search ranking (relevance + popularity fusion)',
      () {
    test(
        'a popular product ranked low by relevance floats above a more-relevant '
        'but unpopular one', () async {
      final repo = _repoReturning([
        _p('rel0-unpopular', popularity: 0),
        _p('rel1-mid', popularity: 1000),
        _p('rel2-unpopular', popularity: 0),
        _p('rel3-very-popular', popularity: 5000),
      ]);

      final result = await repo.getOFFProductsByString('q');
      final names = result.map((m) => m.name).toList();

      expect(names, contains('rel3-very-popular'));
      expect(
        names.indexOf('rel3-very-popular'),
        lessThan(names.indexOf('rel2-unpopular')),
        reason: 'popularity should lift the popular item above a more-relevant '
            'but unpopular one',
      );
    });

    test('a strong relevance match is not buried by popularity alone', () async {
      final repo = _repoReturning([
        _p('top-relevance', popularity: 0),
        _p('popular-1', popularity: 9000),
        _p('popular-2', popularity: 8000),
      ]);

      final result = await repo.getOFFProductsByString('q');
      final names = result.map((m) => m.name).toList();
      // The exact top-relevance hit stays near the top rather than sinking
      // below every popular item (the failure mode of a hard popularity sort).
      expect(names.indexOf('top-relevance'), lessThan(2));
    });

    test('null popularity_key (sparse entries) sinks below scanned products',
        () async {
      final repo = _repoReturning([
        _p('sparse-a'), // null popularity
        _p('sparse-b'), // null popularity
        _p('scanned', popularity: 4000),
      ]);

      final result = await repo.getOFFProductsByString('q');
      expect(
        result.map((m) => m.name).toList().indexOf('scanned'),
        lessThan(2),
        reason: 'a scanned/popular entry should not sit below both sparse ones',
      );
    });

    test(
        'an Atwater-incoherent product is demoted below coherent ones even '
        'when it is popular and highly relevant', () async {
      final repo = _repoReturning([
        _p('incoherent-but-popular', popularity: 9000, atwaterConsistent: false),
        _p('coherent-a', popularity: 10),
        _p('coherent-b', popularity: 5),
      ]);

      final result = await repo.getOFFProductsByString('q');
      final names = result.map((m) => m.name).toList();

      // Despite top relevance and the highest popularity, the incoherent entry
      // sinks to the bottom because its declared kcal doesn't match its macros.
      expect(names.last, 'incoherent-but-popular');
      expect(names.indexOf('coherent-a'),
          lessThan(names.indexOf('incoherent-but-popular')));
    });

    test('result list is trimmed to the display limit', () async {
      final many = List.generate(60, (i) => _p('item$i', popularity: i));
      final repo = _repoReturning(many);

      final result = await repo.getOFFProductsByString('q');
      expect(result.length, lessThanOrEqualTo(25));
    });

    // The repository derives the user's country from Platform.localeName; these
    // tests tag the "local" product with whatever that resolves to so they
    // exercise the real boost path on any host whose locale carries a mapped
    // country (the typical dev/CI case).
    final userTag = OffCountry.fromLocale(Platform.localeName);

    test('a product sold in the user country is softly boosted above a '
        'comparable non-local one', () async {
      if (userTag == null) return; // host locale has no mappable country
      final repo = _repoReturning([
        _p('non-local', popularity: 100),
        _p('local', popularity: 100, countries: [userTag]),
      ]);

      final result = await repo.getOFFProductsByString('q');
      final names = result.map((m) => m.name).toList();
      expect(names.indexOf('local'), lessThan(names.indexOf('non-local')));
    });

    test('the country boost is soft: a clearly dominant global product still '
        'outranks a weak local one', () async {
      if (userTag == null) return;
      final items = <OFFProductDTO>[
        _p('global-strong', popularity: 1000000000),
        ...List.generate(30, (i) => _p('filler$i', popularity: 500 - i)),
        _p('local-weak', popularity: 1, countries: [userTag]),
      ];
      final repo = _repoReturning(items);

      final result = await repo.getOFFProductsByString('q');
      expect(result.first.name, 'global-strong');
    });
  });
}
