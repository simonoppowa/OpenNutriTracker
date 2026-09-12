import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';

import '../helpers/hive_test_setup.dart';

MealNutrimentsDBO _emptyNutriments() => MealNutrimentsDBO(
      energyKcal100: null,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    );

MealDBO _meal({
  String? code,
  String? name,
  MealSourceDBO source = MealSourceDBO.off,
  bool? detailed,
}) {
  return MealDBO(
    code: code,
    name: name,
    brands: null,
    thumbnailImageUrl: null,
    mainImageUrl: null,
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    nutriments: _emptyNutriments(),
    source: source,
    detailed: detailed,
  );
}

void main() {
  group('RemoteSearchCacheDataSource', () {
    late Box<MealDBO> cacheBox;
    late Box<int> tsBox;
    late RemoteSearchCacheDataSource ds;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      cacheBox = await Hive.openBox<MealDBO>(
          'remote_cache_test_${DateTime.now().microsecondsSinceEpoch}');
      tsBox = await Hive.openBox<int>(
          'remote_cache_ts_test_${DateTime.now().microsecondsSinceEpoch}');
      ds = RemoteSearchCacheDataSource(cacheBox, tsBox);
    });

    tearDown(() async {
      await cacheBox.deleteFromDisk();
      await tsBox.deleteFromDisk();
    });

    test('cache adds a new meal and stamps a timestamp', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      await ds.cache(_meal(code: 'A', name: 'Apple'));
      final after = DateTime.now().millisecondsSinceEpoch;

      expect(ds.count, equals(1));
      final ts = tsBox.get('A');
      expect(ts, isNotNull);
      expect(ts!, greaterThanOrEqualTo(before));
      expect(ts, lessThanOrEqualTo(after));
    });

    test('cache overwrites an existing entry by code (refresh)', () async {
      await ds.cache(_meal(code: 'A', name: 'Apple v1'));
      await ds.cache(_meal(code: 'A', name: 'Apple v2'));

      expect(ds.count, equals(1));
      expect(ds.getAll().single.name, equals('Apple v2'));
    });

    test('cache treats null-code entries as distinct by name', () async {
      await ds.cache(_meal(code: null, name: 'Apple'));
      await ds.cache(_meal(code: null, name: 'Banana'));
      await ds.cache(_meal(code: null, name: 'Apple')); // dedup

      expect(ds.count, equals(2));
    });

    test('cache uses code as timestamp key when present, else name',
        () async {
      await ds.cache(_meal(code: 'A', name: 'Apple'));
      expect(tsBox.get('A'), isNotNull);
      expect(tsBox.get('Apple'), isNull);

      await ds.cache(_meal(code: null, name: 'Banana'));
      expect(tsBox.get('Banana'), isNotNull);
    });

    test('cache silently skips timestamping when both code and name are null',
        () async {
      await ds.cache(_meal(code: null, name: null));
      expect(ds.count, equals(1));
      expect(tsBox.length, equals(0));
    });

    test('cacheAll touches every entry', () async {
      await ds.cacheAll([
        _meal(code: 'A', name: 'Apple'),
        _meal(code: 'B', name: 'Banana'),
        _meal(code: 'C', name: 'Cherry'),
      ]);

      expect(ds.count, equals(3));
      expect(tsBox.get('A'), isNotNull);
      expect(tsBox.get('B'), isNotNull);
      expect(tsBox.get('C'), isNotNull);
    });

    test(
        'cacheFromSearch preserves existing timestamps but refreshes meal data '
        '(regression: bulk-caching must not wipe touch signal)', () async {
      await ds.cache(_meal(code: 'A', name: 'Apple v1'));
      final originalTs = tsBox.get('A');
      expect(originalTs, isNotNull);

      // Wait long enough that the millisecond clock would change.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await ds.cacheFromSearch([
        _meal(code: 'A', name: 'Apple v2'), // existing → keep ts, refresh data
        _meal(code: 'B', name: 'Banana'),   // new → fresh ts
      ]);

      expect(tsBox.get('A'), equals(originalTs),
          reason: 'existing entry timestamp must be preserved on re-search');
      expect(ds.getAll().firstWhere((m) => m.code == 'A').name,
          equals('Apple v2'),
          reason: 'meal data should still be refreshed even though ts is kept');
      expect(tsBox.get('B'), isNotNull);
    });

    test(
        'cacheFromSearch dedups within a single batch (later duplicate '
        'overwrites earlier rather than producing two rows)', () async {
      await ds.cacheFromSearch([
        _meal(code: 'A', name: 'Apple v1'),
        _meal(code: 'B', name: 'Banana'),
        _meal(code: 'A', name: 'Apple v2'), // duplicate within the same batch
      ]);

      expect(ds.count, equals(2),
          reason: 'duplicate code within a batch must not double-add');
      final apples =
          ds.getAll().where((m) => m.code == 'A').toList();
      expect(apples, hasLength(1));
      expect(apples.first.name, equals('Apple v2'));
    });

    test(
        'cacheFromSearch behaves identically against a large pre-populated box '
        '(regression: O(N²) linear scan replaced with map dedup)', () async {
      // Pre-populate with 200 entries to make a regression to the
      // linear-scan path obvious in a CI run; the assertion is on
      // correctness, not on timing.
      final preExisting = List.generate(
        200,
        (i) => _meal(code: 'pre$i', name: 'Pre $i'),
      );
      await ds.cacheFromSearch(preExisting);
      expect(ds.count, equals(200));

      // Now cache a batch where some items overlap and some are new.
      final batch = [
        _meal(code: 'pre50', name: 'Pre 50 refreshed'),
        _meal(code: 'pre150', name: 'Pre 150 refreshed'),
        _meal(code: 'fresh1', name: 'Fresh 1'),
        _meal(code: 'fresh2', name: 'Fresh 2'),
      ];
      await ds.cacheFromSearch(batch);

      expect(ds.count, equals(202),
          reason: '200 pre-existing + 2 fresh, no duplicates');
      expect(ds.getByBarcode('pre50')?.name, equals('Pre 50 refreshed'));
      expect(ds.getByBarcode('pre150')?.name, equals('Pre 150 refreshed'));
      expect(ds.getByBarcode('fresh1'), isNotNull);
      expect(ds.getByBarcode('fresh2'), isNotNull);
    });

    test('getByBarcode returns the matching cached entry or null', () async {
      await ds.cache(_meal(code: 'X', name: 'Item X'));
      await ds.cache(_meal(code: 'Y', name: 'Item Y'));

      expect(ds.getByBarcode('X')?.name, equals('Item X'));
      expect(ds.getByBarcode('Y')?.name, equals('Item Y'));
      expect(ds.getByBarcode('Z'), isNull);
    });

    group('detailed flag (thin search vs full product)', () {
      test('getDetailedByBarcode ignores thin entries, returns full ones',
          () async {
        await ds.cache(_meal(code: 'THIN', name: 'Thin', detailed: false));
        await ds.cache(_meal(code: 'FULL', name: 'Full', detailed: true));

        expect(ds.getDetailedByBarcode('THIN'), isNull,
            reason: 'a thin search result must not satisfy a detailed lookup');
        expect(ds.getDetailedByBarcode('FULL')?.name, equals('Full'));
        // getByBarcode still returns either, for callers that accept thin data.
        expect(ds.getByBarcode('THIN')?.name, equals('Thin'));
      });

      test('legacy entries with null detailed are treated as thin', () async {
        await ds.cache(_meal(code: 'OLD', name: 'Legacy')); // detailed == null
        expect(ds.getDetailedByBarcode('OLD'), isNull);
      });

      test(
          'cacheFromSearch does not downgrade a full entry to a thin search '
          'result', () async {
        await ds.cache(_meal(code: 'A', name: 'Full', detailed: true));

        await ds.cacheFromSearch([
          _meal(code: 'A', name: 'Thin from search', detailed: false),
        ]);

        final entry = ds.getByBarcode('A')!;
        expect(entry.name, equals('Full'),
            reason: 'the hydrated full entry must survive a re-search');
        expect(entry.detailed, isTrue);
        expect(ds.getDetailedByBarcode('A')?.name, equals('Full'));
      });

      test('cacheFromSearch still refreshes a thin entry with newer thin data',
          () async {
        await ds.cache(_meal(code: 'B', name: 'Thin v1', detailed: false));

        await ds.cacheFromSearch([
          _meal(code: 'B', name: 'Thin v2', detailed: false),
        ]);

        expect(ds.getByBarcode('B')?.name, equals('Thin v2'));
      });
    });

    test('touch refreshes the timestamp without changing meal data', () async {
      await ds.cache(_meal(code: 'A', name: 'Apple v1'));
      final original = tsBox.get('A')!;

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await ds.touch('A');

      final touched = tsBox.get('A')!;
      expect(touched, greaterThan(original));
      expect(ds.getAll().single.name, equals('Apple v1'),
          reason: 'touch must not modify the cached meal');
    });

    test('touch is a no-op for empty code', () async {
      await ds.touch('');
      expect(tsBox.length, equals(0));
    });

    test('getAllByMostRecentlyTouched orders newest-touched first', () async {
      await ds.cache(_meal(code: 'A', name: 'Apple'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await ds.cache(_meal(code: 'B', name: 'Banana'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await ds.cache(_meal(code: 'C', name: 'Cherry'));
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // Touch A so it jumps to the top.
      await ds.touch('A');

      final ordered = ds.getAllByMostRecentlyTouched()
          .map((m) => m.code)
          .toList();
      expect(ordered.first, equals('A'));
      expect(ordered, equals(const ['A', 'C', 'B']));
    });

    test('getAllByMostRecentlyTouched sorts entries with no timestamp last',
        () async {
      await ds.cache(_meal(code: 'A', name: 'Apple'));
      await ds.cache(_meal(code: 'B', name: 'Banana'));
      // Manually add an entry without a timestamp record (pre-TTL data).
      await cacheBox.add(_meal(code: 'OLD', name: 'Legacy'));

      final ordered = ds.getAllByMostRecentlyTouched()
          .map((m) => m.code)
          .toList();
      expect(ordered.last, equals('OLD'));
    });

    test('pruneStale removes entries older than maxAge', () async {
      await ds.cache(_meal(code: 'OLD', name: 'Old'));
      // Backdate the OLD entry's timestamp by 100 days.
      await tsBox.put(
          'OLD',
          DateTime.now()
              .subtract(const Duration(days: 100))
              .millisecondsSinceEpoch);

      await ds.cache(_meal(code: 'FRESH', name: 'Fresh'));

      final removed = await ds.pruneStale(const Duration(days: 90));
      expect(removed, equals(1));
      expect(ds.count, equals(1));
      expect(ds.getAll().single.code, equals('FRESH'));
      expect(tsBox.get('OLD'), isNull);
      expect(tsBox.get('FRESH'), isNotNull);
    });

    test('pruneStale drops entries with no timestamp record', () async {
      // Manually insert without a ts entry.
      await cacheBox.add(_meal(code: 'NO_TS', name: 'Legacy'));
      await ds.cache(_meal(code: 'FRESH', name: 'Fresh'));

      final removed = await ds.pruneStale(const Duration(days: 90));
      expect(removed, equals(1));
      expect(ds.count, equals(1));
      expect(ds.getAll().single.code, equals('FRESH'));
    });

    test('pruneStale drops entries that have neither code nor name', () async {
      await cacheBox.add(_meal(code: null, name: null));
      final removed = await ds.pruneStale(const Duration(days: 90));
      expect(removed, equals(1));
      expect(ds.count, equals(0));
    });

    test('pruneStale returns 0 when nothing is stale', () async {
      await ds.cache(_meal(code: 'A', name: 'Apple'));
      await ds.cache(_meal(code: 'B', name: 'Banana'));

      final removed = await ds.pruneStale(const Duration(days: 90));
      expect(removed, equals(0));
      expect(ds.count, equals(2));
    });

    test('clear empties both the cache and the timestamps box', () async {
      await ds.cache(_meal(code: 'A', name: 'Apple'));
      await ds.cache(_meal(code: 'B', name: 'Banana'));

      await ds.clear();

      expect(ds.count, equals(0));
      expect(tsBox.length, equals(0));
    });

    test('getStorageSizeBytes returns a non-negative number', () async {
      await ds.cache(_meal(code: 'A', name: 'Apple'));
      final size = await ds.getStorageSizeBytes();
      expect(size, greaterThanOrEqualTo(0));
    });
  });
}
