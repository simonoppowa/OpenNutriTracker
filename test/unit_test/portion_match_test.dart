import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/util/portion_match.dart';

MealPortionEntity _p(String label, {double grams = 1, String? en}) =>
    MealPortionEntity(
      label: label,
      gramWeight: grams,
      localized: en != null,
      englishLabel: en,
    );

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

  group("the model's key is matched against the English label (#1157)", () {
    // A German reader's rows: what they see, and the English the record
    // carries beside it.
    final de = [_p('1 Tasse', en: '1 cup'), _p('1 Scheibe', en: '1 slice')];

    test('an English key lands on a translated row', () {
      // "3 Scheiben Brot" arrives as `portion: "slice"` — the prompt pins the
      // key to English whatever the user wrote — and must land on the same
      // row it would for an English reader. Against the localized label it
      // would miss on exactly the locale whose labels were reviewed.
      expect(matchPortionToKey('slice', de), 1);
      expect(matchPortionToKey('cup', de), 0);
    });

    test('the typed words still go against the localized label', () {
      // Unchanged: the user's words are in their language. The English label
      // is a matching key for the model, not a second vocabulary for the
      // user — matching both was declined for the false-match surface.
      expect(matchPortionToQuery('Scheiben Brot', de), 1);
      expect(matchPortionToQuery('slices of bread', de), isNull);
    });

    test('falls back to the label while the backend sends no English one', () {
      // The column is added in parallel; an app built before it keeps
      // working. In eight of nine locales the label *is* the English string,
      // so the fallback is the match it would have made anyway.
      expect(matchPortionToKey('slice', [_p('1 cup'), _p('1 slice')]), 1);
    });

    test('no key, no match', () {
      expect(matchPortionToKey(null, de), isNull);
      expect(matchPortionToKey('', de), isNull);
    });

    test('a key that names nothing is ignored', () {
      expect(matchPortionToKey('thimble', de), isNull);
    });
  });

  group('on a tie, the middle rung, else the earliest (#1162)', () {
    // Bread, white (2707598) as `portions_by_food_ids` serves it, in its
    // order. FDC lists a ladder small-first, so the earliest slice is the
    // thin one.
    final bread = [
      _p('1 small or thin/very thin slice', grams: 24),
      _p('1 medium or regular slice', grams: 28),
      _p('1 large or thick slice', grams: 43),
      _p('1 slice, crust not eaten', grams: 13),
      _p('1 slice, snack-size', grams: 10),
      _p('1 cup', grams: 40),
    ];

    // The slice ladder on the chicken breast records.
    final chickenSlices = [
      _p('1 small or thin slice', grams: 30),
      _p('1 medium slice', grams: 60),
      _p('1 large or thick slice', grams: 85),
    ];

    test('a slice of bread is the regular slice, 28 g', () {
      // Was 24 g since #969: "slice" ties all five slices and the earliest
      // was the thin one. The thin slice was never what a person meant by
      // "a slice", and the data names its own middle.
      final typed = matchPortionToQuery('a slice of bread', bread);
      expect(typed, 1);
      expect(bread[typed!].gramWeight, 28);
      // The same row whichever path named the word — the matcher cannot tell
      // a typed word from a model key, so the typed path changes with it.
      expect(matchPortionToKey('slice', bread), 1);
    });

    test('a slice of chicken breast is the medium slice, 60 g', () {
      // Was 30 g: small-first again.
      final match = matchPortionToQuery(
        'a slice of chicken breast',
        chickenSlices,
      );
      expect(match, 1);
      expect(chickenSlices[match!].gramWeight, 60);
    });

    test('4 slices chicken breast scale the medium slice, 240 g', () {
      // Was 120 g. The count multiplies whichever row the word picked, so
      // the tie rule moves the whole amount, not just the label.
      final match = matchPortionToQuery(
        '4 slices chicken breast',
        chickenSlices,
      );
      expect(match, 1);
      expect(4 * chickenSlices[match!].gramWeight, 240);
    });

    test(
      '"eine mittlere Hähnchenbrust" keys medium onto the breast, 150 g',
      () {
        // Chicken breast, stewed (2705965) as a German reader receives it:
        // the slice ladder verified, the breast ladder still English. The key
        // "medium" ties the medium breast and the medium slice; both name the
        // middle rung, so the earlier row — the breast — stands. Unchanged
        // from before, and now by rule rather than by row order.
        final chicken = [
          _p(
            '1 Tasse, gegart, gewürfelt',
            grams: 135,
            en: '1 cup, cooked, diced',
          ),
          _p('1 small breast', grams: 130),
          _p('1 medium breast', grams: 150),
          _p('1 large breast', grams: 170),
          _p(
            '1 kleine oder dünne Scheibe',
            grams: 30,
            en: '1 small or thin slice',
          ),
          _p('1 mittlere Scheibe', grams: 60, en: '1 medium slice'),
          _p(
            '1 große oder dicke Scheibe',
            grams: 85,
            en: '1 large or thick slice',
          ),
        ];

        final match = matchPortionToKey('medium', chicken);
        expect(match, 2);
        expect(chicken[match!].gramWeight, 150);
      },
    );

    test('a large pizza has no middle rung, so the earliest stands, 119 g', () {
      // "large" ties the piece and the whole pizza; neither says medium or
      // regular, so the rule does nothing and the backend's order decides
      // exactly as before.
      final pizza = [
        _p('1 piece, large pizza', grams: 119),
        _p('1 large pizza (13-15" diameter)', grams: 954),
      ];

      final match = matchPortionToQuery('a large pizza', pizza);
      expect(match, 0);
      expect(pizza[match!].gramWeight, 119);
      expect(matchPortionToKey('large', pizza), 0);
    });

    test('"regular" names the middle rung too', () {
      // FDC writes it both ways: "1 medium or regular slice", "1 regular",
      // "1 small/regular fillet".
      final rows = [_p('1 thin slice'), _p('1 regular slice')];
      expect(matchPortionToQuery('a slice', rows), 1);
    });

    test('the rule only selects among rows the word already tied', () {
      // A longer match still beats a middle-rung row with a shorter one:
      // "cooked" is the better term, and the medium row never tied.
      final rows = [_p('1 medium'), _p('1 cup, cooked')];
      expect(matchPortionToQuery('cooked rice', rows), 1);
    });

    test('the middle rung is read off the English label', () {
      // The ladder words are English and the English label is sent in every
      // locale, so a German reader's "Scheibe" lands on the regular slice
      // even though nothing in "1 mittlere oder normale Scheibe" says
      // "medium".
      final de = [
        _p('1 kleine oder dünne Scheibe', en: '1 small or thin slice'),
        _p('1 mittlere oder normale Scheibe', en: '1 medium or regular slice'),
        _p('1 große oder dicke Scheibe', en: '1 large or thick slice'),
      ];
      expect(matchPortionToQuery('eine Scheibe Brot', de), 1);
      expect(matchPortionToKey('slice', de), 1);
    });

    test('the unqualified default is untouched', () {
      // #864 decision 7: naming no portion at all still means the first row.
      // The tie rule never runs because nothing tied.
      expect(matchPortionToQuery('bread', bread), isNull);
      expect(matchPortionToKey(null, bread), isNull);
    });
  });
}
