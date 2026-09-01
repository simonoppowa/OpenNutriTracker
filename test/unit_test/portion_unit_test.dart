import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';

void main() {
  group('portion units never reach storage (#864)', () {
    test('the first portion is the string the app always stored', () {
      // A food with one portion has to produce exactly what it produced
      // before portions existed, or every row written since becomes a
      // different row.
      expect(portionUnit(0), 'serving');
      expect(storedUnit(portionUnit(0)), 'serving');
    });

    test('later portions are distinguishable but store the same', () {
      expect(portionUnit(1), 'serving#1');
      expect(portionUnit(7), 'serving#7');
      expect(storedUnit('serving#1'), 'serving');
      expect(storedUnit('serving#7'), 'serving');
    });

    test('storedUnit leaves every other unit alone', () {
      // Safe to call on all of them, so no call site has to decide first.
      for (final u in ['g', 'ml', 'g/ml', 'oz', 'fl.oz', 'serving']) {
        expect(storedUnit(u), u);
      }
    });

    test('an unadorned unit names no portion', () {
      expect(portionIndexOf('serving'), isNull);
      expect(portionIndexOf('g'), isNull);
      expect(portionIndexOf('oz'), isNull);
    });

    test('but a serving-shaped unit still scales by one', () {
      // A row saved before portions existed, and a row that took the
      // default, both mean the portion food_summary would have picked.
      expect(effectivePortionIndex('serving'), 0);
      expect(effectivePortionIndex('serving#0'), 0);
      expect(effectivePortionIndex('serving#3'), 3);
    });

    test('isPortionUnit recognises both spellings and nothing else', () {
      expect(isPortionUnit('serving'), isTrue);
      expect(isPortionUnit('serving#2'), isTrue);
      expect(isPortionUnit('g'), isFalse);
      expect(isPortionUnit('fl.oz'), isFalse);
    });

    test('a malformed suffix is not a portion, and still stores clean', () {
      // Nothing writes these, but a unit read back from an older or newer
      // build must not become an index by accident.
      expect(portionIndexOf('serving#'), isNull);
      expect(portionIndexOf('serving#x'), isNull);
      expect(effectivePortionIndex('serving#x'), 0);
      expect(storedUnit('serving#x'), 'serving');
    });
  });
}
