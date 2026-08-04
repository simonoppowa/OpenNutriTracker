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

    test('all four separators together in one input', () {
      final result = parseMealText('toast, eggs; bacon\ncoffee+juice');

      expect(result.items.map((i) => i.query), [
        'toast',
        'eggs',
        'bacon',
        'coffee',
        'juice',
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

    test('l is converted to ml, quantity times 1000 (period decimal)', () {
      final item = parseMealText('1.5 l milk').items.single;

      expect(item.quantity, 1500);
      expect(item.unit, 'ml');
    });

    test('l is converted to ml, quantity times 1000 (comma decimal)', () {
      // '1,5' is normalized to the decimal 1.5 before segmentation (the
      // digit-digit comma rule), so this is one item, not two.
      final result = parseMealText('1,5 l milk');
      final item = result.items.single;

      expect(item.query, 'milk');
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

  group('parseMealText food-name validation', () {
    test('a segment with no letters (123) is rejected', () {
      final result = parseMealText('123');

      expect(result.items, isEmpty);
      expect(result.errors, ['Item 1: not a valid food name']);
    });

    test('a valid segment after a rejected one keeps its own item number', () {
      final result = parseMealText('123, toast');

      expect(result.errors, ['Item 1: not a valid food name']);
      expect(result.items.single.query, 'toast');
    });

    test('empty segments do not consume an item number', () {
      // The leading empty segment (before the comma) is skipped silently,
      // so the invalid '123' is still 'Item 1', not 'Item 2'.
      final result = parseMealText(',123');

      expect(result.errors, ['Item 1: not a valid food name']);
    });
  });

  group('parseMealText quantity bounds', () {
    test('a quantity of 0 is rejected', () {
      final result = parseMealText('0g water');

      expect(result.items, isEmpty);
      expect(result.errors, ['Item 1: quantity must be greater than 0']);
    });

    test('a quantity over 10000 is rejected', () {
      final result = parseMealText('10001g flour');

      expect(result.items, isEmpty);
      expect(result.errors, ['Item 1: quantity must be 10000 or less']);
    });

    test('exactly 10000 is accepted', () {
      final result = parseMealText('10000g flour');

      expect(result.errors, isEmpty);
      expect(result.items.single.quantity, 10000);
    });

    test('the 10000 bound applies after kg -> g conversion, not before', () {
      // 15 kg converts to 15000 g, which exceeds the bound — it must not
      // be evaluated as 15 (under the bound) before the x1000 conversion.
      final result = parseMealText('15kg flour');

      expect(result.items, isEmpty);
      expect(result.errors, ['Item 1: quantity must be 10000 or less']);
    });
  });

  group('parseMealText unit invariant', () {
    // The app's UnitDropdownItem.toString() values (meal_detail_bloc.dart).
    // A future unit addition there without a matching update here should
    // fail this test rather than silently reach the app's g/ml fallback.
    const validUnitDropdownValues = {
      'g',
      'ml',
      'g/ml',
      'oz',
      'fl.oz',
      'serving',
    };

    test(
      'every parsed unit is null or one of the six UnitDropdownItem values',
      () {
        const inputs = [
          '100g toast',
          'toast 100g',
          '1,5 l milk',
          '1kg flour',
          '4oz steak',
          '2 eggs',
          'black coffee',
          '100G toast',
          '100xyz toast',
          '100g toast, 2 eggs; bacon+coffee\nwater',
        ];

        for (final input in inputs) {
          for (final item in parseMealText(input).items) {
            if (item.unit != null) {
              expect(
                validUnitDropdownValues.contains(item.unit),
                isTrue,
                reason: 'unexpected unit "${item.unit}" from input "$input"',
              );
            }
          }
        }
      },
    );
  });
}
