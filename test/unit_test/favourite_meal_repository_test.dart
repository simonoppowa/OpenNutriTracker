import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/favourite_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_favourite_meals_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/toggle_favourite_meal_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

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
    final provider = FakeHiveDBProvider(
      favouriteMealBox: favouriteBox,
      customMealBox: customMealBox,
      recipeBox: recipeBox,
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

  test('is a per-profile box', () {
    // #1307: favourites are this person's usual foods, so a profile switch
    // swaps them and deleting a profile takes them along.
    expect(
      HiveDBProvider.perProfileBoxNames,
      contains(HiveDBProvider.favouriteMealBoxName),
    );
  });
}
