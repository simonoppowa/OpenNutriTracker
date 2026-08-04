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

      expect(result.items.map((i) => i.query), ['toast', '2 eggs']);
    });

    test(
      'a comma followed by a space is a separator even between digits and letters',
      () {
        final result = parseMealText('100g toast, 2 eggs');

        expect(result.items.map((i) => i.query), ['100g toast', '2 eggs']);
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
}
