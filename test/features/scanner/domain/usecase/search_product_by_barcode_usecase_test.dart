import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';

void main() {
  group('SearchProductByBarcodeUseCase', () {
    late _FakeProductsRepository repo;
    late _FakeCustomMealDataSource customMealDataSource;
    late _FakeRecipeDataSource recipeDataSource;
    late _FakeRemoteSearchCacheDataSource cachedOffMealDataSource;
    late SearchProductByBarcodeUseCase useCase;

    setUp(() {
      repo = _FakeProductsRepository();
      customMealDataSource = _FakeCustomMealDataSource();
      recipeDataSource = _FakeRecipeDataSource();
      cachedOffMealDataSource = _FakeRemoteSearchCacheDataSource();
      useCase = SearchProductByBarcodeUseCase(
        repo,
        customMealDataSource,
        recipeDataSource,
        cachedOffMealDataSource,
      );
    });

    test(
        'returns the local custom meal without hitting OFF when the barcode '
        'matches', () async {
      final localMatch = _customMealDbo(code: '1234567890123', name: 'Local');
      customMealDataSource.meals.add(localMatch);
      repo.barcodeResult = MealEntity(
        code: '1234567890123',
        name: 'OFF Result',
        url: null,
        mealQuantity: '100',
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: 'g',
        servingSize: null,
        nutriments: _emptyNutriments(),
        source: MealSourceEntity.off,
      );

      final result = await useCase.searchProductByBarcode('1234567890123');

      expect(result.name, 'Local');
      expect(result.source, MealSourceEntity.custom);
      expect(repo.getOFFProductByBarcodeCalls, 0,
          reason: 'OFF should not be queried when a local match exists');
    });

    test('falls back to OFF when no local match exists', () async {
      customMealDataSource.meals
          .add(_customMealDbo(code: 'other', name: 'Other'));
      repo.barcodeResult = MealEntity(
        code: 'unknown-barcode',
        name: 'OFF Result',
        url: null,
        mealQuantity: '100',
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: 'g',
        servingSize: null,
        nutriments: _emptyNutriments(),
        source: MealSourceEntity.off,
      );

      final result = await useCase.searchProductByBarcode('unknown-barcode');

      expect(result.name, 'OFF Result');
      expect(result.source, MealSourceEntity.off);
      expect(repo.getOFFProductByBarcodeCalls, 1);
    });

    test('ignores custom meals whose code is null', () async {
      customMealDataSource.meals.add(_customMealDbo(code: null, name: 'NoCode'));
      repo.barcodeResult = MealEntity(
        code: '1234',
        name: 'OFF Result',
        url: null,
        mealQuantity: '100',
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: 'g',
        servingSize: null,
        nutriments: _emptyNutriments(),
        source: MealSourceEntity.off,
      );

      final result = await useCase.searchProductByBarcode('1234');

      expect(result.source, MealSourceEntity.off);
    });

    test(
      'returns cached OFF result without hitting the network when present',
      () async {
        cachedOffMealDataSource.entries.add(_offCacheDbo(
          code: '1234',
          name: 'Cached',
        ));
        repo.barcodeResult = MealEntity(
          code: '1234',
          name: 'Fresh OFF',
          url: null,
          mealQuantity: '100',
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          nutriments: _emptyNutriments(),
          source: MealSourceEntity.off,
        );

        final result = await useCase.searchProductByBarcode('1234');

        expect(result.name, 'Cached');
        expect(repo.getOFFProductByBarcodeCalls, 0);
      },
    );

    test('caches the OFF result on a successful network lookup', () async {
      repo.barcodeResult = MealEntity(
        code: '9999',
        name: 'New Product',
        url: null,
        mealQuantity: '100',
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: 'g',
        servingSize: null,
        nutriments: _emptyNutriments(),
        source: MealSourceEntity.off,
      );

      final result = await useCase.searchProductByBarcode('9999');

      expect(result.name, 'New Product');
      expect(cachedOffMealDataSource.writes, hasLength(1));
      expect(cachedOffMealDataSource.writes.single.code, '9999');
    });

    test('custom-meal match takes priority over cached match', () async {
      customMealDataSource.meals.add(_customMealDbo(
        code: '5555',
        name: 'My Custom',
      ));
      cachedOffMealDataSource.entries.add(_offCacheDbo(
        code: '5555',
        name: 'OFF Cached',
      ));

      final result = await useCase.searchProductByBarcode('5555');

      expect(result.name, 'My Custom');
      expect(repo.getOFFProductByBarcodeCalls, 0);
    });

    // The user attached this barcode to a recipe; scanning it should land
    // on the recipe instead of falling through to OFF (#167).
    test(
      'returns the recipe when its attached barcode matches',
      () async {
        recipeDataSource.recipes.add(
          _recipeDbo(barcode: '7777777777777', name: 'Home granola'),
        );

        final result =
            await useCase.searchProductByBarcode('7777777777777');

        expect(result.name, 'Home granola');
        expect(result.source, MealSourceEntity.recipe);
        expect(repo.getOFFProductByBarcodeCalls, 0,
            reason: 'OFF should not be queried when a recipe matches');
      },
    );

    // A recipe with no attached barcode must never accidentally answer for
    // some other code — the only "match" criterion is exact equality on a
    // non-null barcode.
    test(
      'ignores recipes whose barcode is null and falls through to OFF',
      () async {
        recipeDataSource.recipes
            .add(_recipeDbo(barcode: null, name: 'Untagged recipe'));
        repo.barcodeResult = MealEntity(
          code: '1111',
          name: 'OFF Result',
          url: null,
          mealQuantity: '100',
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          nutriments: _emptyNutriments(),
          source: MealSourceEntity.off,
        );

        final result = await useCase.searchProductByBarcode('1111');

        expect(result.name, 'OFF Result');
        expect(result.source, MealSourceEntity.off);
        expect(repo.getOFFProductByBarcodeCalls, 1);
      },
    );

    // The lookup must still reach OFF when no recipe or custom meal claims
    // the barcode — recipes are an addition to the resolution chain, not a
    // replacement.
    test(
      'falls through to OFF when no recipe or custom meal claims the code',
      () async {
        recipeDataSource.recipes
            .add(_recipeDbo(barcode: '2222', name: 'Other recipe'));
        repo.barcodeResult = MealEntity(
          code: '9999',
          name: 'OFF Result',
          url: null,
          mealQuantity: '100',
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          nutriments: _emptyNutriments(),
          source: MealSourceEntity.off,
        );

        final result = await useCase.searchProductByBarcode('9999');

        expect(result.source, MealSourceEntity.off);
        expect(repo.getOFFProductByBarcodeCalls, 1);
      },
    );

    // Recipes are the user's most explicit declaration of "this barcode
    // means this thing", so they sit at the top of the resolution chain
    // even ahead of flat custom meals that happen to share the code.
    test('recipe match takes priority over custom-meal match', () async {
      recipeDataSource.recipes
          .add(_recipeDbo(barcode: '4444', name: 'Granola recipe'));
      customMealDataSource.meals
          .add(_customMealDbo(code: '4444', name: 'Granola custom'));

      final result = await useCase.searchProductByBarcode('4444');

      expect(result.name, 'Granola recipe');
      expect(result.source, MealSourceEntity.recipe);
    });
  });
}

