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

  group('parseMealText CJK separators', () {
    // A Chinese, Japanese or Korean keyboard emits these by default, so
    // without them a user typing a list the only way their keyboard offers
    // gets one unparsed row regardless of what the placeholder shows.
    test('the ideographic comma separates items', () {
      final result = parseMealText('100g 吐司、250ml 牛奶、黑咖啡');

      expect(result.errors, isEmpty);
      expect(result.items.map((i) => i.query), ['吐司', '牛奶', '黑咖啡']);
      expect(result.items.map((i) => i.quantity), [100, 250, null]);
    });

    test('the fullwidth comma and semicolon separate items', () {
      expect(parseMealText('100g 吐司，250ml 牛奶').items, hasLength(2));
      expect(parseMealText('100g 吐司；250ml 牛奶').items, hasLength(2));
    });

    test('the ideographic space is treated as whitespace', () {
      // U+3000 is matched by \\s, so a quantity separated from the food by
      // one is still recognised.
      final item = parseMealText('100g\u3000吐司').items.single;

      expect(item.query, '吐司');
      expect(item.quantity, 100);
      expect(item.unit, 'g');
    });

    test('CJK and ASCII separators mix in one line', () {
      final result = parseMealText('100g toast，2 eggs、200ml milk');

      expect(result.items.map((i) => i.query), ['toast', 'eggs', 'milk']);
    });

    test('none of them carries a decimal meaning', () {
      // Unlike ',' these never need the digit-on-both-sides guard, so a
      // number on both sides must still split. The leading '1' then has no
      // letters and is reported rather than logged, which is the proof the
      // split happened at all.
      final result = parseMealText('1，5 l milk');

      expect(result.items.single.quantity, 5000);
      expect(result.items.single.unit, 'ml');
      expect(result.errors, [InvalidFoodNameError(1)]);
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

    test('a negative quantity is rejected, not swallowed into the query', () {
      // The number pattern matches the leading '-' on purpose. If it did
      // not, the segment would fall through to the food search as the
      // literal query '-5g sugar' and the review row would quietly apply
      // the default amount — the user typed -5 and would get 100. Matching
      // it routes the input into the same bound that rejects '0g water'.
      final result = parseMealText('-5g sugar');

      expect(result.items, isEmpty);
      expect(result.errors, [QuantityTooSmallError(1)]);
    });

    test('a negative trailing quantity is rejected too', () {
      final result = parseMealText('sugar -5g');

      expect(result.items, isEmpty);
      expect(result.errors, [QuantityTooSmallError(1)]);
    });

    test('a negative kg quantity is rejected after conversion', () {
      final result = parseMealText('-5kg flour');

      expect(result.items, isEmpty);
      expect(result.errors, [QuantityTooSmallError(1)]);
    });

    test('a lone negative number is still an invalid food name', () {
      // No whitespace, so neither quantity regex matches and the segment
      // reaches FoodNameValidator whole — which rejects it for having no
      // letters, not for its sign.
      final result = parseMealText('-123');

      expect(result.items, isEmpty);
      expect(result.errors, [InvalidFoodNameError(1)]);
    });

    test('a hyphen inside a food name is left alone', () {
      // The '-' only reads as a sign when it is glued to the digits of a
      // quantity; hyphenated names must not be disturbed.
      final result = parseMealText('low-fat milk, 100g Coca-Cola');

      expect(result.errors, isEmpty);
      expect(result.items.map((i) => i.query), ['low-fat milk', 'Coca-Cola']);
    });
  });

  group('parseMealText multi-word foods with a bare quantity', () {
    // Regression: the unit group used to be a bare ([a-zA-Z]*), which
    // greedily took the first word of the food name as a candidate unit
    // and then discarded the whole match when it turned out not to be
    // one. '2 eggs' survived only because a single trailing word forced
    // the engine to backtrack into the no-unit reading; anything longer
    // silently lost its quantity.
    test('a two-word food keeps its quantity', () {
      final item = parseMealText('2 chicken breasts').items.single;

      expect(item.query, 'chicken breasts');
      expect(item.quantity, 2);
      expect(item.unit, isNull);
    });

    test('a three-word food keeps its quantity', () {
      final item = parseMealText('4 chocolate chip cookies').items.single;

      expect(item.query, 'chocolate chip cookies');
      expect(item.quantity, 4);
      expect(item.unit, isNull);
    });

    test('a food whose first word starts with a unit letter', () {
      // 'lemons' begins with 'l'; the unit group must not claim it.
      final item = parseMealText('2 lemons').items.single;

      expect(item.query, 'lemons');
      expect(item.quantity, 2);
      expect(item.unit, isNull);
    });

    test('an explicit unit before a multi-word food still parses', () {
      final item = parseMealText('200g chicken breasts').items.single;

      expect(item.query, 'chicken breasts');
      expect(item.quantity, 200);
      expect(item.unit, 'g');
    });

    test('several multi-word items in one line', () {
      final result = parseMealText('2 boiled eggs, 3 slices bread');

      expect(result.errors, isEmpty);
      expect(result.items.map((i) => i.query), ['boiled eggs', 'slices bread']);
      expect(result.items.map((i) => i.quantity), [2, 3]);
    });
  });

  group('parseMealText leaves the food name as the user typed it', () {
    // Regression: decimal commas used to be rewritten to '.' across the
    // whole input before segmentation, which also rewrote commas inside
    // food names — so the string handed to the food search contained
    // characters the user never typed.
    test('a comma inside a food name is not rewritten', () {
      final item = parseMealText('yoghurt 3,5% fat').items.single;

      expect(item.query, 'yoghurt 3,5% fat');
    });

    test('repeated digit-commas inside a food name are not rewritten', () {
      final item = parseMealText('Omega 3,6,9 capsules').items.single;

      expect(item.query, 'Omega 3,6,9 capsules');
    });

    test('a decimal comma in the quantity is still parsed as a number', () {
      // The conversion happens only on the number actually matched, so
      // this keeps working while the two cases above are left alone.
      final item = parseMealText('0,5kg rice').items.single;

      expect(item.query, 'rice');
      expect(item.quantity, 500);
      expect(item.unit, 'g');
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
      expect(result.errors, [InvalidFoodNameError(1)]);
    });

    test('a valid segment after a rejected one keeps its own item number', () {
      final result = parseMealText('123, toast');

      expect(result.errors, [InvalidFoodNameError(1)]);
      expect(result.items.single.query, 'toast');
    });

    test('empty segments do not consume an item number', () {
      // The leading empty segment (before the comma) is skipped silently,
      // so the invalid '123' is still 'Item 1', not 'Item 2'.
      final result = parseMealText(',123');

      expect(result.errors, [InvalidFoodNameError(1)]);
    });
  });

  group('parseMealText quantity bounds', () {
    test('a quantity of 0 is rejected', () {
      final result = parseMealText('0g water');

      expect(result.items, isEmpty);
      expect(result.errors, [QuantityTooSmallError(1)]);
    });

    test('a quantity over 10000 is rejected', () {
      final result = parseMealText('10001g flour');

      expect(result.items, isEmpty);
      expect(result.errors, [QuantityTooLargeError(1, 10000)]);
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
      expect(result.errors, [QuantityTooLargeError(1, 10000)]);
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

  group('a unit nobody wrote (#977)', () {
    // Every payload below was captured from the device, through the shipping
    // client, with a real key. They are what the two providers actually
    // answered — not what the schema asks for.

    test('anthropic answering a litre for a glass is dropped', () {
      // `ein Glas Milch` → `1 l`, normalised x1000 to 1000 ml, logged as
      // 470 kcal for a glass of milk. The whole reason this rule exists.
      final result = validateParsedMealItems(
        const [ParsedMealItem(query: 'Milch', quantity: 1, unit: 'l')],
        statedIn: 'ein Glas Milch',
      );

      expect(result.items.single.unit, isNull);
      expect(
        result.items.single.quantity,
        1,
        reason: 'dropped before the x1000, or the number cannot be put back',
      );
    });

    test('the same phrase answered as a millilitre is dropped too', () {
      // The other half of the coin flip: same input, same provider, `1 ml`.
      final result = validateParsedMealItems(
        const [ParsedMealItem(query: 'Milch', quantity: 1, unit: 'ml')],
        statedIn: 'ein Glas Milch',
      );

      expect(result.items.single.unit, isNull);
    });

    test('`l` inside `Glas` is not a stated unit', () {
      // A substring test reports a unit here, which would keep the litre and
      // change nothing. The token test is the fix.
      expect(textStatesAUnit('ein Glas Milch'), isFalse);
    });

    test('a stated unit is corroborated and kept', () {
      final result = validateParsedMealItems(
        const [ParsedMealItem(query: 'Milch', quantity: 200, unit: 'ml')],
        statedIn: '200ml Milch',
      );

      expect(result.items.single.unit, 'ml');
      expect(result.items.single.quantity, 200);
    });

    test('a stated litre still converts', () {
      // The conversion this rule must not break: it exists because dropping
      // a real litre silently logged 1.5 g/ml.
      final result = validateParsedMealItems(
        const [ParsedMealItem(query: 'Milch', quantity: 1.5, unit: 'l')],
        statedIn: '1,5 l Milch',
      );

      expect(result.items.single.unit, 'ml');
      expect(result.items.single.quantity, 1500);
    });

    test('a mixed line still states a unit, so nothing changes', () {
      // Whole-input, so `100g Toast, 2 Eier` is untouched — the narrowing
      // must not reach the ordinary case.
      final result = validateParsedMealItems(
        const [
          ParsedMealItem(query: 'Toast', quantity: 100, unit: 'g'),
          ParsedMealItem(query: 'Eier', quantity: 2),
        ],
        statedIn: '100g Toast, 2 Eier',
      );

      expect(result.items.first.unit, 'g');
      expect(result.items.first.quantity, 100);
    });

    test('the portion key survives, since it is not a unit', () {
      // Both providers answer `drei Scheiben Brot` correctly via `portion`,
      // and that is the field the dropped unit should have been.
      final result = validateParsedMealItems(
        const [
          ParsedMealItem(query: 'Brot', quantity: 3, portion: 'Scheiben'),
        ],
        statedIn: 'zwei Eier und drei Scheiben Brot',
      );

      expect(result.items.single.portion, 'Scheiben');
      expect(result.items.single.quantity, 3);
    });

    test('without the text nothing is dropped', () {
      // The photo path passes no text and has its own counts-only filter;
      // omitting the argument must behave exactly as before.
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: 'Milch', quantity: 1, unit: 'l'),
      ]);

      expect(result.items.single.unit, 'ml');
      expect(result.items.single.quantity, 1000);
    });
  });

  group('validateParsedMealItems', () {
    // The gate every non-deterministic source passes through, so a model
    // can never reach the diary under looser rules than the regex does.
    test('keeps a well-formed item unchanged', () {
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: 'toast', quantity: 100, unit: 'g'),
      ]);

      expect(result.items.single.query, 'toast');
      expect(result.items.single.quantity, 100);
      expect(result.items.single.unit, 'g');
      expect(result.errors, isEmpty);
    });

    test('applies the same bounds parseMealText applies', () {
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: '123'),
        ParsedMealItem(query: 'water', quantity: 0, unit: 'ml'),
        ParsedMealItem(query: 'flour', quantity: 15000, unit: 'g'),
      ]);

      expect(result.items, isEmpty);
      expect(result.errors, const [
        InvalidFoodNameError(1),
        QuantityTooSmallError(2),
        QuantityTooLargeError(3, 10000),
      ]);
    });

    test('numbers errors by position so the user can find the item', () {
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: 'toast', quantity: 100, unit: 'g'),
        ParsedMealItem(query: '456'),
      ]);

      expect(result.items.single.query, 'toast');
      expect(result.errors, const [InvalidFoodNameError(2)]);
    });

    test('drops an unconvertible unit but keeps the food and the amount', () {
      // Refusing the row outright would lose a usable food over a unit the
      // review row can default better than we can guess.
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: 'flour', quantity: 2, unit: 'cups'),
      ]);

      expect(result.items.single.unit, isNull);
      expect(result.items.single.quantity, 2);
      expect(result.errors, isEmpty);
    });

    test('normalizes kg and l the way parseMealText does', () {
      // Previously dropped, on the reasoning that nothing had normalized
      // them. A model reports litres, and dropping the unit silently was
      // worse than converting it — the model answered `1.5 l` as `1.5 ml`
      // when the enum offered no litre, a thousandfold under-count.
      final kg = validateParsedMealItems(const [
        ParsedMealItem(query: 'flour', quantity: 2, unit: 'kg'),
      ]).items.single;
      expect(kg.quantity, 2000);
      expect(kg.unit, 'g');

      final litres = validateParsedMealItems(const [
        ParsedMealItem(query: 'milk', quantity: 1.5, unit: 'l'),
      ]).items.single;
      expect(litres.quantity, 1500);
      expect(litres.unit, 'ml');
    });

    test('bounds are applied after normalizing, not before', () {
      // 15 kg is 15000 g, over the maximum. Checking first would let it
      // through as a harmless-looking 15.
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: 'flour', quantity: 15, unit: 'kg'),
      ]);

      expect(result.items, isEmpty);
      expect(result.errors, [const QuantityTooLargeError(1, 10000)]);
    });

    test('is not fooled by the casing a caller sends', () {
      // parseMealText lower-cases what it extracts; this entry point takes
      // whatever a caller supplies. A model answering `KG` would otherwise
      // lose its unit and keep its number as a bare count — 2 instead of
      // 2000 g, through casing alone.
      for (final written in ['KG', 'Kg', 'kg']) {
        final result = validateParsedMealItems([
          ParsedMealItem(query: 'flour', quantity: 2, unit: written),
        ]);
        expect(result.items.single.quantity, 2000, reason: written);
        expect(result.items.single.unit, 'g', reason: written);
      }
      expect(
        validateParsedMealItems(const [
          ParsedMealItem(query: 'milk', quantity: 1, unit: 'L'),
        ]).items.single.quantity,
        1000,
      );
    });

    test('a unit the app cannot convert is dropped, the number kept', () {
      // `2 tbsp` becoming `2 g` is a thirteenfold under-count nobody is
      // shown. A bare `2` is a number the review row already questions.
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: 'olive oil', quantity: 2, unit: 'tbsp'),
      ]);

      expect(result.items.single.quantity, 2);
      expect(result.items.single.unit, isNull);
    });

    test('a unit with no quantity is dropped, not presented as stated', () {
      // parseMealText cannot produce this pair, so downstream code was
      // written assuming it never happens. A model can produce it.
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: 'milk', unit: 'ml'),
      ]);

      expect(result.items.single.unit, isNull);
      expect(result.items.single.quantity, isNull);
      expect(result.errors, isEmpty);
    });

    test('a non-finite quantity is dropped, not carried into the row', () {
      // Both bounds are false for NaN, so without an explicit check it
      // survives validation and renders as the literal text "NaN".
      // `double.tryParse('NaN')` returns NaN, so a model answering with
      // that string is all it takes to get here.
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: 'toast', quantity: double.nan, unit: 'g'),
        ParsedMealItem(query: 'milk', quantity: double.infinity, unit: 'ml'),
        ParsedMealItem(
          query: 'flour',
          quantity: double.negativeInfinity,
          unit: 'g',
        ),
      ]);

      expect(result.items, hasLength(3));
      for (final item in result.items) {
        expect(
          item.quantity,
          isNull,
          reason: '${item.query} kept a non-finite',
        );
      }
      expect(result.errors, isEmpty);
    });

    test('a non-finite quantity takes its unit with it', () {
      // The sanitized quantity is what the unit hangs off. Reading the raw
      // value would leave `g` beside a null quantity — the very state the
      // unit-dropping rule above exists to prevent.
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: 'toast', quantity: double.nan, unit: 'g'),
      ]);

      expect(result.items.single.quantity, isNull);
      expect(result.items.single.unit, isNull);
    });

    test('trims the query so a padded name still reaches the search', () {
      final result = validateParsedMealItems(const [
        ParsedMealItem(query: '  toast  '),
      ]);

      expect(result.items.single.query, 'toast');
    });

    test('an empty list is not an error', () {
      final result = validateParsedMealItems(const []);

      expect(result.items, isEmpty);
      expect(result.errors, isEmpty);
      expect(result.hasErrors, isFalse);
    });
  });

  group('scripts without spaces between words (#623)', () {
    // Chinese, Japanese and Korean write a number flush against the thing
    // it counts. The parser found quantities by looking for whitespace, so
    // none of this parsed at all — including weights written with the very
    // Latin unit symbols the placeholder used to demonstrate.
    test('a count reads even with no space after it', () {
      final result = parseMealText('2个鸡蛋');

      expect(result.items.single.quantity, 2);
      // The counter stays on the query. `resolver_relevance` matches CJK by
      // character bigrams, so `个鸡蛋` still finds `鸡蛋` — which is why no
      // list of measure words is needed.
      expect(result.items.single.query, contains('鸡蛋'));
    });

    test('a Latin unit symbol works without a space', () {
      final result = parseMealText('100g吐司');

      expect(result.items.single.query, '吐司');
      expect(result.items.single.quantity, 100);
      expect(result.items.single.unit, 'g');
    });

    test('pounds are extracted, not stranded in the food name', () {
      // `lb` was normalizable but not extractable, so `2 lb chicken` sent
      // "lb chicken" to the food search with the amount as a bare count.
      final result = parseMealText('2 lb chicken').items.single;

      expect(result.query, 'chicken');
      expect(result.quantity, closeTo(907.18, 0.01));
      expect(result.unit, 'g');
    });

    test('lb is matched before the single-letter l', () {
      // Alternation order matters: `l` first would match the `l` of `lb`
      // and leave a stray `b` on the food name.
      expect(parseMealText('1 lb mince').items.single.query, 'mince');
      expect(parseMealText('1 l milk').items.single.quantity, 1000);
    });

    test('the Han forms of gram and millilitre are units', () {
      final grams = parseMealText('100克吐司').items.single;
      expect(grams.query, '吐司');
      expect(grams.quantity, 100);
      expect(grams.unit, 'g');

      final millis = parseMealText('200毫升牛奶').items.single;
      expect(millis.quantity, 200);
      expect(millis.unit, 'ml');
    });

    test('the Han kilogram and litre convert like kg and l', () {
      expect(parseMealText('1千克面粉').items.single.quantity, 1000);
      expect(parseMealText('1升水').items.single.unit, 'ml');
      expect(parseMealText('1升水').items.single.quantity, 1000);
    });

    test('a full line splits into its items', () {
      final result = parseMealText('2个鸡蛋，200ml牛奶，黑咖啡');

      expect(result.items, hasLength(3));
      expect(result.items[1].quantity, 200);
      expect(result.items[1].unit, 'ml');
      expect(result.items[2].quantity, isNull);
    });

    test('a trailing quantity works without a space too', () {
      expect(parseMealText('鸡蛋2').items.single.quantity, 2);
    });

    test('Latin parsing is unchanged by the script boundary', () {
      // The boundary rule touches the same regex the #616 backtracking bug
      // lived in, so the cases that bug produced are re-checked here.
      expect(parseMealText('100g toast').items.single.query, 'toast');
      expect(parseMealText('2 chicken breasts').items.single.quantity, 2);
      expect(parseMealText('1,5 l Milch').items.single.quantity, 1500);
      expect(parseMealText('toast 100g').items.single.unit, 'g');
      // Still not a unit, so still not a quantity.
      expect(parseMealText('100xyz Toast').items.single.quantity, isNull);
    });
  });
}
