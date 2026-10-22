import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/favourite_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_favourite_meals_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/toggle_favourite_meal_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

class _FakeConfigRepository implements ConfigRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// No diary entries to move: these tests are about the favourites (#1417).
class _NoIntakesRepository implements IntakeRepository {
  @override
  Future<int> moveCustomMealInEveryProfile({
    required String fromMealKey,
    required MealDBO toMeal,
  }) async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

MealEntity _meal({
  required String? code,
  String name = 'Porridge',
  MealSourceEntity source = MealSourceEntity.off,
  double kcal = 100,
}) => MealEntity(
  code: code,
  name: name,
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal,
    carbohydrates100: null,
    fat100: null,
    proteins100: null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: source,
);

RecipeEntity _recipe({required String id, required String name}) =>
    RecipeEntity(
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

void main() {
  late Box<FavouriteMealDBO> favouriteBox;
  late Box<MealDBO> customMealBox;
  late Box<RecipeDBO> recipeBox;
  late Box<ProfileDBO> profileBox;
  late FavouriteMealDataSource dataSource;
  late FavouriteMealRepository repository;
  late GetFavouriteMealsUsecase getFavourites;
  late ToggleFavouriteMealUsecase toggleFavourite;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    final tag = DateTime.now().microsecondsSinceEpoch;
    favouriteBox = await Hive.openBox<FavouriteMealDBO>('favourites_$tag');
    customMealBox = await Hive.openBox<MealDBO>('favourites_custom_$tag');
    recipeBox = await Hive.openBox<RecipeDBO>('favourites_recipes_$tag');
    // The registry the cross-profile rewrite walks; only the active profile
    // here, so nothing else is opened.
    profileBox = await Hive.openBox<ProfileDBO>('favourites_profiles_$tag');
    final provider = FakeHiveDBProvider(
      favouriteMealBox: favouriteBox,
      customMealBox: customMealBox,
      recipeBox: recipeBox,
      profileBox: profileBox,
    );
    dataSource = FavouriteMealDataSource(provider);
    repository = FavouriteMealRepository(
      dataSource,
      CustomMealDataSource(provider),
      RecipeDataSource(provider),
    );
    getFavourites = GetFavouriteMealsUsecase(repository);
    toggleFavourite = ToggleFavouriteMealUsecase(repository);
  });

  tearDown(() async {
    await favouriteBox.deleteFromDisk();
    await customMealBox.deleteFromDisk();
    await recipeBox.deleteFromDisk();
    await profileBox.deleteFromDisk();
  });

  group('ToggleFavouriteMealUsecase', () {
    test('stars a meal, then unstars it', () async {
      final meal = _meal(code: '3017620422003');

      expect(await toggleFavourite.toggle(meal), isTrue);
      expect(await getFavourites.isFavourite(meal), isTrue);
      final all = await getFavourites.getAllFavourites();
      expect(all.map((m) => m.code), ['3017620422003']);

      expect(await toggleFavourite.toggle(meal), isFalse);
      expect(await getFavourites.isFavourite(meal), isFalse);
      expect(await getFavourites.getAllFavourites(), isEmpty);
    });

    test('works for a food that has never been logged', () async {
      // The point of #1307: nothing in the intake box is needed.
      await toggleFavourite.toggle(_meal(code: '42'));

      expect(favouriteBox.length, 1);
    });
  });

