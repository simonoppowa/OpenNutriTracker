import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

import '../fixture/backend_sibling_fixtures.dart';

/// #1164, pinned over real backend rows: with the near-duplicate collapse
/// off for backend records and their full descriptions shown, which of a
/// family of same-titled FDC siblings does the resolver auto-select, and
/// do the others survive into the candidate list?
///
/// Every expectation here is the measured one — the fixtures are copied
/// from the backend, not tuned — and the ones that differ from what the
/// decision comment reckoned say so in place. The path is the resolver's
/// own: `mergeAndRankMeals` over the two source lists, then
/// `rankForResolution`, exactly as `ResolveParsedMealsUseCase` does it.
List<MealEntity> resolve(
  String query, {
  List<MealEntity> off = const [],
  List<MealEntity> backend = const [],
}) => rankForResolution(mergeAndRankMeals(off, backend, query), query);

List<String> names(List<MealEntity> meals) => [for (final m in meals) m.name!];

MealEntity offProduct(String name, {required String barcode}) => MealEntity(
  code: barcode,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.off,
);

void main() {
  group('backend siblings are not duplicates', () {
    test('every egg record survives into the candidate list', () {
      // Shown by short title and collapsed by name, the four were one
      // entry called "Egg"; "Egg, yolk only, raw" was the one #1164 caught
      // going missing.
      final candidates = resolve('egg', backend: BackendSiblingFixtures.egg);

      expect(candidates, hasLength(4));
      expect(names(candidates), contains('Egg, yolk only, raw'));
      expect(names(candidates), contains('Egg, whole, raw'));
    });

    test('the yolk record stays even when it is called "Egg"', () {
      // The decision's own example, as the app showed it before the
      // display change: the four records reaching the collapse under their
      // short title. The test above cannot tell the two changes apart —
      // full descriptions alone would keep the yolk visible — so this one
      // pins the collapse on its own: backend records are left alone
      // whatever they are called.
      MealEntity byShortTitle(MealEntity record) => MealEntity(
        code: record.code,
        name: 'Egg',
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: 'g',
        servingSize: null,
        nutriments: record.nutriments,
        source: record.source,
        backendSource: record.backendSource,
        portions: record.portions,
      );

      final candidates = resolve(
        'egg',
        backend: [for (final r in BackendSiblingFixtures.egg) byShortTitle(r)],
      );

      expect(candidates, hasLength(4));
      expect(
        candidates.map((m) => m.code),
        contains(BackendSiblingFixtures.eggYolkOnlyRaw.code),
      );
    });

    test('three sources\' "Eggplant, raw" are three candidates', () {
      // Same full description in SR Legacy, Foundation and the survey —
      // three records, three nutrient profiles, and only the survey one
      // with portions. A name-keyed collapse would keep one of them and
      // lose the other two with the description shown as it is now.
      final candidates = resolve(
        'eggplant',
        backend: BackendSiblingFixtures.eggplant,
      );

      expect(candidates, hasLength(3));
      expect(
        candidates.map((m) => m.backendSource),
        containsAll(['fdc_sr_legacy', 'fdc_foundation', 'fdc_survey']),
      );
      // And the one that can scale an amount is the one auto-selected.
      expect(candidates.first.backendSource, 'fdc_survey');
    });

    test('an OFF pair sharing a name still collapses', () {
      final candidates = resolve(
        'egg',
        off: [
          offProduct('Eggs', barcode: '4000000000001'),
          offProduct('Eggs', barcode: '4000000000002'),
        ],
        backend: BackendSiblingFixtures.egg,
      );

      expect(names(candidates).where((n) => n == 'Eggs'), hasLength(1));
      expect(candidates, hasLength(5));
    });
  });

  group('auto-select among equal text scores', () {
    // Each family's siblings tie on the text score for the one-word query,
    // so the winner is the tie-break's: most labelled portions, then the
    // shortest name.
    test('apple resolves to Apple, raw', () {
      // 7 deliverable portions against 2 for dried and 2 for baked.
      expect(
        names(resolve('apple', backend: BackendSiblingFixtures.apple)).first,
        'Apple, raw',
      );
    });

    test('banana resolves to Banana, raw', () {
      // 5 against 2.
      expect(
        names(resolve('banana', backend: BackendSiblingFixtures.banana)).first,
        'Banana, raw',
      );
    });

    test('bread resolves to Bread, white: portions beat the shorter name', () {
      // "Bread, rye" is two characters shorter and listed first; "Bread,
      // white" carries 7 deliverable portions to its 5. The only family in
      // this pool where the two keys disagree, so the only real-row proof
      // that portions are consulted before name length.
      expect(
        names(resolve('bread', backend: BackendSiblingFixtures.bread)).first,
        'Bread, white',
      );
    });

    test('milk resolves to Milk, NFS', () {
      // Measured: Milk, NFS and Milk, whole both carry three deliverable
      // portions (the decision's "5" was a raw row count; of the six rows
      // two are `Guideline amount` and one `Quantity not specified`, and
      // the RPC drops those), so this is the name-length key deciding,
      // with whole listed first in the fixture to prove it.
      expect(
        names(resolve('milk', backend: BackendSiblingFixtures.milk)).first,
        'Milk, NFS',
      );
    });

    test('egg resolves to Egg, creamed, as measured', () {
      // The decision expected "Egg, whole, boiled or poached" (3 portions)
      // on the theory that the family ties on text. It does not: shown by
      // full description the resolver's soft Dice charges every extra token,
      // and "Egg, creamed" has two tokens to "Egg, whole, raw"'s three and
      // "Egg, whole, boiled or poached"'s five. The tie-break is never
      // reached. Pinned as measured so a later change to the text score
      // shows up here rather than in a diary.
      final ranked = resolve('egg', backend: BackendSiblingFixtures.egg);

      expect(names(ranked).first, 'Egg, creamed');
      expect(
        scoreMealForResolution(BackendSiblingFixtures.eggCreamed, 'egg'),
        greaterThan(
          scoreMealForResolution(
            BackendSiblingFixtures.eggWholeBoiledOrPoached,
            'egg',
          ),
        ),
      );
    });

    test('rice resolves to Rice, cooked, NFS: the known miss never forms', () {
      // The decision accepted "rice" landing on a Puerto Rican variant
      // because the two tied on text and the variant had more portions.
      // With full descriptions they do not tie — three tokens against
      // eight — and each carries exactly one deliverable portion (the
      // variant's other three rows are `yields` and `Quantity not
      // specified`, which the RPC drops), so the text score alone picks
      // the plain record. Known and accepted either way: the collapse no
      // longer hides the sibling, and it is one tap away on the review
      // screen.
      expect(
        names(resolve('rice', backend: BackendSiblingFixtures.rice)).first,
        'Rice, cooked, NFS',
      );
    });
  });

  group('the no-portions penalty', () {
    test('BLS Orange juice is penalised but still leads the survey record', () {
      // What the decision wanted: the exact-title BLS record, with nothing
      // to scale an amount by, dropping behind "Orange juice, 100%". What
      // is measured: the −0.15 was reckoned against the shared ranker's
      // 1.0-vs-0.9, and the resolver's own scorer puts the survey's
      // nearest real record, "Orange juice, 100%, NFS", at 0.667 — so at
      // 0.85 the BLS record keeps first place. Pinned as measured; the
      // penalty's size is a decision, and this test is where a change to
      // it will show.
      final ranked = resolve(
        'orange juice',
        backend: BackendSiblingFixtures.orangeJuice,
      );

      expect(names(ranked), ['Orange juice', 'Orange juice, 100%, NFS']);
      expect(
        scoreMealForResolution(
          BackendSiblingFixtures.orangeJuiceBls,
          'orange juice',
        ),
        closeTo(0.85, 1e-9),
      );
    });

    test('the Food tab keeps its order: the penalty is resolver-only', () {
      final bls = BackendSiblingFixtures.orangeJuiceBls;
      final survey = BackendSiblingFixtures.orangeJuice100Nfs;

      expect(scoreMealRelevance(bls, 'orange juice'), 1.0);
      expect(
        scoreMealRelevance(bls, 'orange juice'),
        greaterThan(scoreMealRelevance(survey, 'orange juice')),
      );
      expect(
        names(rankMealsByRelevance([survey, bls], 'orange juice')).first,
        'Orange juice',
      );
    });

    test('an OFF product with no portions is not penalised', () {
      final off = offProduct('Orange juice', barcode: '4000000000003');

      expect(scoreMealForResolution(off, 'orange juice'), 1.0);
      expect(
        scoreMealForResolution(off, 'orange juice'),
        greaterThan(
          scoreMealForResolution(
            BackendSiblingFixtures.orangeJuiceBls,
            'orange juice',
          ),
        ),
      );
    });
  });

  group('determinism', () {
    test('chicken breast resolves to the same record in every input order', () {
      final pool = BackendSiblingFixtures.chickenBreast;
      final winners = <String>{};
      for (var shift = 0; shift < pool.length; shift++) {
        final rotated = [...pool.skip(shift), ...pool.take(shift)];
        winners.add(names(resolve('chicken breast', backend: rotated)).first);
        // And once more with the pool reversed from that rotation.
        winners.add(
          names(
            resolve('chicken breast', backend: rotated.reversed.toList()),
          ).first,
        );
      }

      expect(winners, {'Chicken breast, rotisserie, skin eaten'});
    });

    test('the portionless SR Legacy record never wins chicken breast', () {
      // It ties the rotisserie record on text (five tokens each) and would
      // be a coin flip on pool order; the portions key and the penalty
      // both say no.
      final ranked = resolve(
        'chicken breast',
        backend: BackendSiblingFixtures.chickenBreast,
      );

      expect(
        names(ranked).indexOf('Chicken breast, roll, oven-roasted'),
        greaterThan(0),
      );
    });

    test('rankForResolution is stable when every key ties', () {
      // Two real survey records that tie on all three keys for "rice":
      // two tokens each, five deliverable portions each, eleven characters
      // each. What is left is the order they came in.
      final bread = BackendSiblingFixtures.breadRice;
      final chips = BackendSiblingFixtures.chipsRice;

      expect(names(rankForResolution([bread, chips], 'rice')), [
        'Bread, rice',
        'Chips, rice',
      ]);
      expect(names(rankForResolution([chips, bread], 'rice')), [
        'Chips, rice',
        'Bread, rice',
      ]);
    });
  });
}
