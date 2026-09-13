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
    // Every row `portions_by_food_ids` serves for these foods, in its
    // order, as read from production on 2026-09-13. Full sets, because a
    // subset can hide which term wins: dropped the breast rows, "a slice of
    // chicken breast" pins 60 g on the typed path; with them, it does not.

    // Bread, white (2707598). FDC lists a ladder small-first, so the
    // earliest slice is the thin one.
    final bread = [
      _p('1 small or thin/very thin slice', grams: 24),
      _p('1 medium or regular slice', grams: 28),
      _p('1 large or thick slice', grams: 43),
      _p('1 slice, crust not eaten', grams: 13),
      _p('1 slice, snack-size', grams: 10),
      _p('1 cup', grams: 40),
      _p('1 cubic inch', grams: 2.8),
    ];

    // Chicken breast, stewed (2705965): a breast ladder and a slice ladder.
    final chicken = [
      _p('1 cup, cooked, diced', grams: 135),
      _p('1 small breast', grams: 130),
      _p('1 medium breast', grams: 150),
      _p('1 large breast', grams: 170),
      _p('1 small or thin slice', grams: 30),
      _p('1 medium slice', grams: 60),
      _p('1 large or thick slice', grams: 85),
      _p('1 oz, cooked', grams: 28.35),
    ];

    // Pizza, cheese (2708614): a ladder of pieces, then a ladder of pies.
    final pizza = [
      _p('1 piece, small pizza', grams: 80),
      _p('1 piece, medium pizza', grams: 86),
      _p('1 piece, large pizza', grams: 119),
      _p('1 piece, extra-large pizza', grams: 128),
      _p('1 personal size pizza (5-7" diameter)', grams: 175),
      _p('1 small pizza (8-10" diameter)', grams: 480),
      _p('1 medium pizza (11-12" diameter)', grams: 691),
      _p('1 large pizza (13-15" diameter)', grams: 954),
      _p('1 extra-large pizza (16-18" diameter)', grams: 1278),
      _p('1 surface inch', grams: 6.2),
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

    test('the key "slice" on chicken breast is the medium slice, 60 g', () {
      // Was 30 g: small-first again. This is the table's row — the model
      // named `slice` and the key went against the slice ladder.
      final match = matchPortionToKey('slice', chicken);
      expect(match, 5);
      expect(chicken[match!].gramWeight, 60);
    });

    test('4 of that key scale the medium slice, 240 g', () {
      // Was 120 g. The count multiplies whichever row the word picked, so
      // the tie rule moves the whole amount, not just the label.
      final match = matchPortionToKey('slice', chicken);
      expect(4 * chicken[match!].gramWeight, 240);
    });

    test('typed, "a slice of chicken breast" lands on the breast ladder', () {
      // Not the table's 60 g, and a limit rather than a rule. The food's own
      // name is a term of its labels, and "breast" outscores "slice" by a
      // letter, so the typed words tie the three breasts and the rung picks
      // the medium one. The base tied them too and took the small breast,
      // 130 g; the slice the user named was never in reach on this path,
      // which only the key path — one English word, no food name — is.
      final match = matchPortionToQuery('a slice of chicken breast', chicken);
      expect(match, 2);
      expect(chicken[match!].gramWeight, 150);
    });

    test(
      '"eine mittlere Hähnchenbrust" keys medium onto the breast, 150 g',
      () {
        // Chicken breast, stewed (2705965) as a German reader receives it:
        // the slice ladder verified, the breast ladder still English. The key
        // "medium" ties the medium breast and the medium slice; both name the
        // middle rung, so the earlier row — the breast — stands. Unchanged
        // from before, and now by rule rather than by row order.
        final de = [
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
          _p('1 oz, gegart', grams: 28.35, en: '1 oz, cooked'),
        ];

        final match = matchPortionToKey('medium', de);
        expect(match, 2);
        expect(de[match!].gramWeight, 150);
      },
    );

    test('a large pizza has no middle rung, so the earliest stands, 119 g', () {
      // "large" ties the piece and the whole pizza; neither says medium or
      // regular, so the rule does nothing and the backend's order decides
      // exactly as before. Typed, "large" and "pizza" both land on those two
      // rows and on no other, so the same tie forms and the same row wins.
      final typed = matchPortionToQuery('a large pizza', pizza);
      expect(typed, 2);
      expect(pizza[typed!].gramWeight, 119);
      expect(matchPortionToKey('large', pizza), 2);
    });

    test('a size the user typed breaks the tie, on every ladder', () {
      // A row is scored by the total length of the terms it matched, so
      // "small slice" scores the small slice on two terms and the other
      // slices on one; no tie, no rung, the size the user asked for. Scored
      // by the single longest term instead, "small" never outweighed the
      // noun beside it — "1 small slice of bread" tied every slice and
      // logged the medium one, 28 g for the 24 g the user named; "2 small
      // chicken breasts" the medium breast for the small; "1 small pizza"
      // the medium piece for the small. The base got these right by row
      // order and the wrong ones below by the same accident.
      expect(matchPortionToQuery('small slice of bread', bread), 0);
      expect(matchPortionToQuery('small chicken breasts', chicken), 1);
      expect(matchPortionToQuery('small pizza', pizza), 0);
      // Larger sizes never won on the base — the small row was earliest and
      // scored the same — and do now, by the same rule.
      expect(matchPortionToQuery('large slice of bread', bread), 2);
      expect(matchPortionToQuery('large chicken breasts', chicken), 3);
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

    test('a food whose own name is a label term goes to its rung too', () {
      // Cookie, chocolate chip (2707909) and Roll, NS (2707595), every row
      // as served. The matcher holds no word list and cannot tell "cookie"
      // from "slice": "2 cookies" hits every cookie row, and the tie goes to
      // the medium cookie, 30 g. The base resolved the same tie to the
      // earliest row — the 5 g bite-size cookie, which is also the default,
      // so the match changed nothing and was invisible. The rung is the
      // same reading of the data's convention either way; this pins the
      // reach so that it is a decision and not a surprise.
      final cookie = [
        _p('1 mini or bite size cookie', grams: 5),
        _p('1 small cookie', grams: 20),
        _p('1 medium cookie', grams: 30),
        _p('1 large cookie', grams: 45),
        _p('1 small bar', grams: 25),
        _p('1 medium bar', grams: 38),
        _p('1 large bar', grams: 56),
        _p('1 Nabisco Chips Ahoy!', grams: 10.5),
        _p('1 Keebler Rainbow Chips Deluxe', grams: 16),
        _p('1 Pepperidge Farm Chocolate Chunk Cookie', grams: 26),
        _p("1 McDonald's cookie", grams: 33),
        _p('1 Subway cookie', grams: 45),
        _p('1 single serving package', grams: 46),
        _p('1 100 calorie package', grams: 22),
        _p('1 cup, bite size', grams: 81),
      ];
      final cookies = matchPortionToQuery('cookies', cookie);
      expect(cookies, 2);
      expect(cookie[cookies!].gramWeight, 30);

      final roll = [
        _p('1 miniature/small roll', grams: 28),
        _p('1 medium/regular/sandwich size roll', grams: 43),
        _p('1 large roll', grams: 52),
        _p('1 extra large roll', grams: 68),
        _p('1 hot dog bun', grams: 45),
        _p('1 hamburger bun', grams: 52),
        _p('1 foot long hot dog bun', grams: 83),
      ];
      expect(matchPortionToQuery('roll', roll), 1);
      // The typed size still decides, here as on the bread ladder.
      expect(matchPortionToQuery('small roll', roll), 0);
    });

    test('a query matching nothing still leaves the default alone', () {
      // #864 decision 7 as the code can keep it: no match means null, and
      // the row keeps its default. Bread's name is not a term of its labels,
      // so "3 bread" ties nothing and the rung never runs.
      expect(matchPortionToQuery('bread', bread), isNull);
      expect(matchPortionToKey(null, bread), isNull);
    });
  });
}
