import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Checks the generated BLS asset (`tool/bls/bls_to_asset.py`) that ships
/// with the app: its shape, its units and a few known foods.
void main() {
  late Map<String, dynamic> asset;
  late List<String> fields;
  late Duration decodeTime;

  setUpAll(() {
    final stopwatch = Stopwatch()..start();
    final bytes = File('assets/bls/bls_4_0.json.gz').readAsBytesSync();
    asset = jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
    decodeTime = stopwatch.elapsed;
    fields = (asset['fields'] as List).cast<String>();
  });

  num? valueOf(String name, String field) {
    final food =
        (asset['foods'] as List).firstWhere((food) => (food as List)[1] == name)
            as List;
    return (food[3] as List)[fields.indexOf(field)] as num?;
  }

  test('carries version, source and license', () {
    expect(asset['version'], 1);
    expect(asset['source'], contains('Max Rubner-Institut'));
    expect(asset['license'], contains('CC BY 4.0'));
  });

  test('holds every BLS 4.0 food with a unique code', () {
    final foods = asset['foods'] as List;
    expect(foods, hasLength(7140));
    final codes = foods.map((food) => (food as List)[0]).toSet();
    expect(codes, hasLength(foods.length));
  });

  test('every row has one number or null per field', () {
    for (final food in asset['foods'] as List) {
      final values = (food as List)[3] as List;
      expect(values, hasLength(fields.length));
      expect(values.every((v) => v == null || v is num), isTrue);
    }
  });

  test('names the fields the app stores', () {
    expect(
      fields,
      containsAll([
        'energyKcal100',
        'proteins100',
        'vitaminB6100',
        'vitaminE100',
        'folate100',
        'iodine100',
      ]),
    );
  });

  test('known foods have the values of the BLS table, in app units', () {
    expect(valueOf('Hafer Flocken', 'energyKcal100'), 348);
    expect(valueOf('Hafer Flocken', 'vitaminB6100'), closeTo(0.098, 1e-9));
    expect(valueOf('Hafer Flocken', 'copper100'), closeTo(0.40961, 1e-9));
    expect(
      valueOf(
        'Speisequark Magerstufe, Magerquark < 10 % Fett i. Tr.',
        'proteins100',
      ),
      greaterThan(10),
    );
    expect(valueOf('Banane roh', 'energyKcal100'), 79);
  });

  test('decodes fast enough to load at first start', () {
    expect(decodeTime, lessThan(const Duration(seconds: 5)));
  });
}
