import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';

class _FakeProductsRepository implements ProductsRepository {
  final Map<String, List<MealEntity>> offResults = {};
  final Map<String, List<MealEntity>> fdcResults = {};

  /// Search strings whose remote call should throw (simulates rate-limit /
  /// network failure / 5xx).
  final Set<String> offThrowOn = {};
  final Set<String> fdcThrowOn = {};

  @override
  Future<List<MealEntity>> getOFFProductsByString(String searchString) async {
    if (offThrowOn.contains(searchString)) {
      throw Exception('OFF HTTP 429');
    }
    return offResults[searchString] ?? const [];
  }

  @override
  Future<List<MealEntity>> getSupabaseFDCFoodsByString(
    String searchString,
  ) async {
    if (fdcThrowOn.contains(searchString)) {
      throw Exception('FDC HTTP 429');
    }
    return fdcResults[searchString] ?? const [];
  }

  // Other ProductsRepository methods aren't exercised here — throw via
  // noSuchMethod if anything unexpectedly hits them.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected call: ${invocation.memberName}',
    );
  }
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  List<IntakeEntity> recentIntake = const [];
  int recentIntakeCallCount = 0;

  @override
  Future<List<IntakeEntity>> getRecentIntake() async {
    recentIntakeCallCount++;
    return recentIntake;
  }

  // Stub everything else — only getRecentIntake is exercised here.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected call: ${invocation.memberName}',
    );
  }
}

class _FakeCustomMealDataSource implements CustomMealDataSource {
  final List<MealDBO> meals = [];

