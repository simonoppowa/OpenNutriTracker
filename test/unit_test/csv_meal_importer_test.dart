import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/csv_meal_importer.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

void main() {
  group('CsvMealImporter.parse', () {
    test('parses a single valid row with all columns populated', () {
      const csv =
          'name,brands,barcode,kcal_per_100g,carbs_per_100g,fat_per_100g,'
          'protein_per_100g,sugars_per_100g,saturated_fat_per_100g,fiber_per_100g\n'
          'Banana,Acme,1234,89,22.8,0.3,1.1,12.2,0.1,2.6';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.meals, hasLength(1));
      final meal = result.meals.single;
      expect(meal.name, 'Banana');
      expect(meal.brands, 'Acme');
      expect(meal.code, '1234');
      expect(meal.source, MealSourceEntity.custom);
      expect(meal.nutriments.energyKcal100, 89);
      expect(meal.nutriments.carbohydrates100, 22.8);
      expect(meal.nutriments.fat100, 0.3);
      expect(meal.nutriments.proteins100, 1.1);
      expect(meal.nutriments.sugars100, 12.2);
      expect(meal.nutriments.saturatedFat100, 0.1);
      expect(meal.nutriments.fiber100, 2.6);
    });

    test('only name and kcal are required; other macros default to null', () {
      const csv = 'name,kcal_per_100g\nApple,52';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      final meal = result.meals.single;
      expect(meal.name, 'Apple');
      expect(meal.nutriments.energyKcal100, 52);
      expect(meal.nutriments.carbohydrates100, isNull);
      expect(meal.nutriments.fat100, isNull);
      expect(meal.nutriments.proteins100, isNull);
    });

    test('column order is irrelevant', () {
      const csv = 'kcal_per_100g,name,fat_per_100g\n61,Whole Milk,3.3';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      final meal = result.meals.single;
      expect(meal.name, 'Whole Milk');
      expect(meal.nutriments.energyKcal100, 61);
      expect(meal.nutriments.fat100, 3.3);
    });

    test('header lookup is case-insensitive', () {
      const csv = 'NAME,Kcal_Per_100g\nApple,52';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.meals.single.name, 'Apple');
    });

    test('a row with empty name is skipped with an error message', () {
      const csv = 'name,kcal_per_100g\n,52\nApple,52';

      final result = CsvMealImporter.parse(csv);

      expect(result.meals, hasLength(1));
      expect(result.meals.single.name, 'Apple');
      expect(result.errors, hasLength(1));
      expect(result.errors.single, contains('Row 2'));
      expect(result.errors.single, contains('name'));
    });

    test('a row with non-numeric kcal is skipped with an error message', () {
      const csv = 'name,kcal_per_100g\nApple,not-a-number\nBanana,89';

      final result = CsvMealImporter.parse(csv);

      expect(result.meals, hasLength(1));
      expect(result.meals.single.name, 'Banana');
      expect(result.errors, hasLength(1));
      expect(result.errors.single, contains('Row 2'));
      expect(result.errors.single, contains('kcal'));
    });

    test('a row with too few columns is skipped', () {
      const csv = 'name,brands,kcal_per_100g\nBanana,Acme';

      final result = CsvMealImporter.parse(csv);

      expect(result.meals, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.single, contains('Row 2'));
    });

    test('quoted fields with embedded commas are preserved', () {
      const csv =
          'name,kcal_per_100g\n"Granola, oats and nuts",450';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.meals.single.name, 'Granola, oats and nuts');
    });

    test('escaped double-quotes inside a quoted field are unescaped', () {
      const csv = 'name,kcal_per_100g\n"He said ""hi""",100';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.meals.single.name, 'He said "hi"');
    });

    test('comma is accepted as decimal separator', () {
      const csv = 'name,kcal_per_100g,fat_per_100g\nApple,52,"0,3"';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.meals.single.nutriments.fat100, 0.3);
    });

    test('quoted decimal-comma works (the documented happy path)', () {
      // Decimal-comma values must be wrapped in quotes because the
      // CSV format alone doesn't disambiguate `288,12,5` (288 + 12.5
      // vs three integers vs 288.12 + 5). The error path below tells
      // users so when they get it wrong.
      const csv = 'name,kcal_per_100g,fat_per_100g,protein_per_100g\n'
          'Butter,717,"82,5","0,9"\n';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.meals, hasLength(1));
      expect(result.meals.single.nutriments.fat100, 82.5);
      expect(result.meals.single.nutriments.proteins100, 0.9);
    });

    test('unquoted decimal-comma triggers a clear too-many-columns hint', () {
      // 3 expected columns; the unquoted `12,5` over-splits to 4.
      // Surface a hint about quoting so the user knows what to fix.
      const csv = 'name,kcal_per_100g,fat_per_100g\n'
          'Butter,717,82,5\n';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('too many columns'));
      expect(result.errors.first, contains('"1,5"'));
      expect(result.meals, isEmpty);
    });

    test('blank lines between rows are ignored', () {
      const csv = 'name,kcal_per_100g\n\nApple,52\n\n\nBanana,89\n';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.meals.map((m) => m.name).toList(), ['Apple', 'Banana']);
    });

    test('missing required columns is a top-level error', () {
      const csv = 'name,fat_per_100g\nApple,0.3';

      final result = CsvMealImporter.parse(csv);

      expect(result.meals, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.single, contains('kcal_per_100g'));
    });

    test('empty CSV reports an error', () {
      final result = CsvMealImporter.parse('');

      expect(result.meals, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('rows without a barcode leave code null so dedup-by-name works', () {
      const csv = 'name,kcal_per_100g\nApple,52\nBanana,89';

      final result = CsvMealImporter.parse(csv);

      expect(result.meals, hasLength(2));
      expect(result.meals[0].code, isNull);
      expect(result.meals[1].code, isNull);
    });

    test('rows with a barcode preserve it as the code', () {
      const csv = 'name,barcode,kcal_per_100g\nApple,1234567890123,52';

      final result = CsvMealImporter.parse(csv);

      expect(result.meals.single.code, '1234567890123');
    });

    test('sampleCsv() parses successfully and produces real meals', () {
      final result = CsvMealImporter.parse(CsvMealImporter.sampleCsv());

      expect(result.errors, isEmpty);
      expect(result.meals, hasLength(2));
      expect(result.meals[0].name, 'Banana');
      expect(result.meals[1].name, 'Whole Milk 3.25%');
    });

    test('serving_size populates servingQuantity and hasServingValues', () {
      // Issue #420 / #421: when present, the meal-detail screen uses
      // `hasServingValues` to default the logged amount to 1 serving
      // instead of 100 g.
      const csv = 'name,kcal_per_100g,serving_size\nBanana,89,118';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      final meal = result.meals.single;
      expect(meal.servingQuantity, 118);
      expect(meal.servingSize, '118 g');
      expect(meal.hasServingValues, isTrue);
    });

    test('decimal serving_size like 62.5 is preserved', () {
      const csv = 'name,kcal_per_100g,serving_size\nProtein Bar,400,62.5';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      final meal = result.meals.single;
      expect(meal.servingQuantity, 62.5);
      expect(meal.servingSize, '62.5 g');
    });

    test('blank serving_size leaves servingQuantity null', () {
      const csv = 'name,kcal_per_100g,serving_size\nApple,52,\nBanana,89,';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.meals.every((m) => m.servingQuantity == null), isTrue);
    });

    test('non-positive serving_size is rejected with a row error', () {
      const csv = 'name,kcal_per_100g,serving_size\nApple,52,-1\nBanana,89,0';

      final result = CsvMealImporter.parse(csv);

      expect(result.meals, isEmpty);
      expect(result.errors, hasLength(2));
      expect(result.errors[0], contains('serving_size'));
      expect(result.errors[1], contains('serving_size'));
    });

    test('old CSV without serving_size column still parses (backward-compat)', () {
      // The header set predating issue #420. Importers in the wild that
      // omit the new column must keep working.
      const csv = 'name,brands,barcode,kcal_per_100g,carbs_per_100g,'
          'fat_per_100g,protein_per_100g,sugars_per_100g,'
          'saturated_fat_per_100g,fiber_per_100g\n'
          'Banana,,,89,22.8,0.3,1.1,12.2,0.1,2.6';

      final result = CsvMealImporter.parse(csv);

      expect(result.errors, isEmpty);
      expect(result.meals.single.servingQuantity, isNull);
    });
  });
}
