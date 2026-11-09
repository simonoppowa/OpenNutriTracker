import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_recent_ingredients_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';

/// #516: a food added to one recipe was not offered in the ingredient
/// picker's Recent tab when building the next one, because that tab only
/// listed foods that had been logged as intakes.
void main() {
  late Box<RecipeDBO> recipeBox;
  late IntakeRepository intakeRepo;
  late RecipeRepository recipeRepo;
  late GetRecentIngredientsUsecase usecase;

  GetRecentIngredientsUsecase usecaseFor(Box<IntakeDBO> intakeBox) {
    final provider = FakeHiveDBProvider(
      intakeBox: intakeBox,
      recipeBox: recipeBox,
    );
    final intakes = IntakeRepository(IntakeDataSource(provider));
    final recipes = RecipeRepository(RecipeDataSource(provider));
    return GetRecentIngredientsUsecase(
      GetIntakeUsecase(intakes, recipes),
      recipes,
    );
  }

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    registerHiveAdaptersOnce();
    recipeBox = await Hive.openBox<RecipeDBO>('recent_ingredients_recipe');
    final intakeBox = await Hive.openBox<IntakeDBO>(
      'recent_ingredients_intake',
    );
    final provider = FakeHiveDBProvider(
      intakeBox: intakeBox,
      recipeBox: recipeBox,
    );
    intakeRepo = IntakeRepository(IntakeDataSource(provider));
    recipeRepo = RecipeRepository(RecipeDataSource(provider));
    usecase = usecaseFor(intakeBox);
  });

  tearDown(() async => Hive.deleteFromDisk());

  MealEntity food(
    String name, {
    String? code,
    MealSourceEntity source = MealSourceEntity.off,
    double kcal = 100,
  }) => MealEntity(
    code: code,
    name: name,
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
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

  RecipeEntity recipe(
    String id,
    List<MealEntity> ingredients, {
    required DateTime updatedAt,
    String? name,
    double kcal = 90,
  }) => RecipeEntity(
    id: id,
    name: name ?? id,
    description: null,
    ingredients: [
      for (final meal in ingredients)
        RecipeIngredientEntity(
          snapshotMeal: meal,
          amount: 30,
          unit: 'g',
          convertedAmountG: 30,
        ),
    ],
    totalWeightG: 300,
    aggregatedNutrimentsPer100: MealNutrimentsEntity(
      energyKcal100: kcal,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    createdAt: updatedAt,
    updatedAt: updatedAt,
    servingsCount: null,
  );

  Future<void> log(
    String id,
    MealEntity meal,
    DateTime at, {
    IntakeRepository? repo,
  }) => (repo ?? intakeRepo).addIntake(
    IntakeEntity(
      id: id,
      unit: 'g',
      amount: 100,
      type: IntakeTypeEntity.lunch,
      meal: meal,
      dateTime: at,
    ),
  );

  List<String?> names(List<MealEntity> meals) =>
      meals.map((meal) => meal.name).toList();

  final protein = food('Protein powder XYZ', code: '4000000000001');
  final oats = food('Oats', code: '4000000000002');
  final milk = food('Milk', code: '4000000000003');

  test('with no recipes and nothing logged, nothing is offered', () async {
    expect(await usecase.getRecentIngredients(), isEmpty);
  });

  test('with no recipes, the logged foods are offered as before', () async {
    await log('a', oats, DateTime(2026, 10, 1));
    await log('b', milk, DateTime(2026, 10, 2));

    expect(names(await usecase.getRecentIngredients()), ['Milk', 'Oats']);
  });

  test(
    'an ingredient of a saved recipe is offered for the next recipe',
    () async {
      await recipeRepo.saveRecipe(
        recipe('shake', [protein], updatedAt: DateTime(2026, 10, 1)),
      );

      expect(names(await usecase.getRecentIngredients()), [
        'Protein powder XYZ',
      ]);
    },
  );

  test('an ingredient used in two recipes is offered once', () async {
    await recipeRepo.saveRecipe(
      recipe('shake', [protein, milk], updatedAt: DateTime(2026, 10, 1)),
    );
    await recipeRepo.saveRecipe(
      recipe('pancakes', [protein, oats], updatedAt: DateTime(2026, 10, 2)),
    );

    final offered = names(await usecase.getRecentIngredients());
    expect(offered.where((name) => name == 'Protein powder XYZ'), hasLength(1));
    expect(offered.toSet(), {'Protein powder XYZ', 'Oats', 'Milk'});
  });

  test('a food both logged and used in a recipe is offered once', () async {
    await log('a', protein, DateTime(2026, 10, 1));
    await recipeRepo.saveRecipe(
      recipe('shake', [protein], updatedAt: DateTime(2026, 10, 2)),
    );

    expect(names(await usecase.getRecentIngredients()), ['Protein powder XYZ']);
  });

  test(
    'the most recently used food comes first, logged or in a recipe',
    () async {
      await log('a', milk, DateTime(2026, 10, 1));
      await recipeRepo.saveRecipe(
        recipe('shake', [protein], updatedAt: DateTime(2026, 10, 2)),
      );
      await log('b', oats, DateTime(2026, 10, 3));

      expect(names(await usecase.getRecentIngredients()), [
        'Oats',
        'Protein powder XYZ',
        'Milk',
      ]);
    },
  );

  test('a recipe saved again moves its ingredients up', () async {
    await recipeRepo.saveRecipe(
      recipe('shake', [protein], updatedAt: DateTime(2026, 10, 1)),
    );
    await log('a', milk, DateTime(2026, 10, 2));
    await recipeRepo.saveRecipe(
      recipe('shake', [protein], updatedAt: DateTime(2026, 10, 3)),
    );

    expect(names(await usecase.getRecentIngredients()), [
      'Protein powder XYZ',
      'Milk',
    ]);
  });

  test(
    'ingredients of the same recipe keep the order the recipe lists them',
    () async {
      await recipeRepo.saveRecipe(
        recipe('porridge', [
          oats,
          milk,
          protein,
        ], updatedAt: DateTime(2026, 10)),
      );

      expect(names(await usecase.getRecentIngredients()), [
        'Oats',
        'Milk',
        'Protein powder XYZ',
      ]);
    },
  );

  test('a deleted recipe no longer offers its ingredients', () async {
    await recipeRepo.saveRecipe(
      recipe('shake', [protein], updatedAt: DateTime(2026, 10, 1)),
    );
    await recipeRepo.saveRecipe(
      recipe('porridge', [oats], updatedAt: DateTime(2026, 10, 2)),
    );
    await recipeRepo.deleteRecipe('shake');

    expect(names(await usecase.getRecentIngredients()), ['Oats']);
  });

  test('a deleted recipe still offers a food that was also logged', () async {
    await log('a', protein, DateTime(2026, 9, 1));
    await recipeRepo.saveRecipe(
      recipe('shake', [protein], updatedAt: DateTime(2026, 10, 1)),
    );
    await recipeRepo.deleteRecipe('shake');

    expect(names(await usecase.getRecentIngredients()), ['Protein powder XYZ']);
  });

  test('Quick Add and custom-meal ingredients without a barcode are offered, '
      'once per name', () async {
    final quickAdd = food('Homemade granola', source: MealSourceEntity.custom);
    await recipeRepo.saveRecipe(
      recipe('bowl', [quickAdd], updatedAt: DateTime(2026, 10, 1)),
    );
    await recipeRepo.saveRecipe(
      recipe('parfait', [quickAdd], updatedAt: DateTime(2026, 10, 2)),
    );

    final offered = await usecase.getRecentIngredients();
    expect(names(offered), ['Homemade granola']);
    expect(offered.single.source, MealSourceEntity.custom);
    expect(offered.single.code, isNull);
  });

  test('an ingredient whose source food no longer exists is offered as the '
      'recipe stored it', () async {
    // The custom-meal library entry it came from is gone (never saved in
    // this test's boxes), and the recipe's copy is all that is left.
    final gone = food(
      'Discontinued bar',
      code: 'custom-gone',
      source: MealSourceEntity.custom,
      kcal: 420,
    );
    await recipeRepo.saveRecipe(
      recipe('snack mix', [gone], updatedAt: DateTime(2026, 10, 1)),
    );

    final offered = (await usecase.getRecentIngredients()).single;
    expect(offered.name, 'Discontinued bar');
    expect(offered.nutriments.energyKcal100, 420);
  });

  test('a recipe used as an ingredient is offered as it is now', () async {
    final base = recipe(
      'base',
      [oats],
      updatedAt: DateTime(2026, 9, 1),
      name: 'Granola base',
    );
    await recipeRepo.saveRecipe(base);
    await recipeRepo.saveRecipe(
      recipe('bowl', [base.toMealEntity()], updatedAt: DateTime(2026, 10, 1)),
    );
    await recipeRepo.saveRecipe(
      recipe(
        'base',
        [oats],
        updatedAt: DateTime(2026, 9, 2),
        name: 'Toasted granola base',
        kcal: 150,
      ),
    );

    final offered = await usecase.getRecentIngredients();
    final nested = offered.firstWhere(
      (meal) => meal.source == MealSourceEntity.recipe,
    );
    expect(nested.name, 'Toasted granola base');
    expect(nested.nutriments.energyKcal100, 150);
  });

  test(
    'a deleted recipe used as an ingredient keeps its stored copy',
    () async {
      final base = recipe(
        'base',
        [oats],
        updatedAt: DateTime(2026, 9, 1),
        name: 'Granola base',
      );
      await recipeRepo.saveRecipe(
        recipe('bowl', [base.toMealEntity()], updatedAt: DateTime(2026, 10, 1)),
      );

      final offered = await usecase.getRecentIngredients();
      expect(names(offered), ['Granola base']);
    },
  );

  test("another profile's logged foods are not offered", () async {
    final otherProfile = await Hive.openBox<IntakeDBO>(
      'recent_ingredients_intake_other',
    );
    final otherRepo = IntakeRepository(
      IntakeDataSource(FakeHiveDBProvider(intakeBox: otherProfile)),
    );
    await log('other', milk, DateTime(2026, 10, 5), repo: otherRepo);
    await log('mine', oats, DateTime(2026, 10, 1));

    expect(names(await usecase.getRecentIngredients()), ['Oats']);
    expect(names(await usecaseFor(otherProfile).getRecentIngredients()), [
      'Milk',
    ]);
  });

  test(
    'recipe ingredients come from the recipe library every profile shares',
    () async {
      final otherProfile = await Hive.openBox<IntakeDBO>(
        'recent_ingredients_intake_other',
      );
      await recipeRepo.saveRecipe(
        recipe('shake', [protein], updatedAt: DateTime(2026, 10, 1)),
      );

      expect(names(await usecaseFor(otherProfile).getRecentIngredients()), [
        'Protein powder XYZ',
      ]);
    },
  );
}