MealDBO _offCacheDbo({required String code, required String name}) =>
    MealDBO(
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
      source: MealSourceDBO.off,
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
  final List<MealDBO> entries = [];
  final List<MealDBO> writes = [];
  final List<String> touched = [];

  @override
  List<MealDBO> getAll() => entries;

  @override
  MealDBO? getByBarcode(String barcode) {
    for (final m in entries) {
      if (m.code == barcode) return m;
    }
    return null;
  }

  @override
  Future<void> cache(MealDBO meal) async {
    writes.add(meal);
    entries.add(meal);
  }

  @override
  Future<void> touch(String code) async {
    touched.add(code);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeProductsRepository implements ProductsRepository {
  MealEntity? barcodeResult;
  int getOFFProductByBarcodeCalls = 0;

  @override
  Future<MealEntity> getOFFProductByBarcode(String barcode) async {
    getOFFProductByBarcodeCalls++;
    return barcodeResult!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

MealDBO _customMealDbo({required String? code, required String name}) {
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
    source: MealSourceDBO.custom,
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

MealNutrimentsEntity _emptyNutriments() => const MealNutrimentsEntity(
      energyKcal100: 0,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    );

RecipeDBO _recipeDbo({required String? barcode, required String name}) {
  final now = DateTime(2024, 1, 1);
  return RecipeDBO(
    id: 'recipe-${name.hashCode}',
    name: name,
    description: null,
    ingredients: const [],
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
    createdAt: now,
    updatedAt: now,
    servingsCount: null,
    tags: null,
    barcode: barcode,
  );
}