  group('identity', () {
    test('the same food starred from two places is one favourite', () async {
      // A search hit and its hydrated detail-page record share source and
      // code but not their nutriments.
      await repository.addFavourite(_meal(code: '123', kcal: 100));
      await repository.addFavourite(_meal(code: '123', kcal: 120));

      final all = await repository.getAllFavourites();
      expect(all, hasLength(1));
      expect(all.single.nutriments.energyKcal100, 120);
    });

    test(
      'a backend id never collides with a barcode of the same digits',
      () async {
        final off = _meal(code: '123', source: MealSourceEntity.off);
        final backend = _meal(code: '123', source: MealSourceEntity.fdc);

        await repository.addFavourite(off);

        expect(await repository.isFavourite(off), isTrue);
        expect(await repository.isFavourite(backend), isFalse);
      },
    );

    test('a legacy custom meal without a code is keyed by its name', () async {
      final soup = _meal(
        code: null,
        name: 'Soup',
        source: MealSourceEntity.custom,
      );

      await repository.addFavourite(soup);

      expect(favouriteBox.keys, ['custom:Soup']);
      expect(await repository.isFavourite(soup), isTrue);
    });

    group('a name too long for a Hive key', () {
      // Hive writes a string key's length in one byte: 255 UTF-8 bytes.
      // 'custom:' plus 249 ASCII characters is 256; 100 three-byte
      // characters are 300 bytes in only 100 UTF-16 units, which Hive's own
      // length check (in UTF-16 units) lets through and then writes wrong.
      final longAscii = 'a' * 249;
      final longMultibyte = '寿' * 100;

      for (final (label, name) in [
        ('ASCII', longAscii),
        ('multibyte', longMultibyte),
      ]) {
        test('stars a $label name, and it survives reopening the box', () async {
          final meal = _meal(
            code: null,
            name: name,
            source: MealSourceEntity.custom,
          );
          expect(utf8.encode('custom:$name').length, greaterThan(255));

          expect(await toggleFavourite.toggle(meal), isTrue);
          expect(await repository.isFavourite(meal), isTrue);
          final key = favouriteBox.keys.single as String;
          expect(key, startsWith('custom#'));
          expect(utf8.encode(key).length, lessThanOrEqualTo(255));
          expect(key, FavouriteMealRepository.keyOf(meal));

          // Read back from disk: a key Hive wrote wrong corrupts the frame.
          final name0 = favouriteBox.name;
          await favouriteBox.close();
          favouriteBox = await Hive.openBox<FavouriteMealDBO>(name0);
          expect(favouriteBox.keys, [key]);
          expect(favouriteBox.get(key)!.meal.name, name);
        });
      }

      test('two names that differ only at the end are two favourites', () async {
        await repository.addFavourite(
          _meal(code: null, name: '${longAscii}x', source: MealSourceEntity.custom),
        );
        await repository.addFavourite(
          _meal(code: null, name: '${longAscii}y', source: MealSourceEntity.custom),
        );

        expect(favouriteBox.length, 2);
        final names = (await repository.getAllFavourites()).map((m) => m.name);
        expect(names, unorderedEquals(['${longAscii}x', '${longAscii}y']));
      });

      test('an import or an edit of one keeps a single entry', () async {
        final meal = _meal(
          code: null,
          name: longMultibyte,
          source: MealSourceEntity.custom,
        );
        await repository.addFavourite(meal);
        final exported = await repository.getAllFavouritesDBO();

        await repository.addAllFavouriteDBOs(exported);
        await repository.addAllFavouriteDBOs(exported);
        expect(favouriteBox.length, 1);

        // Renaming the meal moves it to the new name's key.
        final renamed = _meal(
          code: null,
          name: '$longMultibyte!',
          source: MealSourceEntity.custom,
        );
        await repository.moveFavourite(meal, renamed);
        expect(favouriteBox.keys, [FavouriteMealRepository.keyOf(renamed)]);
        expect(await repository.isFavourite(meal), isFalse);
        expect(await repository.isFavourite(renamed), isTrue);
      });

      test('a key that fits is used as is', () {
        final name = 'b' * 248; // 'custom:' + 248 = 255 bytes
        expect(
          FavouriteMealDBO.keyFor(MealSourceDBO.custom, null, name),
          'custom:$name',
        );
      });
    });

    test('matches the key search deduplicates on', () {
      final meal = _meal(code: '987', source: MealSourceEntity.recipe);

      expect(FavouriteMealRepository.keyOf(meal), 'recipe:987');
      expect(
        FavouriteMealDBO(
          meal: MealDBO.fromMealEntity(meal),
          addedAt: DateTime(2026),
        ).mealKey,
        FavouriteMealRepository.keyOf(meal),
      );
    });
  });

