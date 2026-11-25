import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/data/offline_food_db/sqlite_food_rpc_client.dart';
import 'package:sqlite3/sqlite3.dart';

import 'fixture_db.dart';

/// The columns `food_summary` has, in its order — what Postgres returns for
/// `setof food_summary`.
const _summaryKeys = [
  'food_id', 'source', 'source_code', 'name', 'short_title', 'brands', //
  'barcode', 'category', 'serving_quantity', 'serving_unit',
  'serving_size', 'serving_gram_weight', 'thumbnail_url', 'main_image_url',
  'tags', 'energy_kcal_100', 'carbohydrates_100', 'fat_100', 'proteins_100',
  'sugars_100', 'saturated_fat_100', 'fiber_100', 'monounsaturated_fat_100',
  'polyunsaturated_fat_100', 'trans_fat_100', 'cholesterol_100',
  'sodium_100', 'potassium_100', 'magnesium_100', 'calcium_100', 'iron_100',
  'zinc_100', 'phosphorus_100', 'vitamin_a_100', 'vitamin_c_100',
  'vitamin_d_100', 'vitamin_b6_100', 'vitamin_b12_100', 'niacin_100',
  'has_portion',
];

void main() {
  late Directory dir;
  late Database db;
  late SqliteFoodRpcClient client;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('offline_food_db_rpc');
    db = openFixture(dir);
    client = SqliteFoodRpcClient(db);
  });

  tearDownAll(() {
    db.close();
    dir.deleteSync(recursive: true);
  });

  Future<List<Map<String, dynamic>>> call(
    String fn,
    Map<String, dynamic> params,
  ) => client.rpc(fn, params);

  Future<List<int>> searchIds(
    String term, {
    List<String>? sources,
    int? maxRows = 100,
  }) async => [
    for (final row in await call(SPConst.searchFoodSummaryFn, {
      'term': term,
      'sources': sources,
      'max_rows': maxRows,
    }))
      row['food_id'] as int,
  ];

  test('FTS5 is available in the bundled SQLite', () {
    expect(
      db.select("select 1 from food_fts where food_fts match 'potato'"),
      isNotEmpty,
    );
  });

  group('search_food_summary', () {
    test('orders by portion, exact title, length, then id', () async {
      expect(await searchIds('potato'), [
        1001, // Potato, NFS — portion, title "potato", 11 chars
        1002, // Potato, baked, peel eaten — portion, title, 25
        1007, // Sweet potato, NFS — portion, another title, 17
        1004, // Beef stew with potatoes — portion, another title, 23
        1006, // Potato — no portion, title, 6
        1005, // Potatoes, raw — no portion, 13
        1003, // Potatoes, mashed, NS as to form — no portion, 31
      ]);
      // lower(btrim(term)) for the title comparison.
      expect(await searchIds('  Potato '), await searchIds('potato'));
    });

    test('caps at max_rows like `limit greatest(max_rows, 0)`', () async {
      expect(await searchIds('potato', maxRows: 2), [1001, 1002]);
      expect(await searchIds('potato', maxRows: -1), isEmpty);
      expect(await searchIds('potato', maxRows: null), isEmpty);
      final rows = await call(SPConst.searchFoodSummaryFn, {'term': 'potato'});
      expect(rows, hasLength(7), reason: 'max_rows defaults to 100');
    });

    test('filters by source', () async {
      expect(await searchIds('potato', sources: ['fdc_sr_legacy']), [
        1006,
        1005,
      ]);
      expect(await searchIds('apple'), [1009, 50000002, 50000003]);
      expect(await searchIds('apple', sources: ['fineli']), [
        50000002,
        50000003,
      ]);
      expect(await searchIds('apple', sources: []), isEmpty);
    });

    test('reads websearch syntax', () async {
      expect(await searchIds('apple -juice'), [1009, 50000002]);
      expect(await searchIds('hummus or juice'), [50000003, 1008]);
      expect(await searchIds('"rye bread"'), [50000001]);
      expect(await searchIds('bread rye'), [50000001]);
      expect(await searchIds('"bread rye"'), isEmpty);
      expect(await searchIds('the'), isEmpty, reason: 'only a stopword');
      expect(await searchIds('the apple'), [1009, 50000002, 50000003]);
      expect(await searchIds('"'), isEmpty);
      expect(await searchIds('AND OR NOT ('), isEmpty);
    });

    test('rows are the view\'s and SpFoodDTO reads them', () async {
      final rows = await call(SPConst.searchFoodSummaryFn, {'term': 'potato'});
      expect(rows.first.keys, _summaryKeys);
      final first = rows.first;
      expect(first['has_portion'], isA<bool>());
      expect(first['energy_kcal_100'], isA<int>()); // 77, as JSON sends it
      expect(first['proteins_100'], isA<double>()); // 2.05
      final dto = SpFoodDTO.fromJson(first);
      expect(dto.foodId, 1001);
      expect(dto.name, 'Potato, NFS');
      expect(dto.shortTitle, 'Potato');
      expect(dto.category, 'White potatoes');
      expect(dto.servingSize, '1 cup');
      expect(dto.servingUnit, 'portion');
      expect(dto.servingGramWeight, 150.0);
      expect(dto.energyKcal100, 77.0);
      expect(dto.sugars100, isNull);
      expect(dto.tags, isNull);
      expect(dto.hasPortion, isTrue);
      for (final row in rows) {
        expect(() => SpFoodDTO.fromJson(row), returnsNormally);
      }
    });
  });

  group('food_summary_by_ids', () {
    test('returns the requested foods in the requested sources', () async {
      final rows = await call(SPConst.foodSummaryByIdsFn, {
        'ids': [50000003, 1001, 424242],
        'sources': null,
      });
      expect(rows.map((r) => r['food_id']), [1001, 50000003]);
      expect(rows.first.keys, _summaryKeys);
      final fineli = await call(SPConst.foodSummaryByIdsFn, {
        'ids': [50000003, 1001],
        'sources': ['fineli'],
      });
      expect(fineli.map((r) => r['food_id']), [50000003]);
    });

    test('keeps the view\'s serving derivations', () async {
      final rows = await call(SPConst.foodSummaryByIdsFn, {
        'ids': [1003, 1004, 1005, 1008],
      });
      final byId = {for (final r in rows) r['food_id']: SpFoodDTO.fromJson(r)};
      // SR Legacy: "<amount> <modifier>", amount as Postgres prints it.
      expect(byId[1005]!.servingSize, '1.0 medium');
      expect(byId[1005]!.hasPortion, isFalse);
      // A real unit, nothing to describe it.
      expect(byId[1008]!.servingUnit, 'tablespoon');
      expect(byId[1008]!.servingQuantity, 2.0);
      expect(byId[1008]!.servingSize, isNull);
      expect(byId[1008]!.magnesium100, 71.1);
      // coalesce(short_title, description): NULL falls back, '' does not.
      expect(byId[1003]!.shortTitle, 'Potatoes, mashed, NS as to form');
      expect(byId[1004]!.shortTitle, '');
    });
  });

  group('search_food_translation', () {
    test('matches the locale and orders like the English search', () async {
      final rows = await call(SPConst.searchFoodTranslationFn, {
        'term': 'kartoffel',
        'loc': 'de',
        'max_rows': 100,
      });
      expect(rows, [
        {
          'food_id': 1001,
          'description': 'Kartoffel, NFS',
          'source': 'machine',
          'has_portion': true,
        },
        {
          'food_id': 1006,
          'description': 'Kartoffel',
          'source': 'machine',
          'has_portion': false,
        },
      ]);
    });

    test('is per locale and unstemmed', () async {
      Future<List<Object?>> ids(String term, String loc) async => [
        for (final r in await call(SPConst.searchFoodTranslationFn, {
          'term': term,
          'loc': loc,
        }))
          r['food_id'],
      ];
      expect(await ids('äpple', 'sv'), [50000002]);
      expect(await ids('omena', 'fi'), [50000002]);
      expect(await ids('omena', 'sv'), isEmpty);
      expect(await ids('kartoffeln', 'de'), [1004]);
      // Known difference from Postgres ('simple' keeps diacritics): FTS5
      // folds them, so "apple" finds "Äpple".
      expect(await ids('apple', 'sv'), [50000002]);
    });
  });

  group('portions_by_food_ids', () {
    test('numbers deliverable portions and localizes verified ones', () async {
      final rows = await call(SPConst.portionsByFoodIdsFn, {
        'ids': [50000001, 1007, 1003, 1001],
        'loc': 'de',
      });
      expect(rows, [
        {
          'food_id': 1001,
          'seq': 1,
          'label': '1 Tasse',
          'localized': true,
          'gram_weight': 150.0,
          'label_en': '1 cup',
        },
        {
          'food_id': 1007,
          'seq': 1,
          'label': '1 Tasse',
          'localized': true,
          'gram_weight': 200,
          'label_en': '1 cup',
        },
        {
          'food_id': 1007,
          'seq': 2,
          'label': '1 großes',
          'localized': true,
          'gram_weight': 180,
          'label_en': '1 large',
        },
        // The reviewer deleted "1 slice": the English text, not localized.
        {
          'food_id': 50000001,
          'seq': 1,
          'label': '1 slice',
          'localized': false,
          'gram_weight': 30.0,
          'label_en': '1 slice',
        },
        {
          'food_id': 50000001,
          'seq': 2,
          'label': '1 Stück',
          'localized': true,
          'gram_weight': 45.0,
          'label_en': '1 piece',
        },
      ]);
    });

    test('drops yields/NFS rows and shows only verified text', () async {
      final english = await call(SPConst.portionsByFoodIdsFn, {
        'ids': [1009],
        'loc': 'en',
      });
      expect(english.map((r) => (r['seq'], r['label'], r['localized'])), [
        (1, '1 medium', false),
      ]);
      // Polish has machine translations only.
      final polish = await call(SPConst.portionsByFoodIdsFn, {
        'ids': [1001, 1007],
        'loc': 'pl',
      });
      expect(polish.every((r) => r['localized'] == false), isTrue);
    });
  });

  group('portion_labels_by_food_ids', () {
    test('labels the default portion where a verified one exists', () async {
      final rows = await call(SPConst.portionLabelsByFoodIdsFn, {
        'ids': [1002, 1001, 1003, 1006, 50000001, 424242],
        'loc': 'de',
      });
      expect(rows, [
        {'food_id': 1002, 'label': '1 mittelgroßes'},
        {'food_id': 1001, 'label': '1 Tasse'},
      ]);
      expect(
        await call(SPConst.portionLabelsByFoodIdsFn, {
          'ids': [1001],
          'loc': 'pl',
        }),
        isEmpty,
      );
    });
  });

  test('an unknown function is refused', () {
    expect(
      () => client.query('drop_everything', const {}),
      throwsUnsupportedError,
    );
  });

  group('websearchToFts5', () {
    test('mirrors websearch_to_tsquery', () {
      String? f(String? term, {bool english = true}) =>
          websearchToFts5(term, english: english);
      expect(f('apple'), '(("apple"))');
      expect(f('a "b c" -d or e'), '(("b c") NOT "d") OR (("e"))');
      expect(
        f('apple -pie or "with skin"'),
        '(("apple") NOT "pie") OR (("skin"))',
      );
      expect(f('low-fat milk'), '(("low fat" AND "milk"))');
      expect(f('mango/papaya', english: false), '(("mango/papaya"))');
      expect(f('-cheese'), isNull);
      expect(f('the of'), isNull);
      expect(f('the of', english: false), '(("the" AND "of"))');
      expect(f(null), isNull);
    });

    test('pgBtrimLower trims spaces only', () {
      expect(pgBtrimLower('  Potato '), 'potato');
      expect(pgBtrimLower('\tPotato'), '\tpotato');
    });
  });
}
