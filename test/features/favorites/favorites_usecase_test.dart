import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/favorites/data/favorite_data_source.dart';
import 'package:opennutritracker/features/favorites/domain/favorite_entry.dart';
import 'package:opennutritracker/features/favorites/domain/favorites_usecase.dart';

import '../../helpers/fake_hive_db_provider.dart';
import '../../helpers/hive_test_setup.dart';

MealEntity _meal(
  String code, {
  MealSourceEntity source = MealSourceEntity.off,
}) => MealEntity(
  code: code,
  name: 'Skyr $code',
  brands: 'Arla',
  url: null,
  mealQuantity: '450',
  mealUnit: 'g',
  servingQuantity: 150,
  servingUnit: 'g',
  servingSize: '150 g',
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 63,
    carbohydrates100: 4,
    fat100: 0.2,
    proteins100: 11,
    sugars100: 4,
    saturatedFat100: 0.1,
    fiber100: 0,
  ),
  source: source,
);

RecipeEntity _recipe(String id) => RecipeEntity(
  id: id,
  name: 'Overnight oats',
  description: null,
  ingredients: const [],
  totalWeightG: 400,
  aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  servingsCount: 2,
);

void main() {
  late Directory dir;
  late Box<String> favoriteBox;
  late Box<RecipeDBO> recipeBox;
  late RecipeRepository recipes;
  late FavoritesUsecase favorites;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('favorites_test');
    Hive.init(dir.path);
    registerHiveAdaptersOnce();
    favoriteBox = await Hive.openBox<String>('favorites');
    recipeBox = await Hive.openBox<RecipeDBO>('recipes');
    final provider = FakeHiveDBProvider(
      favoriteBox: favoriteBox,
      recipeBox: recipeBox,
    );
    recipes = RecipeRepository(RecipeDataSource(provider));
    favorites = FavoritesUsecase(
      FavoriteDataSource(provider),
      recipes,
      clock: () => DateTime(2026, 10, 19, 12),
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('a food toggles in and out', () async {
    final skyr = _meal('4002971234567');

    expect(await favorites.toggleMeal(skyr), isTrue);
    expect(favorites.isMealFavorite(skyr), isTrue);
    expect(await favorites.toggleMeal(skyr), isFalse);
    expect(favorites.isMealFavorite(skyr), isFalse);
  });

  test('the same code from another source is another favourite', () async {
    await favorites.toggleMeal(_meal('123'));

    expect(
      favorites.isMealFavorite(_meal('123', source: MealSourceEntity.custom)),
      isFalse,
    );
  });

  test(
    'the list keeps the order favourites were added in, with snapshots',
    () async {
      await favorites.toggleMeal(_meal('a'));
      await recipes.saveRecipe(_recipe('r1'));
      await favorites.toggleRecipe(_recipe('r1'));
      await favorites.toggleMeal(_meal('b', source: MealSourceEntity.custom));

      final list = await favorites.list();

      expect(list.map((e) => e.id), [
        'meal:off:a',
        'recipe:r1',
        'meal:custom:b',
      ]);
      expect(list.first.meal!.nutriments.proteins100, 11);
      expect(list.first.name, 'Skyr a');
      expect(list.last.isOwnFood, isTrue);
      expect(list[1].kind, FavoriteKind.recipe);
    },
  );

  test('reordering moves favourites and keeps the rest after them', () async {
    for (final code in ['a', 'b', 'c']) {
      await favorites.toggleMeal(_meal(code));
    }

    await favorites.reorder(['meal:off:c', 'meal:off:a']);

    expect((await favorites.list()).map((e) => e.id), [
      'meal:off:c',
      'meal:off:a',
      'meal:off:b',
    ]);
  });

  test('a deleted recipe drops out of the favourites', () async {
    await recipes.saveRecipe(_recipe('r1'));
    await favorites.toggleRecipe(_recipe('r1'));

    await recipes.deleteRecipe('r1');

    expect(await favorites.list(), isEmpty);
    expect(favorites.isRecipeFavorite('r1'), isFalse);
  });

  test('every change is announced', () async {
    final before = favorites.changes.value;

    await favorites.toggleMeal(_meal('a'));
    await favorites.toggleMeal(_meal('a'));

    expect(favorites.changes.value, before + 2);
  });

  test('an entry round-trips through JSON', () {
    final entry = FavoriteEntry(
      id: 'meal:off:a',
      kind: FavoriteKind.food,
      name: 'Skyr a',
      meal: _meal('a'),
      createdAt: DateTime(2026, 10, 19),
      sortIndex: 3,
    );

    expect(FavoriteEntry.fromJson(entry.toJson()), entry);
    expect(
      () => FavoriteEntry.fromJson(const {'kind': 'food', 'id': 'x'}),
      throwsFormatException,
    );
  });

  test('an unreadable stored entry is skipped', () async {
    await favoriteBox.put('broken', '{not json');
    await favorites.toggleMeal(_meal('a'));

    expect((await favorites.list()).map((e) => e.id), ['meal:off:a']);
  });

  test('favourite meals filter by name or brand and include recipes', () async {
    await favorites.toggleMeal(_meal('a'));
    await recipes.saveRecipe(_recipe('r1'));
    await favorites.toggleRecipe(_recipe('r1'));

    expect((await favorites.favoriteMeals()).map((m) => m.name), [
      'Skyr a',
      'Overnight oats',
    ]);
    expect((await favorites.favoriteMeals(query: 'OATS')).map((m) => m.name), [
      'Overnight oats',
    ]);
    expect((await favorites.favoriteMeals(query: 'arla')).map((m) => m.name), [
      'Skyr a',
    ]);
  });

  test('a recipe listed as a meal counts as a favourite', () async {
    await recipes.saveRecipe(_recipe('r1'));
    await favorites.toggleRecipe(_recipe('r1'));

    expect(favorites.isMealFavorite(_recipe('r1').toMealEntity()), isTrue);
  });

  test('favourites move to the front, the rest keeps its order', () async {
    await favorites.toggleMeal(_meal('c'));

    expect(
      favorites
          .favoritesFirst([_meal('a'), _meal('b'), _meal('c')])
          .map((m) => m.code),
      ['c', 'a', 'b'],
    );
  });

  test('a recipe starred as a meal is the recipe favourite', () async {
    await recipes.saveRecipe(_recipe('r1'));
    final recipeMeal = _recipe('r1').toMealEntity();

    expect(await favorites.toggleMeal(recipeMeal), isTrue);

    expect(favorites.isMealFavorite(recipeMeal), isTrue);
    expect(favorites.isRecipeFavorite('r1'), isTrue);
    expect((await favorites.list()).single.kind, FavoriteKind.recipe);
    expect(await favorites.toggleRecipe(_recipe('r1')), isFalse);
  });
}
