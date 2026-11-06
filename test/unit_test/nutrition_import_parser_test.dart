import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/edit_meal/domain/nutrition_import_parser.dart';

void main() {
  test('serving weight in a parenthesized product description is used', () {
    final food = NutritionImportParser.parseText('''
Food: Plant-Based Whopper
Brand: Burger King
Nutrition basis: Per serving
Serving size: 1 whole burger (278g)
Calories: 528 kcal
''');
    expect(food.name, 'Plant-Based Whopper');
    expect(food.brand, 'Burger King');
    expect(food.basis, NutritionBasis.serving);
    expect(food.servingSize, 278);
    expect(food.servingUnit, 'g');
    expect(food.toPer100()['kcal'], closeTo(189.928, 0.001));
  });

  test('UK label populates supported values and converts salt to sodium', () {
    final food = NutritionImportParser.parseText('''
Oat Milk
Per 100 ml
Energy: 60 kcal
Fat: 3.0 g
of which saturates: 0.4 g
Carbohydrates: 6.6 g
of which sugars: 4.0 g
Fibre: 0.8 g
Protein: 1.0 g
Salt: 0.1 g
''');
    expect(food.name, 'Oat Milk');
    expect(food.basis, NutritionBasis.per100ml);
    expect(food.toPer100()['kcal'], 60);
    expect(food.toPer100()['saturatedFat'], 0.4);
    expect(food.toPer100()['sodium'], 40);
  });

  test('EU energy kJ and kcal in one line preserves declared kcal', () {
    final food = NutritionImportParser.parseText(
      'Per 100 g\nEnergy 1046 kJ 250 kcal\nProtein 12g',
    );
    expect(food.toPer100()['kcal'], 250);
    expect(food.toPer100()['protein'], 12);
  });

  test('kJ alone converts without rounding', () {
    final food = NutritionImportParser.parseText('Per 100 g\nEnergy 1046 kJ');
    expect(food.toPer100()['kcal'], closeTo(250, 0.01));
  });

  test('US terminology, single line and sodium mg', () {
    final food = NutritionImportParser.parseText(
      'Per 100 g Calories: 250 Total Carbohydrate: 30g Total Fat 9g Dietary Fiber: 4g Sodium 200mg',
    );
    final values = food.toPer100();
    expect(values['kcal'], 250);
    expect(values['carbs'], 30);
    expect(values['fat'], 9);
    expect(values['fiber'], 4);
    expect(values['sodium'], 200);
  });

  test('decimal commas and serving conversion', () {
    final food = NutritionImportParser.parseText(
      'Per serving 25 g\nProtein: 1,25 g',
    );
    expect(food.toPer100()['protein'], 5);
  });

  test('package basis and size convert only with a mass unit', () {
    final food = NutritionImportParser.parseText(
      'Bread\nPer package\nPackage size: 200 g\nEnergy 500 kcal',
    );
    expect(food.basis, NutritionBasis.package);
    expect(food.servingSize, 200);
    expect(food.toPer100()['kcal'], 250);
  });

  test('spreadsheet columns default to per 100 g', () {
    final food = NutritionImportParser.parseText(
      'Nutrient\tPer 100 g\tPer serving\nFat\t9g\t3g\nProtein\t12g\t4g',
    );
    expect(food.toPer100()['fat'], 9);
    expect(food.toPer100()['protein'], 12);
  });

  test('serving column can be selected with known size', () {
    final food = NutritionImportParser.parseText(
      'Nutrient\tPer 100 g\tPer serving\nServing size: 25 g\nFat\t8g\t2g',
      selectedBasis: NutritionBasis.serving,
    );
    expect(food.toPer100()['fat'], 8);
  });

  test('tabular serving energy uses the selected cell, not per-100 kcal', () {
    const label =
        'Nutrient\tPer 100 g\tPer serving\n'
        'Serving size: 25 g\n'
        'Energy\t1046 kJ / 250 kcal\t261.5 kJ / 62.5 kcal\n'
        'Protein\t12 g\t3 g';

    final serving = NutritionImportParser.parseText(
      label,
      selectedBasis: NutritionBasis.serving,
    );
    expect(serving.issues, isEmpty);
    expect(serving.values['kcal'], 62.5);
    expect(serving.values['kj'], 261.5);
    expect(serving.toPer100()['kcal'], 250);
    expect(serving.toPer100()['kj'], 1046);
    expect(serving.toPer100()['protein'], 12);

    final per100 = NutritionImportParser.parseText(label);
    expect(per100.issues, isEmpty);
    expect(per100.toPer100()['kcal'], 250);
    expect(per100.toPer100()['kj'], 1046);
  });

  test('tabular energy without a unique basis column stays unrecognised', () {
    final noHeader = NutritionImportParser.parseText(
      'Per 100 g\nEnergy\t1046 kJ / 250 kcal\t261.5 kJ / 62.5 kcal',
    );
    expect(noHeader.values['kcal'], isNull);
    expect(noHeader.issues.join(' '), contains('Ambiguous columns'));

    final duplicateHeader = NutritionImportParser.parseText(
      'Nutrient\tPer 100 g\tPer 100 g\nEnergy\t250 kcal\t260 kcal',
    );
    expect(duplicateHeader.values['kcal'], isNull);
    expect(duplicateHeader.issues.join(' '), contains('Ambiguous columns'));
  });

  test('energy pairs in either unit order preserve the stated kcal', () {
    final food = NutritionImportParser.parseText(
      'Per 100 g\nEnergy 250 kcal / 1046 kJ',
    );
    expect(food.values['kcal'], 250);
    expect(food.values['kj'], 1046);
  });

  test('an invalid energy pair is not partially imported', () {
    final food = NutritionImportParser.parseText(
      'Per 100 g\nEnergy -1046 kJ / 250 kcal',
    );
    expect(food.values['kj'], isNull);
    expect(food.values['kcal'], isNull);
    expect(food.issues, isNotEmpty);
  });

  test('serving without size cannot be converted', () {
    final food = NutritionImportParser.parseText('Per serving\nProtein 3g');
    expect(() => food.toPer100(), throwsFormatException);
  });

  test('CSV semicolon delimiter, quoted names and invalid rows', () {
    final result = NutritionImportParser.parseCsv(
      'Name;Energy (kcal) per 100 g;Protein (g) per 100 g\n"Milk; oat";60;1,5\nBad;oops;3\n',
    );
    expect(result.entries, hasLength(1));
    expect(result.entries.first.name, 'Milk; oat');
    expect(result.entries.first.toPer100()['protein'], 1.5);
    expect(result.errors, isNotEmpty);
  });

  test('CSV manual mapping recovers unfamiliar headings', () {
    final raw = 'Item;Power;Macro\nMilk;60;1';
    final mapped = NutritionImportParser.parseCsv(
      raw,
      manualMapping: {0: 'name', 1: 'kcal', 2: 'protein'},
    );
    expect(mapped.entries.first.values['kcal'], 60);
  });

  test('JSON foods list retains valid entries and reports invalid ones', () {
    final parsed = NutritionImportParser.parseJson('''
{"foods":[{"name":"Oats","calories_per_100g":250,"protein_per_100g":12},
{"name":"Bad","calories":"oops"}]}
''');
    expect(parsed.entries, hasLength(1));
    expect(parsed.entries.first.toPer100()['protein'], 12);
    expect(parsed.errors, isNotEmpty);
  });
  test('duplicate names are skipped without replacing existing foods', () {
    final entries = [
      NutritionEntry(
        name: 'Oats',
        basis: NutritionBasis.per100g,
        values: {'kcal': 50},
      ),
      NutritionEntry(
        name: 'Milk',
        basis: NutritionBasis.per100ml,
        values: {'kcal': 60},
      ),
      NutritionEntry(
        name: ' milk ',
        basis: NutritionBasis.per100ml,
        values: {'kcal': 70},
      ),
    ];
    final selected = selectNutritionBatch(entries, ['oats']);
    expect(selected.entries, hasLength(1));
    expect(selected.entries.first.name, 'Milk');
    expect(selected.duplicates, 2);
  });

  test('ambiguous columns are reported without choosing a value', () {
    final food = NutritionImportParser.parseText(
      'Per 100 g Per serving\nFat 9g 3g',
    );
    expect(food.values['fat'], isNull);
    expect(food.issues.join(' '), contains('Ambiguous'));
  });

  test('unsupported units and malformed values remain empty', () {
    final food = NutritionImportParser.parseText(
      'Per 100 g\nProtein 3 oz\nFat: unknown',
    );
    expect(food.values['protein'], isNull);
    expect(food.values['fat'], isNull);
    expect(food.issues.join(' '), contains('Unsupported'));
  });

  test('CSV with both bases takes per 100 g, not serving', () {
    final parsed = NutritionImportParser.parseCsv(
      'Name,Protein per 100 g,Protein per serving,Serving size\nOats,12,3,25 g',
    );
    expect(parsed.entries.single.toPer100()['protein'], 12);
  });

  test('JSON with both bases takes per 100 g', () {
    final parsed = NutritionImportParser.parseJson(
      '{"name":"Oats","protein_per_serving":3,"protein_per_100g":12,"serving_size":"25 g"}',
    );
    expect(parsed.entries.single.toPer100()['protein'], 12);
  });
  test('does not treat a mass serving as a volume serving', () {
    final food = NutritionImportParser.parseText(
      'Per 100 ml\nServing size: 30 g\nProtein: 2 g',
    );
    expect(() => food.toPer100(), throwsFormatException);
  });
  test('CSV selected serving column uses serving values', () {
    final parsed = NutritionImportParser.parseCsv(
      'Name,Protein per 100 g,Protein per serving,Serving size\nOats,12,3,25 g',
      selectedBasis: NutritionBasis.serving,
    );
    expect(parsed.entries.single.values['protein'], 3);
    expect(parsed.entries.single.toPer100()['protein'], 12);
  });

  test('JSON selected serving field uses serving values', () {
    final parsed = NutritionImportParser.parseJson(
      '{"name":"Oats","protein_per_serving":3,"protein_per_100g":12,"serving_size":"25 g"}',
      selectedBasis: NutritionBasis.serving,
    );
    expect(parsed.entries.single.values['protein'], 3);
    expect(parsed.entries.single.toPer100()['protein'], 12);
  });

  test('cannot relabel a sole per-100 text column as serving', () {
    final parsed = NutritionImportParser.parseText(
      'Per 100 g\nProtein 12g',
      selectedBasis: NutritionBasis.serving,
    );
    expect(parsed.values['protein'], isNull);
    expect(parsed.issues, isNotEmpty);
  });
  test('separate serving size and unit convert without guessing', () {
    final parsed = NutritionImportParser.parseText(
      'Per serving\nServing size: 25\nServing unit: g\nProtein: 3 g',
    );
    expect(parsed.toPer100()['protein'], 12);
  });
  test('JSON manual mapping recovers unfamiliar keys', () {
    final json = '{"item":"Oats","power":250,"macro":12,"basis":"per 100 g"}';
    final first = NutritionImportParser.parseJson(json);
    expect(first.headings, containsAll(['item', 'power', 'macro']));
    final mapped = NutritionImportParser.parseJson(
      json,
      manualMapping: {
        first.headings.indexOf('item'): 'name',
        first.headings.indexOf('power'): 'kcal',
        first.headings.indexOf('macro'): 'protein',
      },
    );
    expect(mapped.entries.single.name, 'Oats');
    expect(mapped.entries.single.toPer100()['protein'], 12);
  });
  test('US daily value percentage is not a second nutrient value', () {
    final parsed = NutritionImportParser.parseText(
      'Per serving 25 g\nProtein 3g 6% DV',
    );
    expect(parsed.values['protein'], 3);
  });

  test('negative nutrition values are rejected', () {
    final parsed = NutritionImportParser.parseText('Per 100 g\nProtein -3g');
    expect(parsed.values['protein'], isNull);
    expect(parsed.issues, isNotEmpty);
    final csv = NutritionImportParser.parseCsv(
      'Name,Protein per 100 g\nOats,-3',
    );
    expect(csv.entries, isEmpty);
    expect(csv.errors, isNotEmpty);
  });
  test('CSV energy in kJ and sodium in grams use the declared units', () {
    final parsed = NutritionImportParser.parseCsv(
      'Name,Energy per 100 g,Sodium per 100 g\nOats,1046 kJ,0.2 g',
    );
    expect(parsed.entries.single.toPer100()['kcal'], closeTo(250, 0.01));
    expect(parsed.entries.single.toPer100()['sodium'], 200);
  });

  test('percentage cells are not imported as gram amounts', () {
    final parsed = NutritionImportParser.parseCsv(
      'Name,Protein per 100 g\nOats,6%',
    );
    expect(parsed.entries, isEmpty);
    expect(parsed.errors, isNotEmpty);
  });
  test('batch import uses the existing food-name validation rule', () {
    final selected = selectNutritionBatch([
      NutritionEntry(
        name: '123',
        basis: NutritionBasis.per100g,
        values: {'kcal': 100},
      ),
    ], []);
    expect(selected.entries, isEmpty);
    expect(selected.invalid, 1);
  });
  test('advanced micronutrients use the form storage units', () {
    final parsed = NutritionImportParser.parseText(
      'Per 100 g\nCalcium 0.2g\nIron 3mg\nPotassium 400mg\nMagnesium 50mg\nVitamin D 0.005mg\nVitamin B12 2µg',
    );
    final values = parsed.toPer100();
    expect(values['calcium'], 200);
    expect(values['iron'], 3);
    expect(values['potassium'], 400);
    expect(values['magnesium'], 50);
    expect(values['vitaminD'], 5);
    expect(values['vitaminB12'], 2);
  });

  test('JSON advanced micronutrients are recognised', () {
    final parsed = NutritionImportParser.parseJson(
      '{"name":"Oats","basis":"per 100 g","calcium":"200 mg","vitaminD":"5 ug"}',
    );
    expect(parsed.entries.single.toPer100()['calcium'], 200);
    expect(parsed.entries.single.toPer100()['vitaminD'], 5);
  });
  test('a gram amount with a trailing daily value stays a gram amount', () {
    final parsed = NutritionImportParser.parseCsv(
      'Name,Protein per 100 g\nOats,3g (6%)',
    );
    expect(parsed.entries.single.toPer100()['protein'], 3);
  });
}
