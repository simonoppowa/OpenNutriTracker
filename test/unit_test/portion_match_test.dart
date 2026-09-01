import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/util/portion_match.dart';

MealPortionEntity _p(String label) =>
    MealPortionEntity(label: label, gramWeight: 1, localized: false);

void main() {
  group('the word the user typed picks the portion (#864)', () {
    final cupAndSlice = [_p('1 cup'), _p('1 slice')];

    test('the case this exists for', () {
      // "3 slices of bread" logged as three cups is the defect. The parser
      // cannot catch it — it keys off unit symbols, not words — so the word
      // survives into the query and is matched against the food's own labels.
      expect(matchPortionToQuery('slices of bread', cupAndSlice), 1);
    });

    test('singular and plural both land, in either direction', () {
      expect(matchPortionToQuery('slice of bread', cupAndSlice), 1);
      expect(matchPortionToQuery('cups of rice', cupAndSlice), 0);
      // The label may be the plural and the query the singular.
      expect(matchPortionToQuery('slice', [_p('2 slices')]), 0);
    });

    test('a word nobody typed matches nothing', () {
      expect(matchPortionToQuery('bread', cupAndSlice), isNull);
      expect(matchPortionToQuery('', cupAndSlice), isNull);
    });

    test('no portions, no match', () {
      expect(matchPortionToQuery('slices of bread', const []), isNull);
    });

    test('a short term does not match a longer unrelated word', () {
      expect(matchPortionToQuery('ozark trail bar', [_p('1 oz')]), isNull);
    });

    test('a filler word inside a label is not a term', () {
      // What the length floor is actually for. "1 large or thick slice"
      // contains "or"; without a minimum, "a bowl or two" would match it and
      // silently pick a portion the user never named. The previous example
      // did not test this — the inflection bound caught it either way.
      final portions = [_p('1 cup'), _p('1 large or thick slice')];
      expect(matchPortionToQuery('a bowl or two', portions), isNull);
    });

    test('an inflection is bounded, not a prefix rule', () {
      // "cup" must not match "cupboard": three letters longer is not an
      // ending, it is a different word.
      expect(matchPortionToQuery('cupboard sandwich', [_p('1 cup')]), isNull);
      expect(matchPortionToQuery('cups', [_p('1 cup')]), 0);
    });

    test('a count is never a term, so it needs no stripping', () {
      // Only runs of letters become terms, so "1" and "1/2" cannot match
      // anything and there is no separate rule for them.
      expect(matchPortionToQuery('a cup of tea', [_p('1 cup (8 fl oz)')]), 0);
      expect(matchPortionToQuery('half bagel', [_p('1/2 bagel')]), 0);
    });

    test('a word inside a parenthetical is not a term', () {
      // These are real labels. "1 fl oz (no ice)" would otherwise offer
      // "ice", and "ice cream" would silently select a fluid-ounce portion
      // the user never asked for. The previous example only had two-letter
      // words in its brackets, which the length floor dropped anyway — so it
      // passed whether parentheticals were stripped or not.
      final portions = [_p('1 cup'), _p('1 fl oz (no ice)')];
      expect(matchPortionToQuery('ice cream', portions), isNull);
    });

    test('the longer match wins over an earlier, shorter one', () {
      // Both portions match "bag"; only the second also matches "large".
      // Taking the first match instead of the longest would pick portion 0
      // here, so the example has to make them disagree — an earlier version
      // did not, and the rule was untested.
      final portions = [_p('1 bag'), _p('1 large single serving bag')];
      expect(matchPortionToQuery('large bag', portions), 1);
    });

    test('ties go to the earlier portion', () {
      // The backend's order, whose first entry is the default the row would
      // have taken anyway.
      final portions = [_p('1 large'), _p('1 large single serving bag')];
      expect(matchPortionToQuery('large eggs', portions), 0);
    });

    test('a qualifier after the comma is matchable too', () {
      final portions = [_p('1 cup'), _p('1 cup, cooked')];
      expect(matchPortionToQuery('cooked rice', portions), 1);
    });

    test('it works on a translated label, which is the point', () {
      // The vocabulary is whatever the backend sent, so German portions match
      // German words with no word list in the app. #600.
      final de = [_p('1 Tasse'), _p('1 Scheibe')];
      expect(matchPortionToQuery('Scheiben Brot', de), 1);
      expect(matchPortionToQuery('Tasse Reis', de), 0);
    });

    test('and on a non-Latin one', () {
      // Chinese has no spaces, so a label term will not appear as its own
      // token — this must return null rather than mismatching.
      expect(matchPortionToQuery('两片面包', [_p('1 片')]), isNull);
    });
  });
}
