import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

MealEntity meal(
  String name, {
  MealSourceEntity source = MealSourceEntity.off,
  String? brands,
  String? code,
  String? searchTitle,
  int portions = 0,
  bool detailed = false,
}) => MealEntity(
  code: code ?? name,
  name: name,
  searchTitle: searchTitle,
  brands: brands,
  thumbnailImageUrl: null,
  mainImageUrl: null,
  url: null,
  mealQuantity: null,
  mealUnit: null,
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  source: source,
  detailed: detailed,
  nutriments: MealNutrimentsEntity.empty(),
  portions: [
    for (var i = 0; i < portions; i++)
      MealPortionEntity(
        label: '1 portion $i',
        gramWeight: 100,
        localized: false,
      ),
  ],
);

List<String> names(List<MealEntity> meals) => [for (final m in meals) m.name!];

void main() {
  group('inflection tolerance — the reason this scorer exists', () {
    test('a plural query ranks the singular record above a branded plural', () {
      // The shared ranker scores 'eggs' against 'Egg' at exactly 0.0
      // (token sets don't intersect, no contains, no prefix) while
      // 'Cadbury Creme Eggs' contains the literal plural and scores well
      // above it. Since the resolver auto-selects the top candidate, that
      // ordering would put a chocolate egg in the diary.
      const query = 'eggs';
      final rows = [meal('Cadbury Creme Eggs'), meal('Egg')];

      expect(names(rankForResolution(rows, query)).first, 'Egg');

      // Guard the premise: if the shared ranker is ever fixed, this test
      // should be revisited rather than silently passing for a new reason.
      expect(scoreMealRelevance(meal('Egg'), query), 0.0);
    });

    test('a multi-token generic beats a long branded name containing it', () {
      const query = 'black coffee';
      final rows = [
        meal('Nescafé Black Coffee Instant Refill 200g'),
        meal('Coffee'),
      ];

      expect(names(rankForResolution(rows, query)).first, 'Coffee');
    });

    test('German plural resolves to the singular record', () {
      // 'Eier' -> 'Ei' shares only two characters, which is below the
      // normal prefix floor — the floor relaxes for tokens shorter than
      // it so genuinely short words are not excluded by their own length.
      final rows = [meal('Eiersalat mit Mayonnaise'), meal('Ei')];

      expect(names(rankForResolution(rows, 'Eier')).first, 'Ei');
    });

    test('Italian and Turkish inflections resolve too', () {
      expect(
        names(
          rankForResolution([meal('Uova di quaglia'), meal('Uovo')], 'uova'),
        ).first,
        'Uovo',
      );
      expect(
        names(
          rankForResolution([
            meal('Yumurtalı ekmek'),
            meal('Yumurta'),
          ], 'yumurtalar'),
        ).first,
        'Yumurta',
      );
    });
  });

  group('the prefix guard', () {
    test('apple does not match apricot', () {
      // Both begin 'ap'. Without a floor this would score as a partial
      // match and could outrank a correct but lower-placed result.
      expect(scoreMealForResolution(meal('Apricot'), 'apple'), 0.0);
    });

    test('an unrelated word scores zero', () {
      expect(scoreMealForResolution(meal('Bicycle'), 'eggs'), 0.0);
    });

    test('an exact match still scores 1.0', () {
      expect(scoreMealForResolution(meal('Toast'), 'toast'), 1.0);
    });
  });

  group('behaviour that must not regress', () {
    test('toast still ranks the plain record first — the control', () {
      // This case already works with the shared ranker; the point of the
      // test is that the new scorer does not break it.
      final rows = [
        meal('Toast bread wholemeal sliced'),
        meal('Toast'),
        meal('Toasted sesame oil'),
      ];

      expect(names(rankForResolution(rows, 'toast')).first, 'Toast');
    });

    test('own content outranks remote results regardless of score', () {
      // A custom meal with a weaker text match must still come first —
      // the tier from mergeAndRankMeals is preserved, not re-sorted away.
      final rows = [
        meal('Egg'),
        meal('My scrambled eggs recipe', source: MealSourceEntity.custom),
      ];

      final ranked = rankForResolution(rows, 'eggs');

      expect(ranked.first.source, MealSourceEntity.custom);
      expect(names(ranked).last, 'Egg');
    });

    test('a brand-only match scores below the same match on the name', () {
      final byName = scoreMealForResolution(meal('Nescafe'), 'nescafe');
      final byBrand = scoreMealForResolution(
        meal('Instant Coffee Refill', brands: 'Nescafe'),
        'nescafe',
      );

      expect(byBrand, lessThan(byName));
      expect(byBrand, greaterThan(0.0));
    });

    test('an empty query scores zero rather than matching everything', () {
      expect(scoreMealForResolution(meal('Egg'), ''), 0.0);
      expect(scoreMealForResolution(meal('Egg'), '   '), 0.0);
    });

    test('ranking is stable for equally-scored rows', () {
      final rows = [meal('Egg', code: 'a'), meal('Egg', code: 'b')];

      final ranked = rankForResolution(rows, 'eggs');

      expect([for (final m in ranked) m.code], ['a', 'b']);
    });
  });

  group('tie-break among equal scores (#1164)', () {
    // Backend siblings are shown by their full description and score the
    // same on the one-word query for their family, so the order among them
    // is what the auto-select logs. The keys below are the decision's:
    // most labelled portions, then the shortest name, then the input order.
    test('the record with the most labelled portions comes first', () {
      final rows = [
        meal('Apple, dried', source: MealSourceEntity.fdc, portions: 2),
        meal('Apple, raw', source: MealSourceEntity.fdc, portions: 7),
      ];

      expect(names(rankForResolution(rows, 'apple')).first, 'Apple, raw');
    });

    test('equal portions break on the shorter name', () {
      final rows = [
        meal('Milk, whole', source: MealSourceEntity.fdc, portions: 3),
        meal('Milk, NFS', source: MealSourceEntity.fdc, portions: 3),
      ];

      expect(names(rankForResolution(rows, 'milk')).first, 'Milk, NFS');
    });

    test('portions outrank a shorter name', () {
      // The keys are ordered, not summed: a longer description with more
      // portions beats a shorter one with fewer.
      final rows = [
        meal('Apple, raw', source: MealSourceEntity.fdc, portions: 2),
        meal('Apple, baked', source: MealSourceEntity.fdc, portions: 7),
      ];

      expect(names(rankForResolution(rows, 'apple')).first, 'Apple, baked');
    });

    test('the tie-break never overrides the score', () {
      final rows = [
        meal('Egg, whole, raw', source: MealSourceEntity.fdc, portions: 9),
        meal('Egg, creamed', source: MealSourceEntity.fdc, portions: 1),
      ];

      expect(names(rankForResolution(rows, 'egg')).first, 'Egg, creamed');
    });

    test('equal score, portions and name length keep the input order', () {
      final rows = [
        meal(
          'Bread, rice',
          code: 'a',
          source: MealSourceEntity.fdc,
          portions: 5,
        ),
        meal(
          'Chips, rice',
          code: 'b',
          source: MealSourceEntity.fdc,
          portions: 5,
        ),
      ];

      List<String?> codes(List<MealEntity> meals) => [
        for (final m in meals) m.code,
      ];

      expect(codes(rankForResolution(rows, 'rice')), ['a', 'b']);
      expect(
        codes(rankForResolution(rows.reversed.toList(), 'rice')),
        ['b', 'a'],
      );
    });

    test('the input order survives a pool too large for insertion sort', () {
      // A two-record tie cannot tell a stable sort from `List.sort`: Dart
      // insertion-sorts anything under 32 elements, and that happens to be
      // stable. Above it the dual-pivot quicksort moves equal elements, so
      // forty records that tie on every key — score, portions, name length
      // — are what actually pins "stable after that".
      final rows = [
        for (var i = 0; i < 40; i++)
          meal(
            'Bread, rice',
            code: 'r$i',
            source: MealSourceEntity.fdc,
            portions: 5,
          ),
      ];

      expect(
        [for (final m in rankForResolution(rows, 'rice')) m.code],
        [for (var i = 0; i < 40; i++) 'r$i'],
      );
    });

    test('records without a name compare as zero-length names, stably', () {
      MealEntity nameless(String code) => MealEntity(
        code: code,
        name: null,
        brands: 'Milk',
        url: null,
        mealQuantity: null,
        mealUnit: null,
        servingQuantity: null,
        servingUnit: null,
        servingSize: null,
        source: MealSourceEntity.fdc,
        nutriments: MealNutrimentsEntity.empty(),
      );

      // Both match on the brand alone, so they tie on score and on portions
      // and reach the name-length key with nothing to measure.
      final ranked = rankForResolution(
        [nameless('a'), nameless('b')],
        'milk',
      );

      expect([for (final m in ranked) m.code], ['a', 'b']);
    });
  });

  group('scored on the short title (#1164)', () {
    // A backend record shows its description and is scored on its short
    // title, so a family of siblings ties on the one-word query for it and
    // the tie-break below is reached. Anything without a title — an OFF
    // product, a custom meal, a cached copy — is scored on its name as
    // before.
    test('a titled record scores as a record named by its title', () {
      final titled = meal(
        'Egg, whole, raw',
        searchTitle: 'Egg',
        source: MealSourceEntity.fdc,
        portions: 2,
      );
      final named = meal('Egg', source: MealSourceEntity.fdc, portions: 2);

      expect(
        scoreMealForResolution(titled, 'eggs'),
        scoreMealForResolution(named, 'eggs'),
      );
      expect(scoreMealForResolution(titled, 'eggs'), closeTo(0.75, 1e-9));
      expect(scoreMealForResolution(titled, 'egg'), 1.0);
    });

    test('the title is what is scored, not one input among two', () {
      // The description is not consulted at all once a title is there: a
      // record titled "Bread" scores nothing on `rice` although its
      // description contains the word.
      final breadRice = meal(
        'Bread, rice',
        searchTitle: 'Bread',
        source: MealSourceEntity.fdc,
        portions: 5,
      );

      expect(scoreMealForResolution(breadRice, 'rice'), 0.0);
    });

    test('an OFF product has no title and scores exactly as before', () {
      // The numbers the file header and the confidence floor were set
      // against: the inflection match, the branded superstring, the exact
      // name.
      expect(meal('Egg').searchTitle, isNull);
      expect(scoreMealForResolution(meal('Egg'), 'eggs'), closeTo(0.75, 1e-9));
      expect(
        scoreMealForResolution(meal('Cadbury Creme Eggs'), 'eggs'),
        closeTo(0.5, 1e-9),
      );
      expect(scoreMealForResolution(meal('Egg'), 'egg'), 1.0);
      expect(
        scoreMealForResolution(meal('Egg, whole, raw'), 'eggs'),
        closeTo(0.375, 1e-9),
      );
    });

    test('a shared title ties the family so the portions key is reached', () {
      // The mirror of "the tie-break never overrides the score" above:
      // scored on their descriptions the two-token record wins outright,
      // scored on their shared title the portions decide.
      final rows = [
        meal(
          'Egg, creamed',
          searchTitle: 'Egg',
          source: MealSourceEntity.fdc,
          portions: 1,
        ),
        meal(
          'Egg, whole, boiled or poached',
          searchTitle: 'Egg',
          source: MealSourceEntity.fdc,
          portions: 3,
        ),
      ];

      expect(
        names(rankForResolution(rows, 'egg')).first,
        'Egg, whole, boiled or poached',
      );
    });

    test('the name-length key measures the description, not the title', () {
      // Siblings that reach this key share a title, so its length is the
      // same on both sides and says nothing. The description is where they
      // differ: "Milk, NFS" is the less qualified record and comes first
      // although it is listed second.
      final rows = [
        meal(
          'Milk, whole',
          searchTitle: 'Milk',
          source: MealSourceEntity.fdc,
          portions: 3,
        ),
        meal(
          'Milk, NFS',
          searchTitle: 'Milk',
          source: MealSourceEntity.fdc,
          portions: 3,
        ),
      ];

      expect(names(rankForResolution(rows, 'milk')), [
        'Milk, NFS',
        'Milk, whole',
      ]);
    });
  });

  group('the no-portions penalty (#1164)', () {
    test('a backend record with no labelled portion loses 0.15', () {
      final withPortions = meal(
        'Orange juice',
        source: MealSourceEntity.fdc,
        portions: 1,
      );
      final without = meal('Orange juice', source: MealSourceEntity.fdc);

      expect(scoreMealForResolution(withPortions, 'orange juice'), 1.0);
      expect(
        scoreMealForResolution(without, 'orange juice'),
        closeTo(0.85, 1e-9),
      );
    });

    test('an OFF product is never penalised for having no portions', () {
      // OFF products never carry `portions` — the list is filled from the
      // backend's lookup and nowhere else — so penalising on emptiness
      // alone would demote every OFF product, which was not decided.
      final offProduct = meal('Orange juice', source: MealSourceEntity.off);

      expect(scoreMealForResolution(offProduct, 'orange juice'), 1.0);
    });

    test('the penalty is a subtraction from the score, not a cap on it', () {
      // A brand-only match already sits well below 1.0; the penalty comes
      // off that too, rather than only pulling an exact match down to 0.85.
      final byBrand = meal(
        'Instant Coffee Refill',
        brands: 'Nescafe',
        source: MealSourceEntity.fdc,
      );
      final byBrandWithPortions = meal(
        'Instant Coffee Refill',
        brands: 'Nescafe',
        source: MealSourceEntity.fdc,
        portions: 1,
      );

      expect(
        scoreMealForResolution(byBrand, 'nescafe'),
        closeTo(
          scoreMealForResolution(byBrandWithPortions, 'nescafe') - 0.15,
          1e-9,
        ),
      );
    });

    test('the penalty is resolver-only: the shared ranker does not see it', () {
      final without = meal('Orange juice', source: MealSourceEntity.fdc);

      expect(scoreMealRelevance(without, 'orange juice'), 1.0);
    });

    test('the penalty comes off before the clamp, not after it', () {
      // An exact title with the detailed bonus stands at 1.03 before the
      // clamp. Taking 0.15 off first leaves 0.88; clamping first and then
      // subtracting would give 0.85 — the bonus silently lost — and at the
      // other end would push a non-match below zero, off the 0.0-1.0 scale
      // the confidence floor is calibrated on.
      final detailedExact = meal(
        'Orange juice',
        source: MealSourceEntity.fdc,
        detailed: true,
      );
      final noMatch = meal('Orange juice', source: MealSourceEntity.fdc);

      expect(
        scoreMealForResolution(detailedExact, 'orange juice'),
        closeTo(0.88, 1e-9),
      );
      expect(scoreMealForResolution(noMatch, 'zucchini'), 0.0);
    });
  });

  group('confidence signal', () {
    test('a strong match scores well above a weak one', () {
      final strong = scoreMealForResolution(meal('Egg'), 'eggs');
      final weak = scoreMealForResolution(
        meal('Cadbury Creme Eggs Multipack 5 Pack'),
        'eggs',
      );

      expect(strong, greaterThan(weak));
      expect(strong, greaterThan(0.5));
      expect(weak, lessThan(0.5));
    });
  });

  group('scripts without spaces between words (#623)', () {
    // `_tokenize` splits on non-letters, so a CJK phrase arrives as one
    // token and the shared-prefix rule read it as a single long word.
    test('a longer product name still matches the query', () {
      // Scored 0.0 before: `土鸡蛋` contains `鸡蛋` but does not start with
      // it, so a `zh` search could miss the product it was looking at.
      expect(scoreMealForResolution(meal('土鸡蛋'), '鸡蛋'), greaterThan(0.3));
    });

    test('a leading counter does not stop the match', () {
      // This is what removes any need for a list of measure words: the
      // parser leaves `个` on the query and the ranker copes.
      expect(scoreMealForResolution(meal('鸡蛋'), '个鸡蛋'), greaterThan(0.3));
    });

    test('an exact match still scores highest', () {
      final exact = scoreMealForResolution(meal('鸡蛋'), '鸡蛋');
      final partial = scoreMealForResolution(meal('土鸡蛋'), '鸡蛋');
      expect(exact, greaterThan(partial));
    });

    test('unrelated foods still score nothing', () {
      expect(scoreMealForResolution(meal('牛奶'), '鸡蛋'), 0.0);
    });

    test('Latin scoring is unchanged', () {
      // The property #601 was built for: a plain food outranks a branded
      // name that happens to contain the query exactly.
      final plain = scoreMealForResolution(meal('Egg'), 'eggs');
      final branded = scoreMealForResolution(
        meal('Cadbury Creme Eggs'),
        'eggs',
      );
      expect(plain, greaterThan(branded));
    });
  });
}
