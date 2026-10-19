import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/scanner/util/nutrition_label_parser.dart';

List<OcrLine> _lines(List<dynamic> json) => [
  for (final line in json.cast<Map<String, dynamic>>())
    OcrLine(
      text: line['text'] as String,
      x: (line['x'] as num).toDouble(),
      y: (line['y'] as num).toDouble(),
      width: (line['w'] as num).toDouble(),
      height: (line['h'] as num).toDouble(),
      confidence: (line['confidence'] as num?)?.toDouble() ?? 1,
    ),
];

OcrLine _row(String text, double y, {double x = 0.08}) =>
    OcrLine(text: text, x: x, y: y, width: 0.3, height: 0.03);

void main() {
  group('every fixture', () {
    final files =
        Directory('test/fixtures/nutrition_labels')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('the fixture folder is not empty', () {
      expect(files, isNotEmpty);
    });

    for (final file in files) {
      final fixture =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final expected = fixture['expected'] as Map<String, dynamic>;
      test(fixture['product'] as String, () {
        final result = parseNutritionLabel(
          _lines(fixture['lines'] as List<dynamic>),
        );

        expect(result.basis, fixture['basis'], reason: 'basis');
        expect(
          result.energyKcal,
          closeTo((expected['energyKcal'] as num).toDouble(), 1),
          reason: 'energyKcal',
        );
        for (final field in [
          'fat',
          'saturatedFat',
          'carbohydrates',
          'sugars',
          'fiber',
          'protein',
          'salt',
        ]) {
          final want = expected[field] as num?;
          final got = result.valueOf(field);
          if (want == null) {
            expect(got, isNull, reason: field);
          } else {
            expect(got, closeTo(want.toDouble(), 0.005), reason: field);
          }
        }
      });
    }
  });

  group('details', () {
    test('a corrected recognition error marks the field uncertain', () {
      final result = parseNutritionLabel([
        _row('pro 100 g', 0.10, x: 0.55),
        _row('Brennwert', 0.16),
        _row('1O29 kJ/248 kcal', 0.16, x: 0.55),
        _row('Kohlenhydrate', 0.22),
        _row('O,6 g', 0.22, x: 0.55),
        _row('Fett', 0.28),
        _row('19,8 g', 0.28, x: 0.55),
        _row('Eiweiß', 0.34),
        _row('17,2 g', 0.34, x: 0.55),
      ]);

      expect(result.carbohydrates, 0.6);
      expect(result.uncertain, contains('carbohydrates'));
      expect(result.uncertain, isNot(contains('fat')));
    });

    test('a kcal row under kJ keeps to the per-100 column', () {
      final result = parseNutritionLabel([
        _row('pro 100 g', 0.10, x: 0.55),
        _row('pro Portion (30 g)', 0.10, x: 0.80),
        _row('Brennwert', 0.16),
        _row('1029 kJ', 0.16, x: 0.55),
        _row('309 kJ', 0.16, x: 0.80),
        _row('248 kcal', 0.22, x: 0.55),
        _row('74 kcal', 0.22, x: 0.80),
      ]);

      expect(result.energyKcal, 248);
    });

    test('"<" values and "Spuren" read as 0 below the threshold', () {
      final result = parseNutritionLabel([
        _row('Fett < 0,5 g', 0.10),
        _row('Salz Spuren', 0.16),
      ]);

      expect(result.fat, 0);
      expect(result.salt, 0);
      expect(result.belowThreshold, containsAll(['fat', 'salt']));
    });

    test('kcal comes from kJ when the label gives only kJ', () {
      final result = parseNutritionLabel([_row('Energie 1500 kJ', 0.1)]);

      expect(result.energyKcal, closeTo(358.5, 0.5));
      expect(result.uncertain, isNot(contains('energyKcal')));
    });

    test('values that do not add up mark the energy uncertain', () {
      final result = parseNutritionLabel([
        _row('Brennwert 102 kcal', 0.10),
        _row('Fett 19,8 g', 0.16),
        _row('Kohlenhydrate 0,6 g', 0.22),
        _row('Eiweiß 17,2 g', 0.28),
      ]);

      expect(result.energyKcal, 102);
      expect(result.uncertain, contains('energyKcal'));
    });

    test('sugar above the carbohydrates marks the sugar uncertain', () {
      final result = parseNutritionLabel([
        _row('Kohlenhydrate 4,0 g', 0.10),
        _row('davon Zucker 40 g', 0.16),
      ]);

      expect(result.uncertain, contains('sugars'));
    });

    test('a weakly recognized value is uncertain', () {
      final result = parseNutritionLabel([
        OcrLine(
          text: 'Eiweiß 11 g',
          x: 0.08,
          y: 0.1,
          width: 0.3,
          height: 0.03,
          confidence: 0.3,
        ),
      ]);

      expect(result.protein, 11);
      expect(result.uncertain, contains('protein'));
    });

    test('unsaturated fatty acids are not read as saturated', () {
      final result = parseNutritionLabel([
        _row('Fett 30 g', 0.10),
        _row('davon einfach ungesättigte Fettsäuren 18 g', 0.16),
        _row('davon mehrfach ungesättigte Fettsäuren 8 g', 0.22),
        _row('davon gesättigte Fettsäuren 4 g', 0.28),
      ]);

      expect(result.fat, 30);
      expect(result.saturatedFat, 4);
    });

    test('sodium follows from the salt', () {
      final result = parseNutritionLabel([_row('Salz 1,0 g', 0.1)]);

      expect(result.sodiumMg, closeTo(400, 0.001));
    });

    test('text without a nutrition table finds nothing', () {
      final result = parseNutritionLabel([
        _row('Zutaten: Milch, Salz, Lab', 0.1),
        _row('Mindestens haltbar bis 12.10.', 0.2),
      ]);

      expect(result.isEmpty, isTrue);
    });
  });
}
