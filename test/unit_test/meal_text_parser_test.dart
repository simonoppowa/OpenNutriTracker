import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

void main() {
  group('parseMealText segmentation', () {
    test('a single item with no separator at all is one segment', () {
      final result = parseMealText('black coffee');

      expect(result.errors, isEmpty);
      expect(result.items, hasLength(1));
      expect(result.items.single.query, 'black coffee');
    });

    test('splits on comma when the comma is not a decimal point', () {
      final result = parseMealText('toast, eggs');

      expect(result.items.map((i) => i.query), ['toast', 'eggs']);
    });

    test('splits on semicolon, newline, and plus', () {
      final result = parseMealText('toast; eggs\nbacon+coffee');

      expect(result.items.map((i) => i.query), [
        'toast',
        'eggs',
        'bacon',
        'coffee',
      ]);
    });

    test(
      'a comma with digits on both sides is a decimal point, not a separator',
      () {
        final result = parseMealText('1,5 l milk');

        expect(result.items, hasLength(1));
      },
    );

    test('a comma with no digit before it is a separator', () {
      final result = parseMealText('toast,2 eggs');

      // Two segments: 'toast' and '2 eggs'. Quantity/unit extraction turns
      // the second into query 'eggs' + quantity 2 — see the extraction
      // group below for that behavior in isolation.
      expect(result.items, hasLength(2));
      expect(result.items.map((i) => i.query), ['toast', 'eggs']);
    });

    test(
      'a comma followed by a space is a separator even between digits and letters',
      () {
        final result = parseMealText('100g toast, 2 eggs');

        expect(result.items, hasLength(2));
        expect(result.items.map((i) => i.query), ['toast', 'eggs']);
      },
    );

    test('empty segments are skipped, not errors', () {
      final result = parseMealText('toast,, eggs,');

      expect(result.errors, isEmpty);
      expect(result.items.map((i) => i.query), ['toast', 'eggs']);
    });

    test('empty string input produces no items and no errors', () {
      final result = parseMealText('');

      expect(result.items, isEmpty);
      expect(result.errors, isEmpty);
    });

    test('whitespace-only input produces no items and no errors', () {
      final result = parseMealText('   ');

      expect(result.items, isEmpty);
      expect(result.errors, isEmpty);
    });
  });

  group('parseMealText quantity/unit extraction', () {
    test('leading quantity with no space before the unit (100g toast)', () {
      final item = parseMealText('100g toast').items.single;

      expect(item.query, 'toast');
      expect(item.quantity, 100);
      expect(item.unit, 'g');
    });

    test('trailing quantity with no space before the unit (toast 100g)', () {
      final item = parseMealText('toast 100g').items.single;

      expect(item.query, 'toast');
      expect(item.quantity, 100);
      expect(item.unit, 'g');
    });

    test(
      'a space between the number and the unit is also accepted (1.5 l milk)',
      () {
        // Unit normalization (l -> ml x1000) is covered in detail in the
        // group below; this just confirms the space-before-unit case is
        // recognized as quantity+unit at all.
        final item = parseMealText('1.5 l milk').items.single;

        expect(item.query, 'milk');
        expect(item.quantity, isNotNull);
        expect(item.unit, isNotNull);
      },
    );

    test('quantity with no unit (2 eggs)', () {
      final item = parseMealText('2 eggs').items.single;

      expect(item.query, 'eggs');
      expect(item.quantity, 2);
      expect(item.unit, isNull);
    });

    test('no quantity at all (black coffee) leaves both fields null', () {
      final item = parseMealText('black coffee').items.single;

      expect(item.query, 'black coffee');
      expect(item.quantity, isNull);
      expect(item.unit, isNull);
    });

    test('unit matching is case-insensitive and normalized to lowercase', () {
      final item = parseMealText('100G toast').items.single;

      expect(item.unit, 'g');
    });

    test('an unrecognized unit-like token is left as part of the query', () {
      final item = parseMealText('100xyz toast').items.single;

      expect(item.query, '100xyz toast');
      expect(item.quantity, isNull);
      expect(item.unit, isNull);
    });
  });

  group('parseMealText unit normalization', () {
    test('kg is converted to g, quantity times 1000', () {
      final item = parseMealText('1kg flour').items.single;

      expect(item.quantity, 1000);
      expect(item.unit, 'g');
    });

    test('l is converted to ml, quantity times 1000', () {
      final item = parseMealText('1.5 l milk').items.single;

      expect(item.quantity, 1500);
      expect(item.unit, 'ml');
    });

    test('g, ml, and oz pass through unchanged', () {
      final results = [
        parseMealText('100g toast').items.single,
        parseMealText('100ml juice').items.single,
        parseMealText('4oz steak').items.single,
      ];

      expect(results.map((i) => i.unit), ['g', 'ml', 'oz']);
      expect(results.map((i) => i.quantity), [100, 100, 4]);
    });
  });
}
