import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/csv_recipe_importer.dart';

void main() {
  group('CsvRecipeImporter', () {
    test('groups multiple rows by recipe_name into one RecipeEntity', () {
      const csv = 'recipe_name,recipe_description,recipe_servings,'
          'recipe_total_weight_g,recipe_tags,ingredient_name,'
          'ingredient_brands,ingredient_amount,ingredient_unit,'
          'ingredient_kcal_100,ingredient_carbs_100,ingredient_fat_100,'
          'ingredient_protein_100,ingredient_sugars_100,'
          'ingredient_sat_fat_100,ingredient_fiber_100\n'
          'Vanilla Cake,Classic,8,1500,"dessert,baking",Flour,King Arthur,'
          '200,g,340,70,1,10,0,0,3\n'
          'Vanilla Cake,,,,,Sugar,,150,g,387,100,0,0,100,0,0\n'
          'Vanilla Cake,,,,,Eggs,,200,g,155,1,11,13,1,3,0\n';

      final result = CsvRecipeImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.recipes, hasLength(1));
      final imported = result.recipes.single;
      expect(imported.totalWeightOverridden, isTrue);
      final cake = imported.recipe;
      expect(cake.name, 'Vanilla Cake');
      expect(cake.description, 'Classic');
      expect(cake.servingsCount, 8);
      expect(cake.tags, ['dessert', 'baking']);
      expect(cake.ingredients, hasLength(3));
      expect(cake.ingredients[0].snapshotMeal.name, 'Flour');
      expect(cake.ingredients[0].snapshotMeal.brands, 'King Arthur');
      expect(cake.ingredients[1].snapshotMeal.name, 'Sugar');
      expect(cake.ingredients[2].snapshotMeal.name, 'Eggs');
    });

    test('multiple recipes parsed independently', () {
      const csv = 'recipe_name,recipe_description,recipe_servings,'
          'recipe_total_weight_g,recipe_tags,ingredient_name,'
          'ingredient_brands,ingredient_amount,ingredient_unit,'
          'ingredient_kcal_100,ingredient_carbs_100,ingredient_fat_100,'
          'ingredient_protein_100,ingredient_sugars_100,'
          'ingredient_sat_fat_100,ingredient_fiber_100\n'
          'Cake,,,,,Flour,,200,g,340,,,,,,\n'
          'Smoothie,,,,,Banana,,300,g,89,,,,,,\n';

      final result = CsvRecipeImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.recipes, hasLength(2));
      expect(result.recipes.map((r) => r.recipe.name).toSet(),
          {'Cake', 'Smoothie'});
      // No `recipe_total_weight_g` in either row.
      expect(
        result.recipes.every((r) => !r.totalWeightOverridden),
        isTrue,
      );
    });

    test('rows with missing required fields are skipped with errors', () {
      const csv = 'recipe_name,ingredient_name,ingredient_amount,'
          'ingredient_unit,ingredient_kcal_100\n'
          ',Flour,200,g,340\n' // missing recipe_name
          'Cake,,200,g,340\n' // missing ingredient_name
          'Cake,Flour,,g,340\n' // missing amount
          'Cake,Sugar,150,g,387\n'; // valid

      final result = CsvRecipeImporter.parse(csv);

      expect(result.errors, hasLength(3));
      expect(result.recipes, hasLength(1));
      expect(result.recipes.single.recipe.ingredients, hasLength(1));
      expect(
        result.recipes.single.recipe.ingredients.single.snapshotMeal.name,
        'Sugar',
      );
    });

    test('header missing required column reports a clear error', () {
      const csv = 'recipe_name,ingredient_name\nCake,Flour\n';

      final result = CsvRecipeImporter.parse(csv);

      expect(result.recipes, isEmpty);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('missing required column'));
    });

    test('aggregated nutrition is computed from ingredients', () {
      const csv = 'recipe_name,ingredient_name,ingredient_amount,'
          'ingredient_unit,ingredient_kcal_100\n'
          'Mix,A,100,g,200\n'
          'Mix,B,100,g,300\n';

      final result = CsvRecipeImporter.parse(csv);

      // 100 g @ 200 + 100 g @ 300 = 500 kcal in 200 g → 250 kcal/100 g
      expect(result.recipes.single.recipe.totalWeightG, 200);
      expect(
        result.recipes.single.recipe.aggregatedNutrimentsPer100.energyKcal100,
        closeTo(250, 0.001),
      );
    });

    test('quoted decimal-comma in ingredient quantities is supported', () {
      // The documented happy path: wrap decimal-comma values in
      // double quotes so the splitter doesn't see the comma.
      const csv = 'recipe_name,ingredient_name,ingredient_amount,'
          'ingredient_unit,ingredient_kcal_100,ingredient_fat_100\n'
          'Cookie,Vanilla,"1,5",g,288,"12,5"\n'
          'Cookie,Flour,200,g,340,1\n';

      final result = CsvRecipeImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.recipes, hasLength(1));
      final ingredients = result.recipes.single.recipe.ingredients;
      expect(ingredients, hasLength(2));
      expect(ingredients[0].amount, 1.5);
      expect(ingredients[0].unit, 'g');
      expect(ingredients[0].snapshotMeal.nutriments.fat100, 12.5);
      expect(ingredients[1].amount, 200);
    });

    // #1194: keeps the CSV importer symmetric with #1169's JSON fix.
    test(
      'totalWeightOverridden reflects whether recipe_total_weight_g '
      'was supplied per recipe',
      () {
        const csv = 'recipe_name,recipe_description,recipe_servings,'
            'recipe_total_weight_g,recipe_tags,ingredient_name,'
            'ingredient_brands,ingredient_amount,ingredient_unit,'
            'ingredient_kcal_100,ingredient_carbs_100,ingredient_fat_100,'
            'ingredient_protein_100,ingredient_sugars_100,'
            'ingredient_sat_fat_100,ingredient_fiber_100\n'
            'Cake,,,1500,,Flour,,200,g,340,,,,,,\n'
            'Smoothie,,,,,Banana,,300,g,89,,,,,,\n';

        final result = CsvRecipeImporter.parse(csv);

        expect(result.errors, isEmpty);
        expect(result.recipes, hasLength(2));
        final byName = {
          for (final r in result.recipes) r.recipe.name: r,
        };
        expect(byName['Cake']!.totalWeightOverridden, isTrue);
        expect(byName['Smoothie']!.totalWeightOverridden, isFalse);
      },
    );

    test(
      'rejects recipe_total_weight_g of 0, negative or NaN and drops '
      'the recipe',
      () {
        const csv = 'recipe_name,recipe_description,recipe_servings,'
            'recipe_total_weight_g,recipe_tags,ingredient_name,'
            'ingredient_brands,ingredient_amount,ingredient_unit,'
            'ingredient_kcal_100,ingredient_carbs_100,ingredient_fat_100,'
            'ingredient_protein_100,ingredient_sugars_100,'
            'ingredient_sat_fat_100,ingredient_fiber_100\n'
            'Zero,,,0,,Flour,,200,g,340,,,,,,\n'
            'Negative,,,-100,,Flour,,200,g,340,,,,,,\n'
            'NaN,,,NaN,,Flour,,200,g,340,,,,,,\n'
            'Good,,,300,,Flour,,110,g,360,,,,,,\n';

        final result = CsvRecipeImporter.parse(csv);

        expect(result.recipes, hasLength(1));
        expect(result.recipes.single.recipe.name, 'Good');
        expect(result.errors, hasLength(3));
        for (final message in result.errors) {
          expect(
            message,
            contains(
              'recipe_total_weight_g must be a positive finite number',
            ),
          );
        }
      },
    );

    test('unquoted decimal-comma surfaces a too-many-columns hint', () {
      // 16 expected columns; the unquoted `1,5` in the ingredient_amount
      // cell over-splits the row.
      const csv = 'recipe_name,recipe_description,recipe_servings,'
          'recipe_total_weight_g,recipe_tags,ingredient_name,'
          'ingredient_brands,ingredient_amount,ingredient_unit,'
          'ingredient_kcal_100,ingredient_carbs_100,ingredient_fat_100,'
          'ingredient_protein_100,ingredient_sugars_100,'
          'ingredient_sat_fat_100,ingredient_fiber_100\n'
          'Cookie,,,,,Vanilla,,1,5,g,288,0,12,0,0,0,0\n';

      final result = CsvRecipeImporter.parse(csv);

      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('too many columns'));
      expect(result.errors.first, contains('"1,5"'));
    });
  });
}