  @override
  List<MealDBO> getAllCustomMeals() => meals;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRecipeDataSource implements RecipeDataSource {
  final List<RecipeDBO> recipes = [];

  @override
  List<RecipeDBO> getAllRecipes() => recipes;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRemoteSearchCacheDataSource implements RemoteSearchCacheDataSource {
  final List<MealDBO> meals = [];
  final List<MealDBO> cached = [];
  final List<String> touched = [];

  /// Per-key timestamps. Tests that care about ordering should set this
  /// explicitly via [setTimestamp]; otherwise [cache] sets to a synthetic
  /// monotonic counter so insertion-order matches touch-order.
  final Map<String, int> timestamps = {};
  int _nextTs = 0;

  void setTimestamp(String key, int ts) => timestamps[key] = ts;

  @override
  List<MealDBO> getAll() => meals;

  @override
  List<MealDBO> getAllByMostRecentlyTouched() {
    final entries = List<MealDBO>.of(meals);
    entries.sort((a, b) {
      final aTs = timestamps[a.code ?? a.name ?? ''] ?? 0;
      final bTs = timestamps[b.code ?? b.name ?? ''] ?? 0;
      return bTs.compareTo(aTs);
    });
    return entries;
  }

  @override
  Future<void> cache(MealDBO meal) async {
    cached.add(meal);
    meals.add(meal);
    final key = meal.code ?? meal.name;
    if (key != null) {
      timestamps[key] = ++_nextTs;
    }
  }

  @override
  Future<void> cacheAll(Iterable<MealDBO> incoming) async {
    for (final m in incoming) {
      await cache(m);
    }
  }

  @override
  Future<void> cacheFromSearch(Iterable<MealDBO> incoming) async {
    for (final m in incoming) {
      final key = m.code ?? m.name;
      final existingIndex = meals.indexWhere(
          (e) => e.code == m.code || (m.code == null && e.name == m.name));
      if (existingIndex >= 0) {
        // Refresh data, preserve existing timestamp.
        meals[existingIndex] = m;
        cached.add(m);
      } else {
        meals.add(m);
        cached.add(m);
        if (key != null) {
          timestamps[key] = ++_nextTs;
        }
      }
    }
  }

  @override
  MealDBO? getByBarcode(String barcode) =>
      meals.where((m) => m.code == barcode).firstOrNull;

  @override
  Future<void> touch(String code) async {
    touched.add(code);
    timestamps[code] = ++_nextTs;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

void main() {
  group('SearchProductsUseCase', () {
    late _FakeProductsRepository productsRepository;
    late _FakeGetIntakeUsecase getIntakeUsecase;
    late _FakeCustomMealDataSource customMealDataSource;
    late _FakeRemoteSearchCacheDataSource cachedOffMealDataSource;
    late _FakeRecipeDataSource recipeDataSource;
    late SearchProductsUseCase useCase;

    setUp(() {
      productsRepository = _FakeProductsRepository();
      getIntakeUsecase = _FakeGetIntakeUsecase();
      customMealDataSource = _FakeCustomMealDataSource();
      cachedOffMealDataSource = _FakeRemoteSearchCacheDataSource();
      recipeDataSource = _FakeRecipeDataSource();
      useCase = SearchProductsUseCase(
        productsRepository,
        getIntakeUsecase,
        customMealDataSource,
        cachedOffMealDataSource,
        recipeDataSource,
      );
    });

    test('prepends matching custom meals for OFF search', () async {
      final customMatch = _meal(
          code: 'custom-1', name: 'Tofu Bowl', source: MealSourceEntity.custom);
      final customNoMatch = _meal(
          code: 'custom-2',
          name: 'Lentil Soup',
          source: MealSourceEntity.custom);
      final offMatchFromHistory = _meal(
          code: 'off-history',
          name: 'Tofu Snack',
          source: MealSourceEntity.off);
      final offApiResult = _meal(
          code: 'off-api', name: 'Tofu Product', source: MealSourceEntity.off);

      productsRepository.offResults['tofu'] = [offApiResult];
      getIntakeUsecase.recentIntake = [
        _intake('i1', customNoMatch),
        _intake('i2', offMatchFromHistory),
        _intake('i3', customMatch),
      ];

      final result = await useCase.searchOFFProductsByString('tofu');

      expect(result.meals, [customMatch, offApiResult]);
      expect(result.remoteSourceEmpty, isFalse);
    });

    test('deduplicates repeated custom meals for FDC search', () async {
      final customMatch = _meal(
          code: 'custom-apple',
          name: 'Apple Mix',
          source: MealSourceEntity.custom);
      final fdcApiResult = _meal(
          code: 'fdc-api',
          name: 'Apple Nutrition',
          source: MealSourceEntity.fdc);

      productsRepository.fdcResults['apple'] = [fdcApiResult];
      getIntakeUsecase.recentIntake = [
        _intake('i1', customMatch),
        _intake('i2', customMatch),
      ];

      final result = await useCase.searchFDCFoodByString('apple');

      expect(result.meals, [customMatch, fdcApiResult]);
      expect(result.remoteSourceEmpty, isFalse);
    });

    test('does not query recent intake for blank search strings', () async {
      final offApiResult = _meal(
          code: 'off-api', name: 'Any Product', source: MealSourceEntity.off);

      productsRepository.offResults['   '] = [offApiResult];

      final result = await useCase.searchOFFProductsByString('   ');

      expect(result.meals, [offApiResult]);
      expect(getIntakeUsecase.recentIntakeCallCount, 0);
    });

    test('matches custom meals by brand case-insensitively', () async {
      final customBrandMatch = MealEntity(
          code: 'custom-brand',
          name: 'Snack',
          brands: 'Almond Co',
          thumbnailImageUrl: null,
          mainImageUrl: null,
          url: null,
          mealQuantity: null,
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          nutriments: MealNutrimentsEntity.empty(),
          source: MealSourceEntity.custom);
      final fdcApiResult = _meal(
          code: 'fdc-api',
          name: 'Almond Product',
          source: MealSourceEntity.fdc);

      productsRepository.fdcResults['ALMOND'] = [fdcApiResult];
      getIntakeUsecase.recentIntake = [_intake('i1', customBrandMatch)];

      final result = await useCase.searchFDCFoodByString('ALMOND');

      expect(result.meals, [customBrandMatch, fdcApiResult]);
      expect(result.remoteSourceEmpty, isFalse);
    });

    test('deduplicates custom meals when code is missing by fallback name key',
        () async {
      final customNoCode = MealEntity(
          code: null,
          name: 'Peanut Butter',
          brands: null,
          thumbnailImageUrl: null,
          mainImageUrl: null,
          url: null,
          mealQuantity: null,
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          nutriments: MealNutrimentsEntity.empty(),
          source: MealSourceEntity.custom);
      final offApiResult = _meal(
          code: 'off-api',
          name: 'Peanut Product',
          source: MealSourceEntity.off);

      productsRepository.offResults['peanut'] = [offApiResult];
      getIntakeUsecase.recentIntake = [
        _intake('i1', customNoCode),
        _intake('i2', customNoCode),
      ];

      final result = await useCase.searchOFFProductsByString('peanut');

      expect(result.meals, [customNoCode, offApiResult]);
      expect(result.remoteSourceEmpty, isFalse);
    });

    test(
      'returns custom meals + remoteSourceEmpty=true when OFF rate-limits',
      () async {
        final customMatch = _meal(
            code: 'custom-tofu',
            name: 'Tofu Bowl',
            source: MealSourceEntity.custom);

        productsRepository.offThrowOn.add('tofu');
        getIntakeUsecase.recentIntake = [_intake('i1', customMatch)];

        final result = await useCase.searchOFFProductsByString('tofu');

        expect(result.meals, [customMatch]);
        expect(result.remoteSourceEmpty, isTrue);
      },
    );

    test(
      'returns custom meals + remoteSourceEmpty=true when FDC rate-limits',
      () async {
        final customMatch = _meal(
            code: 'custom-apple',
            name: 'Apple Mix',
            source: MealSourceEntity.custom);

        productsRepository.fdcThrowOn.add('apple');
        getIntakeUsecase.recentIntake = [_intake('i1', customMatch)];

        final result = await useCase.searchFDCFoodByString('apple');

        expect(result.meals, [customMatch]);
        expect(result.remoteSourceEmpty, isTrue);
      },
    );

    test(
      'returns empty meals + remoteSourceEmpty=true when remote fails and no '
      'custom meals match',
      () async {
        productsRepository.offThrowOn.add('xyzzy');
        getIntakeUsecase.recentIntake = const [];

        final result = await useCase.searchOFFProductsByString('xyzzy');

        expect(result.meals, isEmpty);
        expect(result.remoteSourceEmpty, isTrue);
      },
    );

    test(
      'remoteSourceEmpty=true when remote returns an empty list (not just on '
      'failure)',
      () async {
        final customMatch = _meal(
            code: 'custom-tofu',
            name: 'Tofu Bowl',
            source: MealSourceEntity.custom);

        // No offResults entry for 'tofu' → fake returns []
        getIntakeUsecase.recentIntake = [_intake('i1', customMatch)];

        final result = await useCase.searchOFFProductsByString('tofu');

        expect(result.meals, [customMatch]);
        expect(result.remoteSourceEmpty, isTrue);
      },
    );

    test(
      'surfaces custom meals from the box even when never logged as intake '
      '(regression: CSV-imported meals must appear in search before being '
      'logged for the first time)',
      () async {
        // Imported via CSV — sits in the custom-meal box, never logged.
        customMealDataSource.meals.add(_customMealDbo(
          code: 'custom-banana',
          name: 'Banana',
        ));
        // Intake history is empty (e.g. fresh app or airplane mode).
        getIntakeUsecase.recentIntake = const [];
        // Remote unavailable too — covers the airplane-mode case explicitly.
        productsRepository.offThrowOn.add('banana');

        final result = await useCase.searchOFFProductsByString('banana');

        expect(result.meals, hasLength(1));
        expect(result.meals.single.name, 'Banana');
        expect(result.meals.single.source, MealSourceEntity.custom);
        expect(result.remoteSourceEmpty, isTrue);
      },
    );

    test(
      'deduplicates a custom meal that appears in both the box and intake '
      'history',
      () async {
        final inBoth = _meal(
            code: 'shared-1',
            name: 'Tofu Bowl',
            source: MealSourceEntity.custom);
        customMealDataSource.meals.add(_customMealDbo(
          code: 'shared-1',
          name: 'Tofu Bowl',
        ));
        getIntakeUsecase.recentIntake = [_intake('i1', inBoth)];

        final result = await useCase.searchOFFProductsByString('tofu');

        expect(result.meals, hasLength(1));
        expect(result.meals.single.code, 'shared-1');
      },
    );

    // Cache: read-side
    test(
      'surfaces cached OFF results when the remote source is empty',
      () async {
        cachedOffMealDataSource.meals.add(_offCacheDbo(
          code: 'off-cached-1',
          name: 'Cached Banana',
        ));
        // No remote results, no failure.
        productsRepository.offResults['banana'] = const [];

        final result = await useCase.searchOFFProductsByString('banana');

        expect(result.meals, hasLength(1));
        expect(result.meals.single.name, 'Cached Banana');
        expect(result.meals.single.source, MealSourceEntity.off);
        expect(result.remoteSourceEmpty, isTrue);
      },
    );

    test(
      'surfaces cached OFF results in airplane mode (remote throws)',
      () async {
        cachedOffMealDataSource.meals.add(_offCacheDbo(
          code: 'off-cached-1',
          name: 'Cached Banana',
        ));
        productsRepository.offThrowOn.add('banana');

        final result = await useCase.searchOFFProductsByString('banana');

        expect(result.meals.map((m) => m.name), contains('Cached Banana'));
        expect(result.remoteSourceEmpty, isTrue);
      },
    );

    test(
      'cache-first ordering deduplicates cached + remote entries with the '
      'same code (only one entry surfaces, position determined by the cache)',
      () async {
        cachedOffMealDataSource.meals.add(_offCacheDbo(
          code: 'off-1',
          name: 'Tofu',
        ));
        productsRepository.offResults['tofu'] = [
          _meal(
              code: 'off-1',
              name: 'Tofu Fresh Name',
              source: MealSourceEntity.off),
        ];

        final result = await useCase.searchOFFProductsByString('tofu');

        // Single entry, identified by code (dedup worked). The data
        // surfaced is whatever cacheFromSearch left in the cache box —
        // by design it refreshes data on existing entries while
        // preserving the timestamp, so the user sees the freshest
        // information without losing their position-in-list.
        expect(result.meals, hasLength(1));
        expect(result.meals.single.code, 'off-1');
      },
    );

    // Cache write-side: search results ARE cached. The 90-day TTL handles
    // unbounded growth — entries the user never selects age out, while
    // selected items have their timestamp refreshed and stay.
    test('successful OFF search results are written to the cache', () async {
      productsRepository.offResults['tofu'] = [
        _meal(code: 'off-1', name: 'Tofu A', source: MealSourceEntity.off),
        _meal(code: 'off-2', name: 'Tofu B', source: MealSourceEntity.off),
      ];

      await useCase.searchOFFProductsByString('tofu');

      expect(cachedOffMealDataSource.cached.map((m) => m.code).toList(),
          ['off-1', 'off-2']);
    });

    test('successful FDC search results are written to the cache', () async {
      productsRepository.fdcResults['apple'] = [
        _meal(code: 'fdc-1', name: 'Apple', source: MealSourceEntity.fdc),
      ];

      await useCase.searchFDCFoodByString('apple');

      expect(cachedOffMealDataSource.cached, hasLength(1));
      expect(cachedOffMealDataSource.cached.single.code, 'fdc-1');
    });

    test('empty remote results do NOT write to the cache', () async {
      productsRepository.offResults['nothing'] = const [];

      await useCase.searchOFFProductsByString('nothing');

      expect(cachedOffMealDataSource.cached, isEmpty);
    });

    test('failing remote calls do NOT write to the cache', () async {
      productsRepository.offThrowOn.add('boom');

      await useCase.searchOFFProductsByString('boom');

      expect(cachedOffMealDataSource.cached, isEmpty);
    });

    test(
      'a re-search does NOT reset timestamps of items already in the cache '
      '(regression: previously, bulk-caching wiped the timestamp of a just-'
      'logged item, breaking the promote-recent ordering)',
      () async {
        // User selected banana-b earlier, so its timestamp is high.
        cachedOffMealDataSource.meals.addAll([
          _offCacheDbo(code: 'banana-a', name: 'Banana A'),
          _offCacheDbo(code: 'banana-b', name: 'Banana B'),
        ]);
        cachedOffMealDataSource.setTimestamp('banana-a', 100);
        cachedOffMealDataSource.setTimestamp('banana-b', 999);

        // Now the user searches "banana" again. Remote returns the same
        // products. cacheFromSearch must NOT reset banana-b's high
        // timestamp — it should stay at the top of the cached list.
        productsRepository.offResults['banana'] = [
          _meal(code: 'banana-a', name: 'Banana A', source: MealSourceEntity.off),
          _meal(code: 'banana-b', name: 'Banana B', source: MealSourceEntity.off),
        ];

        final result = await useCase.searchOFFProductsByString('banana');

        expect(result.meals.first.code, 'banana-b',
            reason:
                'banana-b should still rank first because its timestamp '
                'was not reset by the new search');
      },
    );

    test(
      'recently-touched cached entry sorts above other cached entries '
      '(simulates the user logging a specific result and seeing it at the '
      'top of the same search next time)',
      () async {
        // Three banana variants in the cache from a previous bulk-search.
        cachedOffMealDataSource.meals.addAll([
          _offCacheDbo(code: 'banana-a', name: 'Banana A'),
          _offCacheDbo(code: 'banana-b', name: 'Banana B'),
          _offCacheDbo(code: 'banana-c', name: 'Banana C'),
        ]);
        // All bulk-cached at the same epoch; user then explicitly logged
        // banana-b later (touch fires with a higher timestamp).
        cachedOffMealDataSource.setTimestamp('banana-a', 100);
        cachedOffMealDataSource.setTimestamp('banana-b', 999);
        cachedOffMealDataSource.setTimestamp('banana-c', 100);

        // Remote returns nothing different — keeps the test focused on
        // ordering of the cached entries.
        productsRepository.offResults['banana'] = const [];

        final result = await useCase.searchOFFProductsByString('banana');

        // banana-b (the user-selected one) should be first.
        expect(result.meals.map((m) => m.code).toList(),
            ['banana-b', 'banana-a', 'banana-c']);
      },
    );
  });

  group('SearchProductsUseCase recipes integration', () {
    late _FakeProductsRepository productsRepository;
    late _FakeGetIntakeUsecase getIntakeUsecase;
    late _FakeCustomMealDataSource customMealDataSource;
    late _FakeRemoteSearchCacheDataSource cachedOffMealDataSource;
    late _FakeRecipeDataSource recipeDataSource;
    late SearchProductsUseCase useCase;

    setUp(() {
      productsRepository = _FakeProductsRepository();
      getIntakeUsecase = _FakeGetIntakeUsecase();
      customMealDataSource = _FakeCustomMealDataSource();
      cachedOffMealDataSource = _FakeRemoteSearchCacheDataSource();
      recipeDataSource = _FakeRecipeDataSource();
      useCase = SearchProductsUseCase(
        productsRepository,
        getIntakeUsecase,
        customMealDataSource,
        cachedOffMealDataSource,
        recipeDataSource,
      );
    });

    test('saved recipe matching the search appears with recipe source',
        () async {
      recipeDataSource.recipes
          .add(_recipeDbo(id: 'r-1', name: 'Vanilla Cake'));
      productsRepository.offResults['cake'] = const [];

      final result = await useCase.searchOFFProductsByString('cake');

      expect(result.meals, hasLength(1));
      expect(result.meals.first.name, 'Vanilla Cake');
      expect(result.meals.first.source, MealSourceEntity.recipe);
      expect(result.meals.first.code, 'r-1');
    });

    test('recipe and custom meal with the same name do not dedup-collide',
        () async {
      recipeDataSource.recipes
          .add(_recipeDbo(id: 'r-1', name: 'Banana Bread'));
      customMealDataSource.meals
          .add(_customMealDbo(code: 'cm-1', name: 'Banana Bread'));
      productsRepository.offResults['banana'] = const [];

      final result = await useCase.searchOFFProductsByString('banana');

      // Both appear because dedup is namespaced by source.
      expect(result.meals, hasLength(2));
      final sources = result.meals.map((m) => m.source).toSet();
      expect(sources,
          containsAll([MealSourceEntity.custom, MealSourceEntity.recipe]));
    });

    test('recipe outranks OFF cache hit for the same search string', () async {
      recipeDataSource.recipes
          .add(_recipeDbo(id: 'r-1', name: 'Tomato Soup'));
      cachedOffMealDataSource.meals.add(
        _offCacheDbo(code: 'off-1', name: 'Tomato Soup canned'),
      );
      productsRepository.offResults['tomato'] = const [];

      final result = await useCase.searchOFFProductsByString('tomato');

      // Recipe (priority 2) appears before OFF cache (priority 4).
      expect(result.meals.first.source, MealSourceEntity.recipe);
    });
  });
}

RecipeDBO _recipeDbo({
  required String id,
  required String name,
}) {
  return RecipeDBO(
    id: id,
    name: name,
    description: null,
    ingredients: [],
    totalWeightG: 100,
    aggregatedNutrimentsPer100: MealNutrimentsDBO(
      energyKcal100: 0,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    createdAt: DateTime.utc(2024, 1, 1),
    updatedAt: DateTime.utc(2024, 1, 1),
    servingsCount: null,
    tags: null,
    imagePath: null,
  );
}

MealDBO _customMealDbo({required String code, required String name}) =>
    _meaDboWithSource(code: code, name: name, source: MealSourceDBO.custom);

MealDBO _offCacheDbo({required String code, required String name}) =>
    _meaDboWithSource(code: code, name: name, source: MealSourceDBO.off);

MealDBO _meaDboWithSource({
  required String code,
  required String name,
  required MealSourceDBO source,
}) {
  return MealDBO(
    code: code,
    name: name,
    brands: null,
    thumbnailImageUrl: null,
    mainImageUrl: null,
    url: null,
    mealQuantity: '100',
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    source: source,
    nutriments: MealNutrimentsDBO(
      energyKcal100: 0,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
  );
}

MealEntity _meal({
  required String code,
  required String name,
  required MealSourceEntity source,
}) {
  return MealEntity(
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
    nutriments: MealNutrimentsEntity.empty(),
    source: source,
  );
}

IntakeEntity _intake(String id, MealEntity meal) {
  return IntakeEntity(
    id: id,
    unit: 'g',
    amount: 100,
    type: IntakeTypeEntity.breakfast,
    meal: meal,
    dateTime: DateTime.utc(2024, 1, 1),
  );
}
