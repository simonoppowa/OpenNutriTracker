import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';

class _FakeRecipeRepository implements RecipeRepository {
  final List<RecipeEntity> saved = [];

  @override
  Future<void> saveRecipe(RecipeEntity recipe) async {
    saved.add(recipe);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

MealEntity _meal(String code, {double kcal = 100}) {
  return MealEntity(
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
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: MealSourceEntity.off,
  );
}

void main() {
  late ComputeRecipeNutritionUseCase compute;
  late _FakeRecipeRepository repo;
  late SaveRecipeUseCase save;
  late RecipeBuilderBloc bloc;

  setUp(() {
    compute = ComputeRecipeNutritionUseCase();
    repo = _FakeRecipeRepository();
    save = SaveRecipeUseCase(repo, compute);
    bloc = RecipeBuilderBloc(compute, save);
  });

  tearDown(() => bloc.close());

  group('RecipeBuilderBloc', () {
    test('initial state has no id, empty name, empty ingredients', () {
      expect(bloc.state.id, isNull);
      expect(bloc.state.name, '');
      expect(bloc.state.ingredients, isEmpty);
      expect(bloc.state.isExistingRecipe, isFalse);
    });

    test('AddIngredientEvent recomputes total weight + per-100g nutrition',
        () async {
      bloc.add(AddIngredientEvent(
        meal: _meal('flour', kcal: 340),
        amount: 100,
        unit: 'g',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.ingredients, hasLength(1));
      expect(bloc.state.totalWeightG, 100);
      expect(
          bloc.state.aggregatedNutrimentsPer100.energyKcal100, closeTo(340, 0.01));
    });

    test('save with empty name emits nameRequired error', () async {
      bloc.add(const SaveRecipeEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.saveError, SaveError.nameRequired);
      expect(repo.saved, isEmpty);
    });

    test('save with no ingredients emits needsIngredients error', () async {
      bloc.add(const UpdateNameEvent('Cake'));
      bloc.add(const SaveRecipeEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.saveError, SaveError.needsIngredients);
      expect(repo.saved, isEmpty);
    });

    test('save with explicit zero total weight emits invalidTotalWeight',
        () async {
      bloc.add(const UpdateNameEvent('Cake'));
      bloc.add(AddIngredientEvent(
        meal: _meal('flour', kcal: 340),
        amount: 100,
        unit: 'g',
      ));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const UpdateTotalWeightEvent(0));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SaveRecipeEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.saveError, SaveError.invalidTotalWeight);
      expect(repo.saved, isEmpty);
    });

    test('successful save persists and emits didSave', () async {
      bloc.add(const UpdateNameEvent('Cake'));
      bloc.add(AddIngredientEvent(
        meal: _meal('flour', kcal: 340),
        amount: 100,
        unit: 'g',
      ));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SaveRecipeEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.didSave, isTrue);
      expect(bloc.state.saveError, isNull);
      expect(repo.saved, hasLength(1));
      expect(repo.saved.single.name, 'Cake');
      expect(repo.saved.single.id, isNotEmpty);
    });

    test('initialize with existing recipe sets isExistingRecipe', () async {
      final existing = RecipeEntity(
        id: 'existing-1',
        name: 'Original',
        description: null,
        ingredients: const [],
        totalWeightG: 100,
        aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
        servingsCount: null,
      );
      bloc.add(InitializeBuilderEvent(existing: existing));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isExistingRecipe, isTrue);
      expect(bloc.state.id, 'existing-1');
      expect(bloc.state.name, 'Original');
    });

    test('initialize with empty-id recipe (duplicate sentinel) treats as create',
        () async {
      final duplicate = RecipeEntity(
        id: '',
        name: 'Cake (copy)',
        description: null,
        ingredients: const [],
        totalWeightG: 100,
        aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
        servingsCount: null,
      );
      bloc.add(InitializeBuilderEvent(existing: duplicate));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isExistingRecipe, isFalse);
      expect(bloc.state.id, isNull);
      expect(bloc.state.name, 'Cake (copy)');
    });

    // #1277: reopening a recipe whose total weight was entered by hand reset
    // it to the ingredient sum, and the next save persisted the reset.
    group('reopening a recipe with a manually entered total weight', () {
      RecipeEntity savedRecipe({required double totalWeightG}) {
        return RecipeEntity(
          id: 'soup-1',
          name: 'Soup',
          description: null,
          ingredients: [
            RecipeIngredientEntity(
              snapshotMeal: _meal('stock', kcal: 90),
              amount: 800,
              unit: 'g',
              convertedAmountG: 800,
            ),
          ],
          totalWeightG: totalWeightG,
          aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
          createdAt: DateTime.utc(2024, 1, 1),
          updatedAt: DateTime.utc(2024, 1, 1),
          servingsCount: null,
        );
      }

      test('keeps the saved weight instead of the ingredient sum', () async {
        bloc.add(InitializeBuilderEvent(
          existing: savedRecipe(totalWeightG: 720),
        ));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.totalWeightG, 720);
        expect(bloc.state.totalWeightOverridden, isTrue);
        // 800 g at 90 kcal/100 g = 720 kcal, spread over 720 g.
        expect(bloc.state.aggregatedNutrimentsPer100.energyKcal100, 100);
      });

      test('saving without touching the weight persists the saved weight',
          () async {
        bloc.add(InitializeBuilderEvent(
          existing: savedRecipe(totalWeightG: 720),
        ));
        bloc.add(const UpdateNameEvent('Soup, renamed'));
        bloc.add(const SaveRecipeEvent());
        await Future<void>.delayed(Duration.zero);

        expect(repo.saved.single.totalWeightG, 720);
        expect(
          repo.saved.single.aggregatedNutrimentsPer100.energyKcal100,
          100,
        );
      });

      test('a weight equal to the sum still follows ingredient edits',
          () async {
        bloc.add(InitializeBuilderEvent(
          existing: savedRecipe(totalWeightG: 800),
        ));
        bloc.add(AddIngredientEvent(
          meal: _meal('noodles', kcal: 350),
          amount: 100,
          unit: 'g',
        ));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.totalWeightOverridden, isFalse);
        expect(bloc.state.totalWeightG, 900);
      });
    });
  });
}