  test('lists the most recently starred first', () async {
    await dataSource.addFavourite(
      FavouriteMealDBO(
        meal: MealDBO.fromMealEntity(_meal(code: 'old', name: 'Old')),
        addedAt: DateTime(2026, 1, 1),
      ),
    );
    await dataSource.addFavourite(
      FavouriteMealDBO(
        meal: MealDBO.fromMealEntity(_meal(code: 'new', name: 'New')),
        addedAt: DateTime(2026, 6, 1),
      ),
    );

    final names = (await repository.getAllFavourites()).map((m) => m.name);
    expect(names, ['New', 'Old']);
  });

  group('own meals', () {
    test('a custom meal is read from the library after an edit', () async {
      final original = _meal(
        code: 'c1',
        name: 'Overnight oats',
        source: MealSourceEntity.custom,
        kcal: 150,
      );
      await customMealBox.add(MealDBO.fromMealEntity(original));
      await repository.addFavourite(original);

      // The user corrects the macros on the saved meal afterwards.
      await CustomMealDataSource(
        FakeHiveDBProvider(customMealBox: customMealBox),
      ).saveCustomMeal(
        MealDBO.fromMealEntity(
          _meal(
            code: 'c1',
            name: 'Overnight oats',
            source: MealSourceEntity.custom,
            kcal: 180,
          ),
        ),
      );

      final all = await repository.getAllFavourites();
      expect(all.single.nutriments.energyKcal100, 180);
    });

    test('a custom meal given a barcode in an edit stays starred', () async {
      final original = _meal(
        code: 'c1',
        name: 'Overnight oats',
        source: MealSourceEntity.custom,
        kcal: 150,
      );
      await customMealBox.add(MealDBO.fromMealEntity(original));
      await repository.addFavourite(original);
      final starredAt = favouriteBox.get('custom:c1')!.addedAt;

      // The edit form swaps the code for the barcode the user typed.
      final edited = _meal(
        code: '4006381333931',
        name: 'Overnight oats',
        source: MealSourceEntity.custom,
        kcal: 180,
      );
      final bloc = EditMealBloc(
        _FakeGetConfigUsecase(),
        CustomMealDataSource(FakeHiveDBProvider(customMealBox: customMealBox)),
        _FakeConfigRepository(),
        repository,
        _NoIntakesRepository(),
      );
      await bloc.saveCustomMeal(edited, previous: original);
      await bloc.close();

      expect(favouriteBox.keys, ['custom:4006381333931']);
      expect(favouriteBox.get('custom:4006381333931')!.addedAt, starredAt);
      expect(await repository.isFavourite(edited), isTrue);
      expect(await repository.isFavourite(original), isFalse);
      final all = await repository.getAllFavourites();
      expect(all.single.code, '4006381333931');
      expect(all.single.nutriments.energyKcal100, 180);

      // An export taken now, imported back twice, keeps the one entry.
      final exported = [
        for (final f in await repository.getAllFavouritesDBO())
          FavouriteMealDBO.fromJson(
            jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>,
          ),
      ];
      await repository.addAllFavouriteDBOs(exported);
      await repository.addAllFavouriteDBOs(exported);
      expect(favouriteBox.keys, ['custom:4006381333931']);
    });

    test('an edit that keeps the code refreshes the snapshot', () async {
      final meal = _meal(code: 'c1', source: MealSourceEntity.custom);
      await repository.addFavourite(meal);
      final starredAt = favouriteBox.get('custom:c1')!.addedAt;

      await repository.moveFavourite(
        meal,
        _meal(code: 'c1', source: MealSourceEntity.custom, kcal: 5),
      );
      await repository.moveFavourite(
        _meal(code: 'c9', source: MealSourceEntity.custom),
        _meal(code: 'c10', source: MealSourceEntity.custom),
      );

      expect(favouriteBox.keys, ['custom:c1']);
      expect(favouriteBox.get('custom:c1')!.addedAt, starredAt);
      expect(favouriteBox.get('custom:c1')!.meal.nutriments.energyKcal100, 5);
    });

    test('a deleted custom meal keeps its latest edited snapshot', () async {
      final original = _meal(
        code: 'c1',
        name: 'Overnight oats',
        source: MealSourceEntity.custom,
        kcal: 150,
      );
      await customMealBox.add(MealDBO.fromMealEntity(original));
      await repository.addFavourite(original);
      final edited = _meal(
        code: 'c1',
        name: 'Updated overnight oats',
        source: MealSourceEntity.custom,
        kcal: 180,
      );
      final bloc = EditMealBloc(
        _FakeGetConfigUsecase(),
        CustomMealDataSource(FakeHiveDBProvider(customMealBox: customMealBox)),
        _FakeConfigRepository(),
        repository,
        _NoIntakesRepository(),
      );
      await bloc.saveCustomMeal(edited, previous: original);
      await bloc.close();

      await CustomMealDataSource(
        FakeHiveDBProvider(customMealBox: customMealBox),
      ).deleteCustomMeal('c1');

      final restored = await repository.getAllFavourites();
      expect(restored.single.name, 'Updated overnight oats');
      expect(restored.single.nutriments.energyKcal100, 180);
      final exported = await repository.getAllFavouritesDBO();
      expect(exported.single.meal.name, 'Updated overnight oats');
      expect(exported.single.meal.nutriments.energyKcal100, 180);
    });

    test(
      'a library delete keeps the version an import last wrote, not the star-time one',
      () async {
        final original = _meal(
          code: 'c1',
          name: 'Overnight oats',
          source: MealSourceEntity.custom,
          kcal: 150,
        );
        final library = CustomMealDataSource(
          FakeHiveDBProvider(customMealBox: customMealBox),
        );
        await library.saveCustomMeal(MealDBO.fromMealEntity(original));
        await repository.addFavourite(original);
        final starredAt = favouriteBox.get('custom:c1')!.addedAt;

        // A meal import overwrites the saved meal without the edit form, so
        // the favourite's snapshot is still the one from starring it.
        await library.saveCustomMeal(
          MealDBO.fromMealEntity(
            _meal(
              code: 'c1',
              name: 'Imported oats',
              source: MealSourceEntity.custom,
              kcal: 210,
            ),
          ),
        );
        expect(favouriteBox.get('custom:c1')!.meal.name, 'Overnight oats');

        // What the custom-meals screen runs before deleting it.
        await repository.keepLatestCustomMealSnapshot('c1');
        await library.deleteCustomMeal('c1');

        final restored = await repository.getAllFavourites();
        expect(restored.single.name, 'Imported oats');
        expect(restored.single.nutriments.energyKcal100, 210);
        expect(favouriteBox.get('custom:c1')!.addedAt, starredAt);
      },
    );

    test('a library delete of an unstarred meal stars nothing', () async {
      final library = CustomMealDataSource(
        FakeHiveDBProvider(customMealBox: customMealBox),
      );
      await library.saveCustomMeal(
        MealDBO.fromMealEntity(
          _meal(code: 'c3', source: MealSourceEntity.custom),
        ),
      );

      await repository.keepLatestCustomMealSnapshot('c3');

      expect(favouriteBox.isEmpty, isTrue);
    });

    test('several starred recipes each resolve from the library', () async {
      for (final id in ['r1', 'r2', 'r3']) {
        await recipeBox.add(_recipe(id: id, name: 'Recipe $id').toDBO());
        await repository.addFavourite(
          _meal(code: id, name: 'Old $id', source: MealSourceEntity.recipe),
        );
      }

      final names = (await repository.getAllFavourites()).map((m) => m.name);
      expect(names, unorderedEquals(['Recipe r1', 'Recipe r2', 'Recipe r3']));
    });

    test('a custom meal deleted from the library stays on the list', () async {
      final meal = _meal(
        code: 'c2',
        name: 'Lunchbox',
        source: MealSourceEntity.custom,
      );
      await repository.addFavourite(meal);

      final all = await repository.getAllFavourites();
      expect(all.single.name, 'Lunchbox');
    });

    test('a recipe is read from the library after an edit', () async {
      final recipe = _recipe(id: 'r1', name: 'Chili');
      await recipeBox.add(recipe.toDBO());
      await repository.addFavourite(recipe.toMealEntity());

      await RecipeDataSource(
        FakeHiveDBProvider(recipeBox: recipeBox),
      ).saveRecipe(recipe.copyWith(name: 'Chili con carne').toDBO());

      final all = await repository.getAllFavourites();
      expect(all.single.name, 'Chili con carne');
      expect(all.single.source, MealSourceEntity.recipe);
    });
  });

