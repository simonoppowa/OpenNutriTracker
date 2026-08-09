import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

void main() {
  group('parseMealText', () {
    test('segments all supported separators and retains decimal commas', () {
      final result = parseMealText('toast, eggs; bacon\ncoffee+juice,1,5 l milk');

      expect(result.errors, isEmpty);
      expect(result.items.map((item) => item.query), [
        'toast',
        'eggs',
        'bacon',
        'coffee',
        'juice',
        'milk',
      ]);
      expect(result.items.last.quantity, 1500);
      expect(result.items.last.unit, 'ml');
    });

    test('extracts leading and trailing quantities without rewriting food names', () {
      final items = [
        parseMealText('100g toast').items.single,
        parseMealText('toast 100g').items.single,
        parseMealText('2 chicken breasts').items.single,
        parseMealText('yoghurt 3,5% fat').items.single,
      ];

      expect(items.map((item) => item.query), [
        'toast',
        'toast',
        'chicken breasts',
        'yoghurt 3,5% fat',
      ]);
      expect(items.map((item) => item.quantity), [100, 100, 2, null]);
      expect(items.map((item) => item.unit), ['g', 'g', null, null]);
    });

    test('normalizes only supported input units to app units', () {
      final items = [
        parseMealText('1kg flour').items.single,
        parseMealText('1.5 l milk').items.single,
        parseMealText('4oz steak').items.single,
        parseMealText('100ml juice').items.single,
      ];

      expect(items.map((item) => item.quantity), [1000, 1500, 4, 100]);
      expect(items.map((item) => item.unit), ['g', 'ml', 'oz', 'ml']);
      const supportedUnits = {'g', 'ml', 'g/ml', 'oz', 'fl.oz', 'serving'};
      for (final item in items) {
        expect(item.unit == null || supportedUnits.contains(item.unit), isTrue);
      }
    });

    test('rejects malformed names and invalid quantities without adding items', () {
      final result = parseMealText('100g, 0g water, -5kg flour, 15kg rice, toast');

      expect(result.items.map((item) => item.query), ['toast']);
      expect(result.errors, [
        'Item 1: not a valid food name',
        'Item 2: quantity must be greater than 0',
        'Item 3: quantity must be greater than 0',
        'Item 4: quantity must be 10000 or less',
      ]);
    });

    test('keeps unrecognized unit-like text as a food query', () {
      final item = parseMealText('100xyz toast').items.single;

      expect(item.query, '100xyz toast');
      expect(item.quantity, isNull);
      expect(item.unit, isNull);
    });
  });
}
