import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';

void main() {
  group('lookupBarcode disambiguation', () {
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

    // The motivating case: a user keeps both "apple, large" and "apple,
    // small" against the same supermarket barcode. The scanner should
    // surface both options rather than silently logging whichever happens
    // to be first in the recipe list.
    test('returns a multiple-recipe result when two recipes share a code',
        () async {
      recipeDataSource.recipes.add(
        _recipeDbo(barcode: '4006381333931', name: 'apple, large'),
      );
      recipeDataSource.recipes.add(
        _recipeDbo(barcode: '4006381333931', name: 'apple, small'),
      );

      final result = await useCase.lookupBarcode('4006381333931');

      expect(result, isA<BarcodeLookupMultipleRecipes>());
      final multi = result as BarcodeLookupMultipleRecipes;
      expect(multi.recipes.map((r) => r.name).toList(),
          ['apple, large', 'apple, small']);
      expect(repo.getOFFProductByBarcodeCalls, 0,
          reason: 'No OFF query while the user is still picking');
    });

    // One recipe — the common case. Should resolve straight to a single
    // meal, exactly as the legacy searchProductByBarcode used to.
    test('returns a single-meal result when exactly one recipe matches',
        () async {
      recipeDataSource.recipes
          .add(_recipeDbo(barcode: '7777777777777', name: 'granola'));

      final result = await useCase.lookupBarcode('7777777777777');

      expect(result, isA<BarcodeLookupSingle>());
      final single = result as BarcodeLookupSingle;
      expect(single.meal.name, 'granola');
      expect(single.meal.source, MealSourceEntity.recipe);
    });

    // No recipe claims the code, no custom meal either — we expect OFF
    // to be queried just like the original resolution chain.
    test('falls through to OFF when no recipe matches', () async {
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

      final result = await useCase.lookupBarcode('9999');

      expect(result, isA<BarcodeLookupSingle>());
      final single = result as BarcodeLookupSingle;
      expect(single.meal.name, 'OFF Result');
      expect(single.meal.source, MealSourceEntity.off);
      expect(repo.getOFFProductByBarcodeCalls, 1);
    });
  });
}

RecipeDBO _recipeDbo({required String? barcode, required String name}) {
  final now = DateTime(2024, 1, 1);
  return RecipeDBO(
    id: 'recipe-${name.hashCode}-${barcode ?? 'nobc'}',
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

MealNutrimentsEntity _emptyNutriments() => const MealNutrimentsEntity(
      energyKcal100: 0,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
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
  Future<void> touch(String code) async {}

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
