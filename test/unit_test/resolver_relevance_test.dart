import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

MealEntity meal(
  String name, {
  MealSourceEntity source = MealSourceEntity.off,
  String? brands,
  String? code,
}) => MealEntity(
  code: code ?? name,
  name: name,
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
  nutriments: MealNutrimentsEntity.empty(),
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
