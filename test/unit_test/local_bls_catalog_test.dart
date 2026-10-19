import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_bls_catalog.dart';

void main() {
  late LocalBlsCatalog catalog;

  setUpAll(() {
    catalog = LocalBlsCatalog.decode(
      File('assets/bls/bls_4_0.json.gz').readAsBytesSync(),
    );
  });

  List<String> top3(String query) => [
    for (final food in catalog.search(query, limit: 3)) food.nameDe,
  ];

  /// The everyday groceries from the phase-1 test (Penny, Rewe, Edeka, Lidl
  /// basics) and the BLS food each one should find among the first three.
  const everyday = <String, String>{
    'Vollmilch': 'Vollmilch frisch',
    'Milch fettarm': 'Milch fettarm',
    'Haferflocken': 'Hafer Flocken',
    'Magerquark': 'Speisequark Magerstufe',
    'Skyr': 'Skyr',
    'Joghurt natur': 'Joghurt mild',
    'Gouda': 'Gouda',
    'Mozzarella': 'Mozzarella mind.',
    'Frischkäse': 'Frischkäse',
    'Butter': 'Butter',
    'Ei': 'Hühnerei roh',
    'Eier': 'Hühnerei roh',
    'Toastbrot': 'Weizenmischtoastbrot',
    'Vollkornbrot': 'Vollkornbrot',
    'Brötchen': 'Weizenbrötchen',
    'Spaghetti': 'Teigwaren',
    'Basmati': 'Reis',
    'Kartoffel gekocht': 'Kartoffel geschält, gekocht',
    'Kartoffeln': 'Kartoffel',
    'Hähnchenbrust': 'Brustfilet',
    'Hackfleisch gemischt': 'Hackfleisch gemischt, roh',
    'Lachs': 'Lachs roh',
    'Thunfisch': 'Thunfisch',
    'Banane': 'Banane roh',
    'Apfel': 'Apfel roh',
    'Tomate': 'Tomate roh',
    'Tomaten': 'Tomate roh',
    'Gurke': 'Gurke roh',
    'Paprika': 'Gemüsepaprika',
    'Brokkoli': 'Broccoli roh',
    'Erbsen': 'Grüne Erbsen',
    'Kidneybohnen': 'Kidneybohne',
    'Tomaten passiert': 'Tomaten passiert',
    'Erdnussbutter': 'Erdnussbutter',
    'Erdnussmus': 'Erdnussbutter',
    'Nuss-Nougat': 'Nuss-Nougat-Creme',
    'Müsli': 'Müsli',
    'Cornflakes': 'Cornflakes',
    'Olivenöl': 'Olivenöl',
    'Rapsöl': 'Rapsöl',
    'Salami': 'Salami',
    'Kochschinken': 'Kochschinken',
    'Leberwurst': 'Leberwurst',
    'Hummus': 'Hummus',
    'Tofu': 'Tofu',
    'Haferdrink': 'Haferdrink ungesüßt',
    'Hafermilch': 'Haferdrink',
    'Cola': 'Colagetränk',
    'Orangensaft': 'Orangensaft',
    'Bier': 'Pilsner Bier',
    'Vollmilchschokolade': 'Vollmilchschokolade',
    'Kartoffelchips': 'Kartoffelchips',
    'Chips': 'Kartoffelchips',
    'Gummibärchen': 'Fruchtgummi',
    'Pizza': 'Pizza',
    'Pommes': 'Pommes frites',
    'Fischstäbchen': 'Fischstäbchen',
    'Wraps': 'Weizentortilla',
    'Ketchup': 'Tomatenketchup',
    'Mayonnaise': 'Mayonnaise',
    'Kaffee': 'Kaffee (Getränk)',
    'Hüttenkäse': 'Körniger Frischkäse',
    'Linsen': 'Linsen',
    'Studentenfutter': 'Studentenfutter',
    'Mangosaft': 'Mangosaft',
  };

  for (final entry in everyday.entries) {
    test('"${entry.key}" finds ${entry.value}', () {
      expect(
        top3(entry.key),
        contains(contains(entry.value)),
        reason: 'top 3: ${top3(entry.key)}',
      );
    });
  }

  group('spelling', () {
    test('ae, oe and ue match their umlaut', () {
      expect(top3('Huehnerei'), contains(contains('Hühnerei')));
      expect(top3('Broetchen'), contains(contains('Weizenbrötchen')));
    });

    test('one typo still finds the food', () {
      expect(top3('Brokoli'), contains(contains('Broccoli')));
      expect(top3('Apfelmuss'), contains(contains('Apfelmus')));
      expect(top3('Mozarella'), contains(contains('Mozzarella')));
    });

    test('case and punctuation do not matter', () {
      expect(top3('HAFER-FLOCKEN'), contains('Hafer Flocken'));
    });
  });

  group('ranking', () {
    test('a diet variant only comes first when asked for', () {
      expect(top3('Toastbrot glutenfrei').first, contains('glutenfrei'));
      expect(top3('Milch fettarm').first, isNot(contains('laktosefrei')));
    });

    test('a raw food comes before its preparations', () {
      expect(top3('Lachs').first, 'Lachs roh');
    });
  });

  test('an unknown food finds nothing', () {
    expect(catalog.search('Xylophonsuppe'), isEmpty);
  });

  test('an empty query finds nothing', () {
    expect(catalog.search('  '), isEmpty);
  });

  test('values come in app units and missing ones stay absent', () {
    final oats = catalog.search('Hafer Flocken', limit: 1).single;
    expect(oats.values['energyKcal100'], 348);
    expect(oats.values['vitaminB6100'], closeTo(0.098, 1e-9));
    expect(oats.values.containsKey('transFat100'), isFalse);
  });
}
