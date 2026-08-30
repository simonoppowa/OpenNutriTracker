import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/portion_label.dart';

void main() {
  group('householdPortionLabel', () {
    test('pulls the measure out of an FDC-style label', () {
      // What `MealEntity._spServingLabel` renders for a backend food.
      expect(householdPortionLabel('1 slice (38 g)', languageCode: 'en'), 'slice');
    });

    test('keeps a qualified measure whole, comma and all', () {
      // The backend's own schema comment names this exact shape, and the
      // comma is why the word may never reach the *stored* unit (#864).
      expect(householdPortionLabel('1 cup, sliced (240 g)', languageCode: 'en'), 'cup, sliced');
    });

    test('handles a description with no weight appended', () {
      expect(householdPortionLabel('1 egg', languageCode: 'en'), 'egg');
    });

    test('a bare weight names no household measure', () {
      // OFF's common shape. Reducing "30 g" to "g" and showing it as a unit
      // would replace a correct word with a wrong one.
      expect(householdPortionLabel('30 g', languageCode: 'en'), isNull);
      expect(householdPortionLabel('240ml', languageCode: 'en'), isNull);
      expect(householdPortionLabel('1.5 l', languageCode: 'en'), isNull);
    });

    test('a decimal or comma count is stripped like any other', () {
      expect(householdPortionLabel('0.5 cup (120 g)', languageCode: 'en'), 'cup');
      expect(householdPortionLabel('1,5 slices', languageCode: 'en'), 'slices');
    });

    test('"portion" is the backend saying it has no household measure', () {
      // `food_summary` maps FDC's measure_unit 9999 ('undetermined') to the
      // word "portion". It says nothing the dropdown does not already say.
      expect(householdPortionLabel('1 portion', languageCode: 'en'), isNull);
      expect(householdPortionLabel('serving', languageCode: 'en'), isNull);
    });

    test('nothing usable gives null rather than an empty label', () {
      expect(householdPortionLabel(null, languageCode: 'en'), isNull);
      expect(householdPortionLabel('', languageCode: 'en'), isNull);
      expect(householdPortionLabel('   ', languageCode: 'en'), isNull);
      expect(householdPortionLabel('1', languageCode: 'en'), isNull);
      expect(householdPortionLabel('1 (38 g)', languageCode: 'en'), isNull);
      expect(householdPortionLabel('---', languageCode: 'en'), isNull);
    });

    test('a label too long for the row is refused, not truncated', () {
      // The dropdown sizes itself to its widest item and this row has
      // already overflowed once (#824). "Serving" underneath is still
      // correct, so losing the word is the cheaper failure.
      final long = 'a' * (maxHouseholdPortionLabel + 1);
      expect(householdPortionLabel('1 $long', languageCode: 'en'), isNull);
      final atLimit = 'a' * maxHouseholdPortionLabel;
      expect(householdPortionLabel('1 $atLimit', languageCode: 'en'), atLimit);
    });

    test('nothing is offered outside English, because the data is English', () {
      // #864. `food_summary.serving_size` comes straight from
      // `food_portion.portion_description`; `food_portion_translation` is
      // empty on the live backend — 0 rows against 36,682 portions — so this
      // word is English for every locale the app ships. Showing it in the
      // other eight put a raw dataset string in their UI, which #865 did.
      for (final locale in ['de', 'cs', 'it', 'pl', 'sk', 'tr', 'uk', 'zh']) {
        expect(
          householdPortionLabel('1 slice (38 g)', languageCode: locale),
          isNull,
          reason: '$locale would have been shown the English word',
        );
      }
    });

    test('the gate is on the language, not the region', () {
      // A country subtag never reaches this function — the caller passes
      // `languageCode` — but pinning it means a future caller passing "en_US"
      // fails here rather than silently going quiet in every English build.
      expect(householdPortionLabel('1 slice', languageCode: 'en'), 'slice');
      expect(householdPortionLabel('1 slice', languageCode: 'en_US'), isNull);
    });

    test('a non-Latin measure survives', () {
      // The backend translates portion descriptions per locale, so this
      // function must not assume the Latin script it was written against.
      expect(householdPortionLabel('1 片 (38 g)', languageCode: 'en'), '片');
      expect(householdPortionLabel('1 Scheibe (38 g)', languageCode: 'en'), 'Scheibe');
    });
  });
}
