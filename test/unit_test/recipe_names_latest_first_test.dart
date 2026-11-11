import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';

class _FakeRecipeDataSource implements RecipeDataSource {
  final List<RecipeDBO> recipes;

  _FakeRecipeDataSource(this.recipes);

  @override
  List<RecipeDBO> getAllRecipes() => recipes;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

RecipeDBO _recipe(String name, DateTime updatedAt) => RecipeDBO(
  id: name,
  name: name,
  description: null,
  ingredients: const [],
  totalWeightG: 100,
  aggregatedNutrimentsPer100: MealNutrimentsDBO(
    energyKcal100: 100,
    carbohydrates100: null,
    fat100: null,
    proteins100: null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: updatedAt,
  servingsCount: null,
  tags: null,
  imagePath: null,
);

void main() {
  test('recipe names come latest changed first', () {
    final repository = RecipeRepository(
      _FakeRecipeDataSource([
        _recipe('Borscht', DateTime.utc(2026, 3, 1)),
        _recipe('Pelmeni', DateTime.utc(2026, 5, 1)),
        _recipe('Grey peas with bacon', DateTime.utc(2026, 1, 1)),
      ]),
    );

    expect(repository.getRecipeNamesLatestFirst(), [
      'Pelmeni',
      'Borscht',
      'Grey peas with bacon',
    ]);
  });
}
