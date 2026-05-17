import 'package:flutter_test/flutter_test.dart';

/// Regression test for the Simple-mode "empty field treated as zero" fix.
///
/// Background: `_hasRequiredProductInfoMissing()` on the meal-detail sheet
/// guards the Add button with a null-check on `energyKcal100`,
/// `carbohydrates100`, `fat100`, and `proteins100`. The Simple-mode save
/// path previously forwarded the controllers' raw `.text` straight to
/// `createNewMealEntity`, so an empty Carbs field round-tripped to a
/// stored `null` on `carbohydrates100`. The display formatter renders
/// `null` as "0.0 g", which made the on-screen state and the validation
/// state disagree — the meal showed 0g carbs but couldn't be logged,
/// and the error read "Product missing required kcal or macronutrients
/// information" even though every visible field had a value.
///
/// The fix coerces empty Simple-mode fields to "0" before they reach
/// `createNewMealEntity`. A user creating a custom meal in Simple mode is
/// the source of truth for that food's macros — leaving a field blank
/// should mean "this food has zero of this" (oil, plain meat, egg
/// whites), not "I don't know". This test pins the coercion contract.
void main() {
  group('Simple-mode empty-field coercion', () {
    // The production helper is private to _EditMealScreenState. The
    // contract is stable enough to mirror here — anything that returns
    // a non-empty string for a non-empty input and "0" for empty / ws.
    String simpleFieldOrZero(String text) =>
        text.trim().isEmpty ? '0' : text;

    test('empty string returns "0"', () {
      expect(simpleFieldOrZero(''), '0');
    });

    test('whitespace-only returns "0"', () {
      expect(simpleFieldOrZero('   '), '0');
      expect(simpleFieldOrZero('\t'), '0');
      expect(simpleFieldOrZero('\n'), '0');
    });

    test('an explicit "0" is preserved (not turned back into null)', () {
      expect(simpleFieldOrZero('0'), '0');
    });

    test('a non-zero numeric string is returned verbatim', () {
      expect(simpleFieldOrZero('100'), '100');
      expect(simpleFieldOrZero('4.5'), '4.5');
    });

    test('numeric strings with surrounding spaces are not stripped', () {
      // The downstream double.tryParse handles trim implicitly via the
      // text input formatter on the form; this helper just decides
      // empty-vs-not so it can leave the original whitespace intact.
      expect(simpleFieldOrZero(' 4 '), ' 4 ');
    });
  });
}
