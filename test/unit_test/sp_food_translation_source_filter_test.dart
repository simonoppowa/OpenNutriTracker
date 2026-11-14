import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/hive_test_setup.dart';

/// A food in the fake backend: its `food_summary` row, plus — when it has a
/// German name — the `search_food_translation` row that names it.
class _Food {
  const _Food(
    this.id,
    this.source,
    this.englishName, {
    this.germanName,
    this.hasPortion = false,
  });

  final int id;
  final String source;
  final String englishName;
  final String? germanName;
  final bool hasPortion;

  Map<String, dynamic> get summary => {
    SPConst.foodId: id,
    SPConst.foodSource: source,
    'name': englishName,
    'has_portion': hasPortion,
  };

  Map<String, dynamic> get translation => {
    SPConst.translationFoodId: id,
    SPConst.translationDescription: germanName,
    SPConst.translationSource: 'native',
    SPConst.translationHasPortion: hasPortion,
  };
}

/// Answers the three search RPCs the way the backend does, and records each
/// call. `search_food_translation` takes no source filter (food_translation
/// has no source column); the other two apply `sources` when it is non-null.
class _FakeBackend extends http.BaseClient {
  _FakeBackend(this.foods, {this.failSummaryByIds = false});

  final List<_Food> foods;
  final bool failSummaryByIds;
  final calls = <({String fn, Map<String, dynamic> body})>[];

  bool _allowed(_Food food, Object? sources) =>
      sources == null || (sources as List).contains(food.source);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final req = request as http.Request;
    final fn = req.url.pathSegments.last;
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    calls.add((fn: fn, body: body));

    final Object answer;
    var status = 200;
    switch (fn) {
      case SPConst.searchFoodTranslationFn:
        answer = [
          for (final food in foods)
            if (food.germanName != null) food.translation,
        ].take(body['max_rows'] as int).toList();
      case SPConst.foodSummaryByIdsFn:
        if (failSummaryByIds) {
          status = 503;
          answer = {'message': 'food_summary_by_ids: unavailable'};
        } else {
          final ids = (body['ids'] as List).cast<int>().toSet();
          answer = [
            for (final food in foods)
              if (ids.contains(food.id) && _allowed(food, body['sources']))
                food.summary,
          ];
        }
      case SPConst.searchFoodSummaryFn:
        final term = (body['term'] as String).toLowerCase();
        answer = [
          for (final food in foods)
            if (food.englishName.toLowerCase().contains(term) &&
                _allowed(food, body['sources']))
              food.summary,
        ];
      default:
        status = 404;
        answer = {'message': 'unknown function $fn'};
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(answer))),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
      request: request,
    );
  }

  List<String> get functions => [for (final call in calls) call.fn];
}

class _TestHiveDBProvider extends HiveDBProvider {
  final Box<ConfigDBO> shared;
  final Box<ConfigDBO> profile;
  _TestHiveDBProvider(this.shared, this.profile);

  @override
  Box<ConfigDBO> get appConfigBox => shared;

  @override
  Box<ConfigDBO> get configBox => profile;
}

const _fdcSources = [
  'fdc_foundation',
  'fdc_sr_legacy',
  'fdc_survey',
  'fdc_branded',
];

/// The BLS record a German reader means by "Kaffee". BLS carries no
/// deliverable portion, so on the resolver's page it takes
/// `noPortionsPenalty` and scores 0.85.
const _blsCoffee = _Food(
  1000,
  'bls',
  'Coffee, brewed',
  germanName: 'Kaffee',
  hasPortion: false,
);

