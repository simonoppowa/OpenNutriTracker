import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/domain/entity/shared_recipe_payload.dart';

RecipeEntity _testRecipe() {
  final flour = MealEntity(
    code: 'flour',
    name: 'Flour',
    brands: 'King Arthur',
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: null,
    servingSize: null,
    nutriments: MealNutrimentsEntity(
      energyKcal100: 340,
      carbohydrates100: 70,
      fat100: 1,
      proteins100: 10,
      sugars100: 0,
      saturatedFat100: 0,
      fiber100: 3,
    ),
    source: MealSourceEntity.off,
    thumbnailImageUrl: 'https://example.com/flour.jpg',
  );
  final sugar = MealEntity(
    code: 'sugar',
    name: 'Sugar',
    brands: null,
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: null,
    servingSize: null,
    nutriments: MealNutrimentsEntity(
      energyKcal100: 390,
      carbohydrates100: 100,
      fat100: 0,
      proteins100: 0,
      sugars100: 100,
      saturatedFat100: 0,
      fiber100: 0,
    ),
    source: MealSourceEntity.off,
  );
  return RecipeEntity(
    id: 'recipe-1',
    name: 'Vanilla Cake',
    description: 'A simple cake',
    ingredients: [
      RecipeIngredientEntity(
        snapshotMeal: flour,
        amount: 200,
        unit: 'g',
        convertedAmountG: 200,
      ),
      RecipeIngredientEntity(
        snapshotMeal: sugar,
        amount: 100,
        unit: 'g',
        convertedAmountG: 100,
      ),
    ],
    totalWeightG: 300,
    aggregatedNutrimentsPer100: MealNutrimentsEntity(
      energyKcal100: 356.7,
      carbohydrates100: 80,
      fat100: 0.7,
      proteins100: 6.7,
      sugars100: 33.3,
      saturatedFat100: 0,
      fiber100: 2,
    ),
    createdAt: DateTime.utc(2024, 1, 1),
    updatedAt: DateTime.utc(2024, 1, 2),
    servingsCount: 8,
  );
}

// Note: RecipeEntity tags default to const [], so we don't pass them above.

class _FakeRecipeRepository implements RecipeRepository {
  final List<RecipeEntity> saved = [];

