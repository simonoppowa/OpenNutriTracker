import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

import '../fixture/backend_sibling_fixtures.dart';

/// #1164, pinned over real backend rows: with the near-duplicate collapse
/// off for backend records, their full descriptions shown and their short
/// titles scored, which of a family of same-titled FDC siblings does the
/// resolver auto-select, and do the others survive into the candidate
/// list?
///
/// The fixtures are copied from the backend, not tuned, and the winners
/// are the ones the decision reckoned: a family ties on its title, and the
/// portions key, then the description's length, settles it. An earlier
/// revision of this branch scored the description that is shown and pinned
/// what that measured — "Egg, creamed" on `egg`, BLS "Orange juice" ahead
/// of the survey record — because fewer tokens beat the tie-break to it.
/// The path is the resolver's own: `mergeAndRankMeals` over the two source
/// lists, then `rankForResolution`, exactly as `ResolveParsedMealsUseCase`
/// does it.
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

  group('scored on the short title, shown by the description', () {
    // A backend record's name is what the row shows and its searchTitle is
    // what the scorers read. The one is "Egg, whole, raw" and the other
    // "Egg", and the score is the one a record called "Egg" gets.
    MealEntity called(MealEntity record, String name) => MealEntity(
      code: record.code,
      name: name,
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

    test('eggs scores Egg, whole, raw as it scores Egg', () {
      final record = BackendSiblingFixtures.eggWholeRaw;

      expect(record.name, 'Egg, whole, raw');
      expect(record.searchTitle, 'Egg');
      expect(
        scoreMealForResolution(record, 'eggs'),
        scoreMealForResolution(called(record, 'Egg'), 'eggs'),
      );
      // And not as a record called by its description would score: every
      // token past the one that matched costs, 0.75 against 0.375.
      expect(scoreMealForResolution(record, 'eggs'), closeTo(0.75, 1e-9));
      expect(
        scoreMealForResolution(called(record, 'Egg, whole, raw'), 'eggs'),
        closeTo(0.375, 1e-9),
      );
    });

    test('the candidate list still shows the description', () {
      final ranked = resolve('eggs', backend: BackendSiblingFixtures.egg);

      expect(names(ranked), everyElement(startsWith('Egg, ')));
      expect(names(ranked), isNot(contains('Egg')));
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

    test('egg resolves to Egg, whole, boiled or poached by its portions', () {
      // All four are titled "Egg" and score 1.0 on the query, so the
      // portions key is reached: boiled or poached carries 3 deliverable
      // portions to 2 for each of the others. Scored on the description
      // instead, "Egg, creamed" won on having two tokens to "Egg, whole,
      // boiled or poached"'s five and the key was never consulted.
      final ranked = resolve('egg', backend: BackendSiblingFixtures.egg);

      expect(names(ranked).first, 'Egg, whole, boiled or poached');
      expect(names(ranked).first, isNot('Egg, creamed'));
      for (final record in BackendSiblingFixtures.egg) {
        expect(scoreMealForResolution(record, 'egg'), 1.0);
      }
      // The 2-portion records follow by description length: creamed (12),
      // whole raw (15), yolk only (19).
      expect(names(ranked), [
        'Egg, whole, boiled or poached',
        'Egg, creamed',
        'Egg, whole, raw',
        'Egg, yolk only, raw',
      ]);
    });

    test('rice resolves to Rice, cooked, NFS', () {
      // The decision accepted "rice" landing on a Puerto Rican variant
      // because the two tie on their title and it reckoned the variant had
      // more portions. Each carries exactly one deliverable portion (the
      // variant's other three rows are `yields` and `Quantity not
      // specified`, which the RPC drops), so the tie falls through to the
      // description's length and the plain record's 17 characters beat 48.
      expect(
        names(resolve('rice', backend: BackendSiblingFixtures.rice)).first,
        'Rice, cooked, NFS',
      );
    });

    test('Bread, rice and Chips, rice score nothing on rice', () {
      // Both are in the live pool for "rice", and scored on their
      // descriptions they outscored the plain record — two tokens against
      // three, a miss no tie-break could reach. Their titles are "Bread"
      // and "Chips", and on those the query matches nothing.
      final pool = [
        BackendSiblingFixtures.breadRice,
        BackendSiblingFixtures.chipsRice,
        ...BackendSiblingFixtures.rice,
      ];

      expect(
        scoreMealForResolution(BackendSiblingFixtures.breadRice, 'rice'),
        0.0,
      );
      expect(
        scoreMealForResolution(BackendSiblingFixtures.chipsRice, 'rice'),
        0.0,
      );
      expect(names(resolve('rice', backend: pool)).first, 'Rice, cooked, NFS');
      expect(names(resolve('rice', backend: pool)).sublist(2), [
        'Bread, rice',
        'Chips, rice',
      ]);
    });
  });

  group('the no-portions penalty', () {
    test('the penalty drops BLS Orange juice behind the survey record', () {
      // What the decision wanted: the exact-title BLS record, with nothing
      // to scale an amount by, dropping behind the survey's "Orange juice,
      // 100%, NFS". Both are titled "Orange juice" and score 1.0 on the
      // query, so the −0.15 is the whole difference. Scored on its
      // description the survey record sat at 0.667 and the BLS record kept
      // first place at 0.85. The penalty's size is a decision, and this
      // test is where a change to it will show.
      final ranked = resolve(
        'orange juice',
        backend: BackendSiblingFixtures.orangeJuice,
      );

      expect(names(ranked), ['Orange juice, 100%, NFS', 'Orange juice']);
      expect(
        scoreMealForResolution(
          BackendSiblingFixtures.orangeJuice100Nfs,
          'orange juice',
        ),
        1.0,
      );
      expect(
        scoreMealForResolution(
          BackendSiblingFixtures.orangeJuiceBls,
          'orange juice',
        ),
        closeTo(0.85, 1e-9),
      );
    });

    test('the Food tab keeps its order: the penalty is resolver-only', () {
      // The shared ranker scores both titles at 1.0 and knows nothing of
      // portions, so the two tie and the order they came in stands — the
      // BLS record is not moved behind the survey one there.
      final bls = BackendSiblingFixtures.orangeJuiceBls;
      final survey = BackendSiblingFixtures.orangeJuice100Nfs;

      expect(scoreMealRelevance(bls, 'orange juice'), 1.0);
      expect(scoreMealRelevance(survey, 'orange juice'), 1.0);
      expect(names(rankMealsByRelevance([bls, survey], 'orange juice')), [
        'Orange juice',
        'Orange juice, 100%, NFS',
      ]);
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

      // Every survey record is titled "Chicken breast" and scores 1.0, so
      // the portions key decides: baked carries 9 deliverable portions to 7
      // for rotisserie and for NS as to cooking method. (Scored on the
      // description, rotisserie won on having the fewest tokens.)
      expect(winners, {
        'Chicken breast, baked, broiled, or roasted, skin not eaten, from raw',
      });
    });

    test('the portionless SR Legacy record never wins chicken breast', () {
      // It ties every survey record on the title and would be a coin flip
      // on pool order; the portions key and the penalty both say no.
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
      // titled "Bread" and "Chips", so a score of zero each, then five
      // deliverable portions each and eleven characters each. What is left
      // is the order they came in. (Two records cannot
      // tell a stable sort from an unstable one — Dart insertion-sorts
      // short lists — so the forty-record case in resolver_relevance_test
      // is what pins the algorithm; this one pins the real rows.)
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
