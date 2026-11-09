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

  // PR #1491 review: a fat subtype's trailing "Fat" read as total fat and
  // overwrote it.
  test('fat subtypes leave total fat alone', () {
    final food = NutritionImportParser.parseText('''
Nutrition Facts
Per 100 g
Total Fat 10 g
Saturated Fat 3 g
Trans Fat 0 g
Polyunsaturated Fat 2 g
Monounsaturated Fat 4 g
Sat. Fat 3 g
Total Sugars 12 g
Added Sugars 10 g
''');
    expect(food.values['fat'], 10);
    expect(food.values['saturatedFat'], 3);
    expect(food.values['sugars'], 12);
  });

  test('subtype columns are not mapped onto total fat or sugars', () {
    expect(NutritionImportParser.fieldFor('Trans Fat (g)'), isNull);
    expect(NutritionImportParser.fieldFor('Monounsaturated fat'), isNull);
    expect(NutritionImportParser.fieldFor('polyunsaturated_fat'), isNull);
    expect(NutritionImportParser.fieldFor('Added sugars'), isNull);
    expect(NutritionImportParser.fieldFor('Sat fat'), 'saturatedFat');
    final parsed = NutritionImportParser.parseCsv(
      'Name,Fat per 100 g,Trans fat per 100 g\nOats,7,0',
    );
    expect(parsed.entries.single.values['fat'], 7);
  });

  // PR #1491 review: a unit in a column heading was dropped, and a unitless
  // sodium cell defaulted to milligrams.
  test('a unit in a CSV heading applies to unitless cells', () {
    final parsed = NutritionImportParser.parseCsv(
      'Name,Sodium (g) per 100 g,Vitamin D [µg],Calcium mg\n'
      'Soup,0.5,2,120\n'
      'Stock,300 mg,1,0.1 g',
    );
    expect(parsed.errors, isEmpty);
    final soup = parsed.entries[0].toPer100();
    expect(soup['sodium'], 500);
    expect(soup['vitaminD'], 2);
    expect(soup['calcium'], 120);
    // A unit in the cell wins over the heading's.
    final stock = parsed.entries[1].toPer100();
    expect(stock['sodium'], 300);
    expect(stock['calcium'], 100);
  });

  test('a unit in a JSON key applies to unitless values', () {
    final parsed = NutritionImportParser.parseJson(
      '{"name":"Soup","basis":"per 100 g","sodium_g":0.5,"energy (kJ)":1046}',
    );
    final values = parsed.entries.single.values;
    expect(values['sodium'], 500);
    expect(values['kj'], 1046);
  });

  test('a per-100 heading is not read as the nutrient unit', () {
    final parsed = NutritionImportParser.parseCsv(
      'Name,Sodium per 100 g\nSoup,480',
    );
    expect(parsed.entries.single.values['sodium'], 480);
  });

  // Imported energy in both units must agree, or one of them was misread.
  test('kJ and kcal that disagree are flagged for review', () {
    final food = NutritionImportParser.parseText(
      'Oats\nPer 100 g\nEnergy 2046 kJ / 250 kcal\nFat 7 g',
    );
    expect(food.issues, isNotEmpty);
    final consistent = NutritionImportParser.parseText(
      'Oats\nPer 100 g\nEnergy 1046 kJ / 250 kcal\nFat 7 g',
    );
    expect(consistent.issues, isEmpty);
  });

  test('a file with headings but no foods says so', () {
    expect(
      NutritionImportParser.parseCsv('Name,Fat per 100 g').errors,
      isNotEmpty,
    );
    expect(NutritionImportParser.parseJson('[]').errors, isNotEmpty);
    expect(NutritionImportParser.parseJson('{"foods":[]}').errors, isNotEmpty);
  });

  test('a JSON object or list is not read as a nutrient value', () {
    final parsed = NutritionImportParser.parseJson(
      '[{"name":"Oats","basis":"per 100 g","fat":{"value":7}},'
      '{"name":"Rice","basis":"per 100 g","fat":[1, 2]}]',
    );
    expect(parsed.entries, isEmpty);
    expect(parsed.errors, isNotEmpty);
  });

  // Codex review: Greek mu (U+03BC) was not read as a unit, so 100 μg of
  // calcium fell back to milligrams.
  test('micrograms written with the Greek mu are micrograms', () {
    expect(NutritionImportParser.parseNutrientCell('calcium', '100 μg'), (
      'calcium',
      0.1,
    ));
    final food = NutritionImportParser.parseText(
      'Oats\nPer 100 g\nCalcium 100 μg\nVitamin D 5 μg',
    );
    expect(food.values['calcium'], 0.1);
    expect(food.values['vitaminD'], 5);
    expect(food.issues, isEmpty);
  });

  // Codex review: a comma before three digits is a thousands separator on
  // US and UK labels; "1,200 mg" was read as 1.2 mg.
  test('a thousands separator is not a decimal comma', () {
    final food = NutritionImportParser.parseText(
      'Soup\nPer 100 g\nEnergy 1,046 kJ / 250 kcal\nSodium 1,200 mg\n'
      'Fat 1,5 g\nSalt 0,125 g',
    );
    expect(food.values['kj'], 1046);
    expect(food.values['sodium'], 1200);
    expect(food.values['fat'], 1.5);
    expect(food.values['salt'], 0.125);
    expect(food.issues, isEmpty);
    expect(
      NutritionImportParser.parseNutrientCell('sodium', '1,200 mg'),
      ('sodium', 1200.0),
    );
    expect(NutritionImportParser.parseNumber('1,234.5'), 1234.5);
  });

  // Codex review: the first size on the label was used whatever the basis.
  test('the size that belongs to the chosen basis is used', () {
    const label =
        'Crackers\nServing size: 50 g\nPackage size: 200 g\n'
        'Per package\nEnergy 200 kcal';
    final food = NutritionImportParser.parseText(label);
    expect(food.basis, NutritionBasis.package);
    expect(food.servingSize, 200);
    expect(food.toPer100()['kcal'], 100);
    final serving = NutritionImportParser.parseText(
      'Crackers\nPackage size: 200 g\nServing size: 50 g\n'
      'Per serving\nEnergy 200 kcal',
    );
    expect(serving.servingSize, 50);
  });

  // Codex review: "Sugar Alcohol" matched the leading "Sugar" and replaced
  // total sugars.
  test('sugar alcohols leave total sugars alone', () {
    final food = NutritionImportParser.parseText(
      'Gum\nPer 100 g\nTotal Sugars 1 g\nSugar Alcohol 14 g\n'
      'of which polyols 14 g\nEnergy 200 kcal',
    );
    expect(food.values['sugars'], 1);
    expect(NutritionImportParser.fieldFor('Sugar alcohols (g)'), isNull);
    expect(NutritionImportParser.fieldFor('polyols'), isNull);
  });

  // Codex review: re-reading a file under another basis matched foods by
  // position, so a row left out under the new basis shifted the others.
  test('a re-read file is matched to its foods by row', () {
    const csv =
        'Name,Energy per 100 g,Energy per serving,Serving size\n'
        'Oats,370,,\n'
        'Bread,250,125,50 g';
    final first = NutritionImportParser.parseCsv(csv);
    final oats = first.entries[0];
    final bread = first.entries[1];
    final serving = NutritionImportParser.parseCsv(
      csv,
      manualMapping: first.mapping,
      selectedBasis: NutritionBasis.serving,
    );
    expect(serving.entryFromRowOf(oats), isNull);
    expect(serving.entryFromRowOf(bread)?.values['kcal'], 125);

    final json = NutritionImportParser.parseJson(
      '[{"name":"Oats","energy per 100 g":370},'
      '{"name":"Bread","energy per 100 g":250,"energy per serving":125}]',
    );
    final jsonServing = NutritionImportParser.parseJson(
      '[{"name":"Oats","energy per 100 g":370},'
      '{"name":"Bread","energy per 100 g":250,"energy per serving":125}]',
      selectedBasis: NutritionBasis.serving,
    );
    expect(jsonServing.entryFromRowOf(json.entries[0]), isNull);
    expect(jsonServing.entryFromRowOf(json.entries[1])?.values['kcal'], 125);
  });
}
