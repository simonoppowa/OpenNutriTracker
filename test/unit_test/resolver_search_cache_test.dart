import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

import '../fixture/backend_sibling_fixtures.dart';
import '../helpers/hive_test_setup.dart';

class _FakeProductsRepository implements ProductsRepository {
  final Map<String, List<MealEntity>> fdc = {};
  bool remoteDown = false;

  @override
  Future<List<MealEntity>> getOFFProductsByString(String searchString) async {
    if (remoteDown) throw Exception('offline');
    return const [];
  }

  @override
  Future<List<MealEntity>> getSupabaseFoodsByString(String searchString) async {
    if (remoteDown) throw Exception('offline');
    return fdc[searchString] ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _NoIntake implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getRecentIntake() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _NoCustomMeals implements CustomMealDataSource {
  @override
  List<MealDBO> getAllCustomMeals() => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _NoRecipes implements RecipeDataSource {
  @override
  List<RecipeDBO> getAllRecipes() => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _EverySourceEnabled implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

ParsedMealItem item(String query) => ParsedMealItem(query: query);

/// #1164 on the resolver's real path: `ResolveParsedMealsUseCase` over the
/// real `SearchProductsUseCase` and a real Hive-backed search cache, with
/// only the network faked.
///
/// The unit tests of the scorers hand them fresh entities. The use case
/// does not: `searchFDCFoodByString` writes the remote page to the cache
/// *before* `_buildResult` reads the cache back, and the cache-first dedup
/// keeps the cached copy of every record the page returned — from the
/// first search, not the second. A copy read back through `MealDBO` has no
/// portions, so what the resolver scores on every search is whatever
/// survives that round trip. The first revision of the title scoring
/// carried the title as a field the round trip dropped, and every winner
/// the cold-cache tests pinned went back to the description-scored one on
/// this path: `egg` -> "Egg, creamed" at 0.517, `rice` -> "Rice, cooked,
/// NFS" at 0.350 and flagged, `orange juice` -> the BLS record ahead of
/// the survey one. The title now derives from the name, which the round
/// trip keeps; the portions it still does not.
void main() {
  late Box<MealDBO> cacheBox;
  late Box<int> timestampsBox;
  late RemoteSearchCacheDataSource cache;
  late _FakeProductsRepository repository;
  late ResolveParsedMealsUseCase resolver;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    cacheBox = await Hive.openBox<MealDBO>('resolver_cache_test_$stamp');
    timestampsBox = await Hive.openBox<int>('resolver_cache_ts_test_$stamp');
    cache = RemoteSearchCacheDataSource(cacheBox, timestampsBox);
    repository = _FakeProductsRepository();
    resolver = ResolveParsedMealsUseCase(
      SearchProductsUseCase(
        repository,
        _NoIntake(),
        _NoCustomMeals(),
        cache,
        _NoRecipes(),
        _EverySourceEnabled(),
      ),
    );
  });

  tearDown(() async {
    await cacheBox.deleteFromDisk();
    await timestampsBox.deleteFromDisk();
  });

  Future<ResolvedMealItem> resolveOne(String query) async =>
      (await resolver.resolve([item(query)])).single;

  group('a record the fresh page returned is scored as the fresh page', () {
    test('egg resolves the same on the first search and the next', () async {
      repository.fdc['egg'] = BackendSiblingFixtures.egg;

      final first = await resolveOne('egg');
      final second = await resolveOne('egg');

      for (final resolved in [first, second]) {
        expect(resolved.selected!.name, 'Egg, whole, boiled or poached');
        expect(resolved.confidence, 1.0);
        // The entity the resolver hands on is the fresh one: the portions
        // the review screen's picker lists are there.
        expect(resolved.selected!.portions, hasLength(3));
        expect(resolved.candidates, hasLength(4));
      }
      expect(cache.count, 4);
    });

    test('orange juice keeps the survey record ahead of BLS', () async {
      // The order c3aa4ebc fixed: both titles score 1.0, and the survey
      // record wins by not carrying the no-portions penalty. Scored as
      // cached copies, both are penalised, the tie falls to name length,
      // and the BLS record's shorter name wins — the order the decision
      // wanted gone.
      repository.fdc['orange juice'] = BackendSiblingFixtures.orangeJuice;

      final first = await resolveOne('orange juice');
      final second = await resolveOne('orange juice');

      for (final resolved in [first, second]) {
        expect(resolved.candidates.map((m) => m.name), [
          'Orange juice, 100%, NFS',
          'Orange juice',
        ]);
        expect(resolved.confidence, 1.0);
      }
    });

    test('rice stays above the floor on a warm cache', () async {
      repository.fdc['rice'] = [
        BackendSiblingFixtures.breadRice,
        BackendSiblingFixtures.chipsRice,
        ...BackendSiblingFixtures.rice,
      ];

      await resolveOne('rice');
      final resolved = await resolveOne('rice');

      expect(resolved.selected!.name, 'Rice, cooked, NFS');
      expect(resolved.confidence, 1.0);
      expect(resolved.isLowConfidence, isFalse);
    });

    test(
      'chicken breast resolves to the baked record on a warm cache',
      () async {
        // Scored as cached copies, every record lost its portions, the
        // survey records tied the SR Legacy one, and the SR Legacy record's
        // shorter description won at 0.421 — under the floor.
        repository.fdc['chicken breast'] = BackendSiblingFixtures.chickenBreast;

        await resolveOne('chicken breast');
        final resolved = await resolveOne('chicken breast');

        expect(
          resolved.selected!.name,
          'Chicken breast, baked, broiled, or roasted, skin not eaten, from raw',
        );
        expect(resolved.confidence, 1.0);
      },
    );

    test('bread resolves to Bread, white on a warm cache', () async {
      repository.fdc['bread'] = BackendSiblingFixtures.bread;

      await resolveOne('bread');
      final resolved = await resolveOne('bread');

      expect(resolved.selected!.name, 'Bread, white');
    });

    test('dried apple resolves to Apple, dried, cold cache and warm', () async {
      // The review's probe of the title-only revision, on this path: with
      // the page in the data source's description-ranked order, every
      // "Apple" tied at 0.667 and the portions key logged "Apple, raw" at
      // 0.667, not flagged. The qualifier the query names is read off the
      // description, which the cache keeps, so both searches land on the
      // record the user typed.
      repository.fdc['dried apple'] = [
        BackendSiblingFixtures.appleRaw,
        BackendSiblingFixtures.appleDried,
        BackendSiblingFixtures.appleBaked,
      ];

      final first = await resolveOne('dried apple');
      final second = await resolveOne('dried apple');

      for (final resolved in [first, second]) {
        expect(resolved.selected!.name, 'Apple, dried');
        expect(resolved.confidence, 1.0);
        expect(resolved.isLowConfidence, isFalse);
        expect(resolved.candidates.map((m) => m.name).skip(1), [
          'Apple, raw',
          'Apple, baked',
        ]);
      }
    });

    test('rye bread resolves to Bread, rye on a warm cache', () async {
      repository.fdc['rye bread'] = BackendSiblingFixtures.bread;

      await resolveOne('rye bread');
      final resolved = await resolveOne('rye bread');

      expect(resolved.selected!.name, 'Bread, rye');
      expect(resolved.confidence, 1.0);
    });
  });

  group('a record held only in the cache', () {
    test('is scored on its title beside fresh siblings', () async {
      // The sibling the user logged is in the cache and nowhere in this
      // search's page; three never-seen siblings arrive fresh. Scored on
      // its description it was 0.183 — behind every fresh sibling at 1.0
      // and under the floor. The title derives from the name, which the
      // cache keeps, so it scores 1.0 on that and trails the fresh
      // siblings by the no-portions penalty alone, which is what the cache
      // does not keep.
      final logged = BackendSiblingFixtures.eggWholeBoiledOrPoached;
      await cache.cache(MealDBO.fromMealEntity(logged));
      repository.fdc['egg'] = [
        BackendSiblingFixtures.eggWholeRaw,
        BackendSiblingFixtures.eggCreamed,
        BackendSiblingFixtures.eggYolkOnlyRaw,
      ];

      final resolved = await resolveOne('egg');

      final candidate = resolved.candidates.singleWhere(
        (m) => m.code == logged.code,
      );
      expect(candidate.name, 'Egg, whole, boiled or poached');
      expect(candidate.scoringName, 'Egg');
      expect(candidate.portions, isEmpty);
      expect(scoreMealForResolution(candidate, 'egg'), closeTo(0.85, 1e-9));
      expect(
        scoreMealForResolution(candidate, 'egg'),
        greaterThanOrEqualTo(kResolutionConfidenceFloor),
      );
      expect(resolved.candidates, hasLength(4));
    });

    test('is scored on its title when the remote is down', () async {
      // Offline, the whole pool is cached copies. Scored on their
      // descriptions the best of them, "Egg, creamed", was 0.35 and the
      // item was flagged as a guess; on their titles every one is 0.85.
      repository.fdc['egg'] = BackendSiblingFixtures.egg;
      await resolveOne('egg');
      repository.remoteDown = true;

      final resolved = await resolveOne('egg');

      expect(resolved.candidates, hasLength(4));
      expect(resolved.confidence, closeTo(0.85, 1e-9));
      expect(resolved.isLowConfidence, isFalse);
      for (final candidate in resolved.candidates) {
        expect(candidate.scoringName, 'Egg');
        expect(candidate.name, startsWith('Egg, '));
        expect(scoreMealForResolution(candidate, 'egg'), closeTo(0.85, 1e-9));
      }
    });
  });
}
