import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_all_recipes_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_meal_bloc.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

RecipeEntity _recipe(String id, String name) => RecipeEntity(
  id: id,
  name: name,
  description: null,
  ingredients: const [],
  totalWeightG: 300,
  aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  servingsCount: null,
);

List<String?> _names(RecipeMealState state) =>
    (state as RecipeMealLoadedState).recipes.map((m) => m.name).toList();

/// #1284: the add-food screen's Recipes source, over the real recipe box.
void main() {
  late Directory dir;
  late Box<RecipeDBO> box;
  late FakeHiveDBProvider provider;
  late RecipeRepository repository;
  late RecipeMealBloc bloc;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dir = await Directory.systemTemp.createTemp('recipe_meal_bloc_test');
    Hive.init(dir.path);
    registerHiveAdaptersOnce();
    box = await Hive.openBox<RecipeDBO>('recipe_meal_bloc_recipes');
    provider = FakeHiveDBProvider(activeProfileId: 'profile-a', recipeBox: box);
    repository = RecipeRepository(RecipeDataSource(provider));
    bloc = RecipeMealBloc(
      GetAllRecipesUseCase(repository),
      _FakeGetConfigUsecase(),
    );
  });

  tearDown(() async {
    await bloc.close();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('loads every recipe A to Z, ignoring case', () async {
    await repository.saveRecipe(_recipe('1', 'pancakes'));
    await repository.saveRecipe(_recipe('2', 'Apple pie'));
    await repository.saveRecipe(_recipe('3', 'banana bread'));

    bloc.add(const LoadRecipeMealEvent(searchString: ''));

    final loaded = await bloc.stream.firstWhere(
      (s) => s is RecipeMealLoadedState,
    );
    expect(_names(loaded), ['Apple pie', 'banana bread', 'pancakes']);
    final meals = (loaded as RecipeMealLoadedState).recipes;
    expect(meals.every((m) => m.source == MealSourceEntity.recipe), isTrue);
    expect(meals.map((m) => m.code), ['2', '3', '1']);
  });

  test('an empty library loads as an empty list', () async {
    bloc.add(const LoadRecipeMealEvent(searchString: ''));

    final loaded = await bloc.stream.firstWhere(
      (s) => s is RecipeMealLoadedState,
    );
    expect(_names(loaded), isEmpty);
  });

  test('a query filters by name, ignoring case and spaces', () async {
    await repository.saveRecipe(_recipe('1', 'Lentil soup'));
    await repository.saveRecipe(_recipe('2', 'Pancakes'));

    bloc.add(const LoadRecipeMealEvent(searchString: '  SOUP '));

    final loaded = await bloc.stream.firstWhere(
      (s) => s is RecipeMealLoadedState,
    );
    expect(_names(loaded), ['Lentil soup']);
  });

  test('deleting a recipe reloads the list without it', () async {
    await repository.saveRecipe(_recipe('1', 'Lentil soup'));
    await repository.saveRecipe(_recipe('2', 'Pancakes'));
    bloc.add(const LoadRecipeMealEvent(searchString: ''));
    await bloc.stream.firstWhere((s) => s is RecipeMealLoadedState);

    final next = bloc.stream.firstWhere(
      (s) => s is RecipeMealLoadedState && _names(s).length == 1,
    );
    await repository.deleteRecipe('1');

    expect(_names(await next), ['Pancakes']);
  });

  test('a recipe saved elsewhere joins the list', () async {
    bloc.add(const LoadRecipeMealEvent(searchString: ''));
    await bloc.stream.firstWhere((s) => s is RecipeMealLoadedState);

    final next = bloc.stream.firstWhere(
      (s) => s is RecipeMealLoadedState && _names(s).isNotEmpty,
    );
    await repository.saveRecipe(_recipe('1', 'Lentil soup'));

    expect(_names(await next), ['Lentil soup']);
  });

  test('a change before the first load does not load on its own', () async {
    await repository.saveRecipe(_recipe('1', 'Lentil soup'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<RecipeMealInitial>());
  });

  test('recipes are the shared library, the same in every profile', () async {
    // The recipe box is global (HiveDBProvider.perProfileBoxNames leaves it
    // out), as on the Recipes page: a second profile picks from the same
    // recipes, and what it logs goes to its own diary.
    expect(
      HiveDBProvider.perProfileBoxNames,
      isNot(contains(HiveDBProvider.recipeBoxName)),
    );
    await repository.saveRecipe(_recipe('1', 'Lentil soup'));
    bloc.add(const LoadRecipeMealEvent(searchString: ''));
    await bloc.stream.firstWhere((s) => s is RecipeMealLoadedState);

    provider.activeProfileId = 'profile-b';
    bloc.add(const LoadRecipeMealEvent(searchString: ''));
    final loaded = await bloc.stream.firstWhere(
      (s) => s is RecipeMealLoadedState,
    );

    expect(_names(loaded), ['Lentil soup']);
  });

  test('a failed read reports failure', () async {
    await box.close();

    bloc.add(const LoadRecipeMealEvent(searchString: ''));

    expect(
      await bloc.stream.firstWhere((s) => s is! RecipeMealLoadingState),
      isA<RecipeMealFailedState>(),
    );
  });
}