/// Twenty-five FDC records titled "Kaffee", each with a portion, so each
/// scores 1.0 on the resolver's page and outranks [_blsCoffee]. They come
/// first in the backend's order, as portion-bearing rows do.
final _fdcCoffees = [
  for (var i = 0; i < 25; i++)
    _Food(
      i + 1,
      _fdcSources[i % _fdcSources.length],
      'Coffee, variant $i',
      germanName: 'Kaffee, Variante $i',
      hasPortion: true,
    ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<ConfigDBO> appConfigBox;
  late Box<ConfigDBO> profileConfigBox;
  late ConfigDataSource config;

  setUp(() async {
    Hive.init('.');
    registerHiveAdaptersOnce();
    final tag = DateTime.now().microsecondsSinceEpoch;
    appConfigBox = await Hive.openBox<ConfigDBO>('sp_source_app_$tag');
    profileConfigBox = await Hive.openBox<ConfigDBO>('sp_source_cfg_$tag');
    if (locator.isRegistered<ConfigDataSource>()) {
      locator.unregister<ConfigDataSource>();
    }
    config = ConfigDataSource(
      _TestHiveDBProvider(appConfigBox, profileConfigBox),
    );
    locator.registerSingleton<ConfigDataSource>(config);
    AppLocale.select('de');
  });

  tearDown(() async {
    AppLocale.reset();
    if (locator.isRegistered<SupabaseClient>()) {
      locator.unregister<SupabaseClient>();
    }
    locator.unregister<ConfigDataSource>();
    await Hive.deleteFromDisk();
  });

  _FakeBackend serve(List<_Food> foods, {bool failSummaryByIds = false}) {
    final backend = _FakeBackend(foods, failSummaryByIds: failSummaryByIds);
    if (locator.isRegistered<SupabaseClient>()) {
      locator.unregister<SupabaseClient>();
    }
    locator.registerSingleton<SupabaseClient>(
      SupabaseClient('http://backend.invalid', 'test-key', httpClient: backend),
    );
    return backend;
  }

  Future<void> disable(Iterable<String> sources) =>
      config.setConfigFoodSourceToggles({for (final s in sources) s: false});

  group('translated search with a source turned off (#1272)', () {
    test(
      'FDC off: the resolver keeps the BLS match FDC rows outrank',
      () async {
        // The issue's case. Twenty-five portion-bearing FDC rows beat the
        // penalised BLS row in the cut; before the fix the cut ran first, the
        // twenty survivors were all FDC, the source filter then removed every
        // one, and the English fallback — "Kaffee" matches no English name —
        // found nothing.
        final backend = serve([..._fdcCoffees, _blsCoffee]);
        await disable(_fdcSources);

        final results = await SpFoodDataSource().fetchSearchWordResults(
          'Kaffee',
          forResolution: true,
        );

        expect(results.map((r) => r.foodId), [_blsCoffee.id]);
        expect(results.single.localizedName, 'Kaffee');
        expect(results.single.source, 'bls');
        expect(backend.functions, isNot(contains(SPConst.searchFoodSummaryFn)));
      },
    );

    test('FDC off: the Food tab keeps the BLS match too', () async {
      serve([..._fdcCoffees, _blsCoffee]);
      await disable(_fdcSources);

      final results = await SpFoodDataSource().fetchSearchWordResults('Kaffee');

      expect(results.map((r) => r.foodId), [_blsCoffee.id]);
    });

    test('FDC off: the twenty are cut from enabled sources only', () async {
      // More enabled rows than the page holds: the page is full, and only
      // with rows the user allows.
      final blsMany = [
        for (var i = 0; i < 30; i++)
          _Food(
            2000 + i,
            'bls',
            'Coffee drink $i',
            germanName: 'Kaffee, Getränk $i',
          ),
      ];
      serve([..._fdcCoffees, ...blsMany]);
      await disable(_fdcSources);

      final results = await SpFoodDataSource().fetchSearchWordResults(
        'Kaffee',
        forResolution: true,
      );

      expect(results, hasLength(SPConst.maxNumberOfItems));
      expect(results.map((r) => r.source).toSet(), {'bls'});
    });

    test(
      'BLS off: FDC rows still fill the page, without the BLS row',
      () async {
        serve([..._fdcCoffees, _blsCoffee]);
        await disable(['bls']);

        final results = await SpFoodDataSource().fetchSearchWordResults(
          'Kaffee',
          forResolution: true,
        );

        expect(results, hasLength(SPConst.maxNumberOfItems));
        expect(results.map((r) => r.foodId), isNot(contains(_blsCoffee.id)));
        expect(
          results.every((r) => _fdcSources.contains(r.source)),
          isTrue,
          reason: '${results.map((r) => r.source)}',
        );
      },
    );

    test(
      'every enabled source: unchanged — one summary fetch for the twenty',
      () async {
        // No filter to apply, so nothing is fetched early: the page is cut
        // from the whole pool and only its twenty ids are asked for, as
        // before. Under the penalty the portion-bearing FDC rows win, which
        // is the resolver's existing rule and not what #1272 is about.
        final backend = serve([..._fdcCoffees, _blsCoffee]);

        final results = await SpFoodDataSource().fetchSearchWordResults(
          'Kaffee',
          forResolution: true,
        );

        expect(results, hasLength(SPConst.maxNumberOfItems));
        expect(results.map((r) => r.foodId), isNot(contains(_blsCoffee.id)));
        final summaryCalls = [
          for (final call in backend.calls)
            if (call.fn == SPConst.foodSummaryByIdsFn) call.body,
        ];
        expect(summaryCalls, hasLength(1));
        expect(summaryCalls.single['ids'], hasLength(SPConst.maxNumberOfItems));
        expect(summaryCalls.single['sources'], isNull);
      },
    );

    test('every source off: no request, no results', () async {
      final backend = serve([..._fdcCoffees, _blsCoffee]);
      await disable(SPConst.foodSourceDisplayNames.keys);

      final results = await SpFoodDataSource().fetchSearchWordResults(
        'Kaffee',
        forResolution: true,
      );

      expect(results, isEmpty);
      expect(backend.calls, isEmpty);
    });

    test(
      'no enabled source in the pool: falls through to the English search',
      () async {
        // Only FDC rows match the German term and FDC is off: the localized
        // answer is empty, so the English search is asked, with the filter.
        final backend = serve([
          ..._fdcCoffees,
          const _Food(3000, 'bls', 'Kaffee instant'),
        ]);
        await disable(_fdcSources);

        final results = await SpFoodDataSource().fetchSearchWordResults(
          'Kaffee',
          forResolution: true,
        );

        expect(results.map((r) => r.foodId), [3000]);
        final english = backend.calls.lastWhere(
          (c) => c.fn == SPConst.searchFoodSummaryFn,
        );
        expect(english.body['sources'], isNot(contains('fdc_survey')));
        expect(english.body['sources'], contains('bls'));
      },
    );

    test(
      'a summary lookup that fails is an error, not an empty page',
      () async {
        // Read as "no BLS match", a failure would fall through to the English
        // search and hand the resolver a page that silently lacks the record.
        // It surfaces instead, after `withRetry`'s attempts, as before.
        final backend = serve([
          ..._fdcCoffees,
          _blsCoffee,
        ], failSummaryByIds: true);
        await disable(_fdcSources);

        await expectLater(
          SpFoodDataSource().fetchSearchWordResults(
            'Kaffee',
            forResolution: true,
          ),
          throwsA(isA<PostgrestException>()),
        );
        expect(backend.functions, isNot(contains(SPConst.searchFoodSummaryFn)));
      },
    );
  });

  test('English locale with FDC off: the backend filters the search', () async {
    AppLocale.select('en');
    final backend = serve([..._fdcCoffees, _blsCoffee]);
    await disable(_fdcSources);

    final results = await SpFoodDataSource().fetchSearchWordResults(
      'coffee',
      forResolution: true,
    );

    expect(results.map((r) => r.foodId), [_blsCoffee.id]);
    expect(backend.functions, [SPConst.searchFoodSummaryFn]);
  });
}
