import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';

import '../../../helpers/fake_hive_db_provider.dart';
import '../../../helpers/hive_test_setup.dart';

MealEntity _food(String code, {required double kcal, double? protein}) =>
    MealEntity(
      code: code,
      name: code,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: MealNutrimentsEntity(
        energyKcal100: kcal,
        carbohydrates100: null,
        fat100: null,
        proteins100: protein,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.off,
    );

RecipeIngredientEntity _ingredient(MealEntity meal, double grams) =>
    RecipeIngredientEntity(
      snapshotMeal: meal,
      amount: grams,
      unit: 'g',
      convertedAmountG: grams,
    );

/// 600 g pasta at 350 kcal and 400 g sauce at 50 kcal: 1000 g raw with
/// 2300 kcal, 230 kcal per 100 g.
RecipeEntity _recipe({String id = 'r1', int? servings, String? imagePath}) =>
    RecipeEntity(
      id: id,
      name: 'Pasta',
      description: null,
      ingredients: [
        _ingredient(_food('pasta', kcal: 350, protein: 12), 600),
        _ingredient(_food('sauce', kcal: 50, protein: 2), 400),
      ],
      totalWeightG: 1000,
      aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
      servingsCount: servings,
      imagePath: imagePath,
    );

void main() {
  final compute = ComputeRecipeNutritionUseCase();

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  group('a logged recipe', () {
    late Box<RecipeDBO> recipeBox;
    late Box<IntakeDBO> intakeBox;
    late RecipeRepository recipes;
    late IntakeDataSource intakes;

    setUp(() async {
      Hive.init('.');
      recipeBox = await Hive.openBox<RecipeDBO>('recipe_regression_recipes');
      intakeBox = await Hive.openBox<IntakeDBO>('recipe_regression_intakes');
      final db = FakeHiveDBProvider(recipeBox: recipeBox, intakeBox: intakeBox);
      recipes = RecipeRepository(RecipeDataSource(db));
      intakes = IntakeDataSource(db);
    });

    tearDown(() => Hive.deleteFromDisk());

    test(
      'keeps its diary entry when the recipe changes or is deleted',
      () async {
        final save = SaveRecipeUseCase(recipes, compute);
        final saved = await save.save(_recipe(servings: 4));
        await intakes.addIntake(
          IntakeDBO.fromIntakeEntity(
            IntakeEntity(
              id: 'i1',
              unit: 'serving',
              amount: 1,
              type: IntakeTypeEntity.dinner,
              meal: saved.toMealEntity(),
              dateTime: DateTime(2026, 10, 2, 19),
            ),
          ),
        );

        await save.save(
          saved.copyWith(
            servingsCount: 2,
            ingredients: [_ingredient(_food('pasta', kcal: 350), 200)],
          ),
        );
        await recipes.deleteRecipe(saved.id);

        final logged = (await intakes.getIntakeById('i1'))!;
        expect(logged.meal.nutriments.energyKcal100, closeTo(230, 1e-9));
        expect(logged.meal.nutriments.proteins100, closeTo(8, 1e-9));
        expect(logged.meal.servingQuantity, closeTo(250, 1e-9));
        expect(logged.meal.mealQuantity, '1000.0');
        expect(logged.amount, 1);
        expect(recipes.getRecipeById(saved.id), isNull);
      },
    );
  });

  group('portions', () {
    test('one portion is the total weight divided by the portions', () {
      final meal = _recipe(servings: 4).toMealEntity();

      expect(meal.servingQuantity, 250);
      expect(meal.servingUnit, 'g');
    });

    test('follow the weight after cooking', () {
      final meal = _recipe(
        servings: 4,
      ).copyWith(totalWeightG: 800).toMealEntity();

      expect(meal.servingQuantity, 200);
    });

    test('without portions there is no serving to pick', () {
      final meal = _recipe().toMealEntity();

      expect(meal.servingQuantity, isNull);
      expect(meal.servingUnit, isNull);
    });
  });

  group('weight after cooking', () {
    test('1000 g raw, 800 g cooked scales per 100 g by 1000/800', () {
      final raw = compute.compute(_recipe().ingredients);
      final cooked = compute.compute(
        _recipe().ingredients,
        totalWeightOverride: 800,
      );

      expect(raw.perHundredG.energyKcal100, closeTo(230, 1e-9));
      expect(cooked.totalWeightG, 800);
      expect(cooked.perHundredG.energyKcal100, closeTo(230 * 1000 / 800, 1e-9));
      expect(
        cooked.perHundredG.proteins100,
        closeTo(raw.perHundredG.proteins100! * 1000 / 800, 1e-9),
      );
    });

    test(
      'saving with the cooked weight stores it and the scaled values',
      () async {
        final repo = _MemoryRecipeRepository();

        final saved = await SaveRecipeUseCase(repo, compute).save(
          _recipe().copyWith(totalWeightG: 800),
          totalWeightOverridden: true,
        );

        expect(saved.totalWeightG, 800);
        expect(
          saved.aggregatedNutrimentsPer100.energyKcal100,
          closeTo(287.5, 1e-9),
        );
      },
    );
  });

  group('duplicating', () {
    test('saves a new recipe with a new id and without the photo', () async {
      final repo = _MemoryRecipeRepository();
      final bloc = RecipeBuilderBloc(compute, SaveRecipeUseCase(repo, compute));
      addTearDown(bloc.close);
      final original = _recipe(
        id: 'original',
        servings: 4,
        imagePath: 'recipe_images/original.webp',
      );

      bloc.add(
        InitializeBuilderEvent(
          existing: RecipeEntity(
            id: '',
            name: '${original.name} (copy)',
            description: original.description,
            ingredients: original.ingredients,
            totalWeightG: original.totalWeightG,
            aggregatedNutrimentsPer100: original.aggregatedNutrimentsPer100,
            createdAt: original.createdAt,
            updatedAt: original.updatedAt,
            servingsCount: original.servingsCount,
            imagePath: original.imagePath,
          ),
        ),
      );
      bloc.add(const SaveRecipeEvent());
      await bloc.stream.firstWhere((state) => repo.saved.isNotEmpty);

      final copy = repo.saved.single;
      expect(copy.id, isNot(anyOf('', 'original')));
      expect(copy.imagePath, isNull);
      expect(copy.name, 'Pasta (copy)');
      expect(copy.ingredients, original.ingredients);
      expect(copy.servingsCount, 4);
    });
  });
}

class _MemoryRecipeRepository implements RecipeRepository {
  final List<RecipeEntity> saved = [];

  @override
  Future<void> saveRecipe(RecipeEntity recipe) async => saved.add(recipe);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
