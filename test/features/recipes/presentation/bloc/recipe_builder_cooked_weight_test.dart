import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';

class _MemoryRepository implements RecipeRepository {
  final saved = <RecipeEntity>[];

  @override
  Future<void> saveRecipe(RecipeEntity recipe) async => saved.add(recipe);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

RecipeEntity _soup({double totalWeightG = 800}) => RecipeEntity(
  id: 'soup',
  name: 'Soup',
  description: null,
  ingredients: [
    RecipeIngredientEntity(
      snapshotMeal: MealEntity(
        code: 'veg',
        name: 'veg',
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: null,
        servingSize: null,
        nutriments: MealNutrimentsEntity(
          energyKcal100: 100,
          carbohydrates100: null,
          fat100: null,
          proteins100: null,
          sugars100: null,
          saturatedFat100: null,
          fiber100: null,
        ),
        source: MealSourceEntity.off,
      ),
      amount: 1000,
      unit: 'g',
      convertedAmountG: 1000,
    ),
  ],
  totalWeightG: totalWeightG,
  aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  servingsCount: null,
);

void main() {
  late RecipeBuilderBloc bloc;
  late _MemoryRepository repo;

  setUp(() {
    final compute = ComputeRecipeNutritionUseCase();
    repo = _MemoryRepository();
    bloc = RecipeBuilderBloc(compute, SaveRecipeUseCase(repo, compute));
  });

  tearDown(() => bloc.close());

  test('the raw weight is the sum of the ingredients', () async {
    bloc.add(InitializeBuilderEvent(existing: _soup()));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.rawWeightG, 1000);
    expect(bloc.state.totalWeightG, 800);
  });

  test('resetting the cooked weight goes back to the raw weight', () async {
    bloc.add(InitializeBuilderEvent(existing: _soup()));
    bloc.add(const ResetTotalWeightEvent());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.totalWeightOverridden, isFalse);
    expect(bloc.state.totalWeightG, 1000);
    expect(
      bloc.state.aggregatedNutrimentsPer100.energyKcal100,
      closeTo(100, 1e-9),
    );
  });

  test('a reset never shows the cooked weight as the raw one', () async {
    bloc.add(InitializeBuilderEvent(existing: _soup()));
    await Future<void>.delayed(Duration.zero);
    final seen = <(bool, double)>[];
    final sub = bloc.stream.listen(
      (state) => seen.add((state.totalWeightOverridden, state.totalWeightG)),
    );

    bloc.add(const ResetTotalWeightEvent());
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen, [(false, 1000.0)]);
  });

  test('a reset and save stores the raw weight and its values', () async {
    bloc.add(InitializeBuilderEvent(existing: _soup()));
    bloc.add(const ResetTotalWeightEvent());
    bloc.add(const SaveRecipeEvent());
    await bloc.stream.firstWhere((_) => repo.saved.isNotEmpty);

    final saved = repo.saved.single;
    expect(saved.totalWeightG, 1000);
    expect(saved.aggregatedNutrimentsPer100.energyKcal100, closeTo(100, 1e-9));

    final reopened = RecipeBuilderBloc(
      ComputeRecipeNutritionUseCase(),
      SaveRecipeUseCase(repo, ComputeRecipeNutritionUseCase()),
    );
    addTearDown(reopened.close);
    reopened.add(InitializeBuilderEvent(existing: saved));
    await Future<void>.delayed(Duration.zero);
    expect(reopened.state.totalWeightOverridden, isFalse);
  });

  test('a stored weight of zero is no cooked weight', () async {
    bloc.add(InitializeBuilderEvent(existing: _soup(totalWeightG: 0)));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.totalWeightOverridden, isFalse);
    expect(bloc.state.totalWeightG, 1000);
  });
}