  test('watchFavourites fires on a toggle', () async {
    final events = <void>[];
    final sub = getFavourites.watchFavourites().listen(events.add);

    await toggleFavourite.toggle(_meal(code: 'w'));
    await toggleFavourite.toggle(_meal(code: 'w'));
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(2));
    await sub.cancel();
  });

  test('watchFavourites fires on a custom meal or recipe edit', () async {
    // The list reads both libraries in place of its snapshots, so an edit
    // there changes what it shows.
    final events = <void>[];
    final sub = getFavourites.watchFavourites().listen(events.add);

    await CustomMealDataSource(
      FakeHiveDBProvider(customMealBox: customMealBox),
    ).saveCustomMeal(
      MealDBO.fromMealEntity(
        _meal(code: 'c', name: 'Soup', source: MealSourceEntity.custom),
      ),
    );
    await RecipeDataSource(
      FakeHiveDBProvider(recipeBox: recipeBox),
    ).saveRecipe(_recipe(id: 'r', name: 'Chili').toDBO());
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(2));
    await sub.cancel();
  });

  test(
    'an open Favourites list follows an edit to a starred custom meal',
    () async {
      final original = _meal(
        code: 'c3',
        name: 'Overnight oats',
        source: MealSourceEntity.custom,
        kcal: 150,
      );
      await customMealBox.add(MealDBO.fromMealEntity(original));
      await repository.addFavourite(original);
      final bloc = FavouriteMealBloc(getFavourites, _FakeGetConfigUsecase());
      bloc.add(const LoadFavouriteMealEvent(searchString: ''));
      await bloc.stream.firstWhere((s) => s is FavouriteMealLoadedState);
      final reload = bloc.stream
          .firstWhere((s) => s is FavouriteMealLoadedState)
          .timeout(const Duration(seconds: 5));

      // Edited from its detail page, opened from the Favourites tab that is
      // still on the route stack underneath.
      await CustomMealDataSource(
        FakeHiveDBProvider(customMealBox: customMealBox),
      ).saveCustomMeal(
        MealDBO.fromMealEntity(
          _meal(
            code: 'c3',
            name: 'Overnight oats',
            source: MealSourceEntity.custom,
            kcal: 180,
          ),
        ),
      );

      final updated = await reload;
      final favourites = (updated as FavouriteMealLoadedState).favourites;
      expect(favourites.single.nutriments.energyKcal100, 180);
      await bloc.close();
    },
  );

  test('is a per-profile box', () {
    // #1307: favourites are this person's usual foods, so a profile switch
    // swaps them and deleting a profile takes them along.
    expect(
      HiveDBProvider.perProfileBoxNames,
      contains(HiveDBProvider.favouriteMealBoxName),
    );
  });
}