  @override
  Future<void> saveRecipe(RecipeEntity recipe) async => saved.add(recipe);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

SharedRecipePayload _roundTrip(RecipeEntity recipe) =>
    SharedRecipePayload.fromJsonString(
      SharedRecipePayload.fromRecipe(recipe).toJsonString(),
    );

void main() {
  group('SharedRecipePayload', () {
    test('round-trips name, description, and ingredient count', () {
      final payload = SharedRecipePayload.fromRecipe(_testRecipe());
      final encoded = payload.toJsonString();
      final decoded = SharedRecipePayload.fromJsonString(encoded);

      expect(decoded.name, 'Vanilla Cake');
      expect(decoded.description, 'A simple cake');
      expect(decoded.servingsCount, 8);
      expect(decoded.totalWeightG, 300);
      expect(decoded.ingredients, hasLength(2));
    });

    test('preserves macro nutrients on aggregated and per-ingredient', () {
      final encoded =
          SharedRecipePayload.fromRecipe(_testRecipe()).toJsonString();
      final decoded = SharedRecipePayload.fromJsonString(encoded);

      // 1dp tolerance because we round during compaction.
      expect(decoded.energyKcal100, closeTo(356.7, 0.1));
      expect(decoded.carbohydrates100, closeTo(80, 0.1));
      expect(decoded.fat100, closeTo(0.7, 0.1));
      expect(decoded.proteins100, closeTo(6.7, 0.1));

      final flour = decoded.ingredients.first;
      expect(flour.name, 'Flour');
      expect(flour.brands, 'King Arthur');
      expect(flour.amount, 200);
      expect(flour.unit, 'g');
      expect(flour.convertedAmountG, 200);
      expect(flour.energyKcal100, closeTo(340, 0.1));
      expect(flour.thumbnailImageUrl, 'https://example.com/flour.jpg');
    });

    test('toRecipeEntity rebuilds a valid RecipeEntity', () {
      final encoded =
          SharedRecipePayload.fromRecipe(_testRecipe()).toJsonString();
      final decoded = SharedRecipePayload.fromJsonString(encoded);
      final reconstructed = decoded.toRecipeEntity();

      expect(reconstructed.name, 'Vanilla Cake');
      expect(reconstructed.ingredients, hasLength(2));
      // Ingredient meals get fresh UUID codes since they're snapshots.
      expect(reconstructed.ingredients.first.snapshotMeal.code, isNotNull);
      expect(reconstructed.ingredients.first.snapshotMeal.source,
          MealSourceEntity.custom);
    });

    // #1194: the wire format has no override flag, so a shared recipe with a
    // hand-entered total weight was saved at the ingredient sum instead.
    group('a total weight entered by hand', () {
      test('is recognised after the round trip', () {
        // 300 g of ingredients, cooked down to 240 g.
        final decoded =
            _roundTrip(_testRecipe().copyWith(totalWeightG: 240));

        expect(decoded.totalWeightOverridden, isTrue);
      });

      test('survives the save, and nutrition is spread over it', () async {
        final repo = _FakeRecipeRepository();
        final save = SaveRecipeUseCase(repo, ComputeRecipeNutritionUseCase());
        final decoded =
            _roundTrip(_testRecipe().copyWith(totalWeightG: 240));

        await save.save(
          decoded.toRecipeEntity(),
          totalWeightOverridden: decoded.totalWeightOverridden,
        );

        final saved = repo.saved.single;
        expect(saved.totalWeightG, 240);
        // 200 g flour at 340 + 100 g sugar at 390 = 1070 kcal over 240 g.
        expect(saved.aggregatedNutrimentsPer100.energyKcal100,
            closeTo(445.8, 0.1));
      });

      test('an untouched total is not mistaken for one', () {
        expect(_roundTrip(_testRecipe()).totalWeightOverridden, isFalse);
      });

      test('one-decimal rounding alone is not mistaken for one', () {
        // Each 33.333 g ingredient travels as 33.3, and the 99.999 g total
        // as 100 — 0.1 g apart without anybody having typed anything.
        final base = _testRecipe();
        final third = base.ingredients.first.copyWith(convertedAmountG: 33.333);
        final decoded = _roundTrip(base.copyWith(
          ingredients: [third, third, third],
          totalWeightG: 99.999,
        ));

        expect(decoded.totalWeightG - decoded.ingredients
            .fold<double>(0, (sum, i) => sum + i.convertedAmountG), isNonZero);
        expect(decoded.totalWeightOverridden, isFalse);
      });
    });

    test('throws on malformed input', () {
      expect(
        () => SharedRecipePayload.fromJsonString('not-a-recipe'),
        throwsA(isA<SharedRecipeParseException>()),
      );
    });

    test('throws on unsupported version', () {
      // Manually craft a payload with version 99
      final fakeJson = '[99,"name",null,null,100,[null,null,null,null,null,null,null],[]]';
      expect(
        () => SharedRecipePayload.fromJsonString(fakeJson),
        throwsA(isA<SharedRecipeParseException>()),
      );
    });

    test('oversized decompressed payload throws SharedRecipeParseException',
        () {
      // 1 MiB of repeated bytes compresses to ~1 KiB but expands well
      // past the 64 KiB cap. A malicious QR could in principle ship
      // something like this; the cap keeps the parse predictable.
      final blob = List<int>.filled(1024 * 1024, 0x42);
      final compressed = gzip.encode(blob);
      final raw = base64Url.encode(compressed);
      expect(
        () => SharedRecipePayload.fromJsonString(raw),
        throwsA(
          isA<SharedRecipeParseException>().having(
            (e) => e.message,
            'message',
            contains('too large'),
          ),
        ),
      );
    });
  });
}
