import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
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

class _NoOpIntakeRepository implements IntakeRepository {
  @override
  Future<List<(IntakeEntity, IntakeEntity)>> remapRecipeOnIntakes({
    required String recipeId,
    required MealDBO toMeal,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value([]);
}

class _NoOpAddTrackedDayUsecase implements AddTrackedDayUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value();
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
    save = SaveRecipeUseCase(
      repo, compute, _NoOpIntakeRepository(), _NoOpAddTrackedDayUsecase(),
    );
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
  });
}
