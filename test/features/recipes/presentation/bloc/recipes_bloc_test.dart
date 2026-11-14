import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_all_recipes_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipes_bloc.dart';

class _FakeGetAllRecipesUseCase implements GetAllRecipesUseCase {
  List<RecipeEntity> recipes = [];
  bool throwOnGetAll = false;

  @override
  List<RecipeEntity> getAll() {
    if (throwOnGetAll) {
      throw StateError('fake failure');
    }
    return recipes;
  }

  @override
  Stream<void> watch() => const Stream.empty();
}

RecipeEntity _recipe({
  required String id,
  required String name,
  required DateTime updatedAt,
}) {
  return RecipeEntity(
    id: id,
    name: name,
    description: null,
    ingredients: const [],
    totalWeightG: 100,
    aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
    createdAt: updatedAt,
    updatedAt: updatedAt,
    servingsCount: null,
  );
}

void main() {
  group('RecipesBloc', () {
    late _FakeGetAllRecipesUseCase useCase;
    late RecipesBloc bloc;

    setUp(() {
      useCase = _FakeGetAllRecipesUseCase();
      bloc = RecipesBloc(useCase);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state', () {
      expect(bloc.state, isA<RecipesInitial>());
    });

    test('LoadRecipesEvent emits Loaded with most-recently-updated first',
        () async {
      useCase.recipes = [
        _recipe(
            id: 'a',
            name: 'Old',
            updatedAt: DateTime.utc(2024, 1, 1)),
        _recipe(
            id: 'b',
            name: 'New',
            updatedAt: DateTime.utc(2025, 6, 1)),
        _recipe(
            id: 'c',
            name: 'Middle',
            updatedAt: DateTime.utc(2024, 8, 1)),
      ];

      bloc.add(const LoadRecipesEvent());
      // Drain the stream until we see the loaded state, then assert.
      await bloc.stream.firstWhere((s) => s is RecipesLoaded);
      final loaded = bloc.state as RecipesLoaded;
      expect(
        loaded.recipes.map((r) => r.id).toList(),
        ['b', 'c', 'a'],
      );
    });

    test('LoadRecipesEvent emits Failed when use case throws', () async {
      useCase.throwOnGetAll = true;

      bloc.add(const LoadRecipesEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RecipesLoading>(),
          isA<RecipesFailed>(),
        ]),
      );
    });

    test('LoadRecipesEvent on empty store emits Loaded with empty list',
        () async {
      bloc.add(const LoadRecipesEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RecipesLoading>(),
          predicate<RecipesLoaded>((s) => s.recipes.isEmpty),
        ]),
      );
    });
  });
}
