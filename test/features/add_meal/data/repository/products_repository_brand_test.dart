import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';

/// Answers from Open Food Facts' Search-a-licious recorded on 2026-10-19
/// (`test/fixtures/off_search/`); any other query finds nothing.
class _RecordedOffDataSource extends OFFDataSource {
  static const _recorded = {
    'Paradiso Mango-Maracuja': 'Paradiso_Mango-Maracuja.json',
    'Mango-Maracuja brands_tags:paradiso':
        'Mango-Maracuja_brands_tags_paradiso.json',
  };

  final asked = <String>[];

  @override
  Future<OFFWordResponseDTO> fetchSearchWordResults(String searchString) async {
    asked.add(searchString);
    final file = _recorded[searchString];
    if (file == null) {
      return OFFWordResponseDTO(
        count: 0,
        page: 1,
        page_count: 0,
        page_size: 0,
        products: const [],
      );
    }
    return OFFWordResponseDTO.fromJson(
      jsonDecode(File('test/fixtures/off_search/$file').readAsStringSync())
          as Map<String, dynamic>,
    );
  }
}

void main() {
  test('"Paradiso Mango-Maracuja" finds the Penny nectar 28410768 in the top '
      'three (#41)', () async {
    final off = _RecordedOffDataSource();
    final repository = ProductsRepository(
      off,
      SpFoodDataSource(),
      countryTag: () async => 'en:germany',
    );

    final results = await repository.getOFFProductsByString(
      'Paradiso Mango-Maracuja',
    );

    expect(results.take(3).map((m) => m.code), contains('28410768'));
    expect(off.asked.first, 'Mango-Maracuja brands_tags:paradiso');
  });

  test('without brand hits the plain query is searched', () async {
    final off = _RecordedOffDataSource();
    final repository = ProductsRepository(
      off,
      SpFoodDataSource(),
      countryTag: () async => 'en:germany',
    );

    await repository.getOFFProductsByString('Milbona Mango-Maracuja');

    expect(off.asked, [
      'Mango-Maracuja brands_tags:milbona',
      'Milbona Mango-Maracuja',
    ]);
  });

  test('a query without a brand is searched once, as typed', () async {
    final off = _RecordedOffDataSource();
    final repository = ProductsRepository(
      off,
      SpFoodDataSource(),
      countryTag: () async => 'en:germany',
    );

    await repository.getOFFProductsByString('Mango Nektar');

    expect(off.asked, ['Mango Nektar']);
  });

  test(
    'brand hits without nutrition values fall back to the plain query',
    () async {
      final off = _NoNutrimentsForBrandDataSource();
      final repository = ProductsRepository(
        off,
        SpFoodDataSource(),
        countryTag: () async => 'en:germany',
      );

      final results = await repository.getOFFProductsByString(
        'Paradiso Mango-Maracuja',
      );

      expect(off.asked, [
        'Mango-Maracuja brands_tags:paradiso',
        'Paradiso Mango-Maracuja',
      ]);
      expect(results, isNotEmpty);
    },
  );
}

/// The brand query answers with products that carry no nutrition values.
class _NoNutrimentsForBrandDataSource extends _RecordedOffDataSource {
  @override
  Future<OFFWordResponseDTO> fetchSearchWordResults(String searchString) async {
    if (!searchString.contains('brands_tags')) {
      return super.fetchSearchWordResults(searchString);
    }
    asked.add(searchString);
    final json =
        jsonDecode(
              File(
                'test/fixtures/off_search/'
                'Mango-Maracuja_brands_tags_paradiso.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    for (final product in json['hits'] as List) {
      (product as Map<String, dynamic>)['nutriments'] = null;
    }
    return OFFWordResponseDTO.fromJson(json);
  }
}
