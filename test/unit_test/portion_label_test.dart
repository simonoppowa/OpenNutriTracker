import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/portion_label.dart';

void main() {
  group('householdPortionLabel', () {
    test('pulls the measure out of an FDC-style label', () {
      // What `MealEntity._spServingLabel` renders for a backend food.
      expect(householdPortionLabel('1 slice (38 g)'), 'slice');
    });

    test('keeps a qualified measure whole, comma and all', () {
      // The backend's own schema comment names this exact shape, and the
      // comma is why the word may never reach the *stored* unit (#864).
      expect(householdPortionLabel('1 cup, sliced (240 g)'), 'cup, sliced');
    });

    test('handles a description with no weight appended', () {
      expect(householdPortionLabel('1 egg'), 'egg');
    });

    test('a bare weight names no household measure', () {
      // OFF's common shape. Reducing "30 g" to "g" and showing it as a unit
      // would replace a correct word with a wrong one.
      expect(householdPortionLabel('30 g'), isNull);
      expect(householdPortionLabel('240ml'), isNull);
      expect(householdPortionLabel('1.5 l'), isNull);
    });

    test('a decimal or comma count is stripped like any other', () {
      expect(householdPortionLabel('0.5 cup (120 g)'), 'cup');
      expect(householdPortionLabel('1,5 slices'), 'slices');
    });

    test('"portion" is the backend saying it has no household measure', () {
      // `food_summary` maps FDC's measure_unit 9999 ('undetermined') to the
      // word "portion". It says nothing the dropdown does not already say.
      expect(householdPortionLabel('1 portion'), isNull);
      expect(householdPortionLabel('serving'), isNull);
    });

    test('nothing usable gives null rather than an empty label', () {
      expect(householdPortionLabel(null), isNull);
      expect(householdPortionLabel(''), isNull);
      expect(householdPortionLabel('   '), isNull);
      expect(householdPortionLabel('1'), isNull);
      expect(householdPortionLabel('1 (38 g)'), isNull);
      expect(householdPortionLabel('---'), isNull);
    });

    test('a label too long for the row is refused, not truncated', () {
      // The dropdown sizes itself to its widest item and this row has
      // already overflowed once (#824). "Serving" underneath is still
      // correct, so losing the word is the cheaper failure.
      final long = 'a' * (maxHouseholdPortionLabel + 1);
      expect(householdPortionLabel('1 $long'), isNull);
      final atLimit = 'a' * maxHouseholdPortionLabel;
      expect(householdPortionLabel('1 $atLimit'), atLimit);
    });

    test('a non-Latin measure survives', () {
      // The backend translates portion descriptions per locale, so this
      // function must not assume the Latin script it was written against.
      expect(householdPortionLabel('1 片 (38 g)'), '片');
      expect(householdPortionLabel('1 Scheibe (38 g)'), 'Scheibe');
    });
  });
}
