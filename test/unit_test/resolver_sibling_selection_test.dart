import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

import '../fixture/backend_pool_fixtures.dart';
import '../fixture/backend_sibling_fixtures.dart';

/// #1164, pinned over real backend rows: with the near-duplicate collapse
/// off for backend records, their full descriptions shown and their short
/// titles scored, which of a family of same-titled FDC siblings does the
/// resolver auto-select, and do the others survive into the candidate
/// list?
///
/// The fixtures are copied from the backend, not tuned, and the winners
/// are the ones the decision reckoned: a family ties on its title, and the
/// description's length, then the portions key, settles it. An earlier
/// revision of this branch scored the description that is shown and pinned
/// what that measured — "Egg, creamed" on `egg`, BLS "Orange juice" ahead
/// of the survey record — because fewer tokens beat the tie-break to it.
/// The revision after scored the title and nothing else, and every query
/// here was a bare title, so nothing showed that `dried apple` tied the
/// family too and the tie-break logged "Apple, raw": the qualifier the
/// user typed was the one thing the scorer could not see. A qualifier the
/// query names now joins the title (`MealEntity.scoringQualifiers`), and
/// a group below pins that. The tie-break itself was portions first until
/// the 39 survey families with more than twenty members were measured
/// (#1170): FDC counts a dish in more ways than its ingredient, so most
/// portions picked "Potato, french fries, fast food" over "Potato, NFS",
/// and the shortest description now goes first — which lands "Egg,
/// creamed" again, this time as a pinned known miss. The path is the
/// resolver's own: `mergeAndRankMeals` over the two source lists, then
/// `rankForResolution`, exactly as `ResolveParsedMealsUseCase` does it.
///
/// What the resolver is handed is the other half. The data source keeps
/// twenty of the hundred rows the backend sends, and the backend's hundred
/// are its own cut — the first hundred matches by deliverable portion,
/// then id — made before any client code runs. The family fixtures here
/// are real rows but not that hundred, so a winner pinned on a family
/// alone is the tie-break's answer, not always the app's: on the pool the
/// app is handed `bread` lands on "Bread, pita", because "Bread, rye" is
/// rank 157 and never arrives, and `potato` lands on a beef stew at 0.5,
/// because not one row titled "Potato" is inside the hundred (#1170
/// review). The last groups pin those on `BackendPoolFixtures`' real
/// pools, and the two ways the cut and the resolver read a pool
/// differently.
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
    // A backend record's name is what the row shows and its scoringName —
    // the name up to its first comma — is what the scorers read. The one
    // is "Egg, whole, raw" and the other "Egg", and the score is the one a
    // record called "Egg" gets.
    MealEntity called(
      MealEntity record,
      String name, {
      MealSourceEntity? source,
    }) => MealEntity(
      code: record.code,
      name: name,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: record.nutriments,
      source: source ?? record.source,
      backendSource: record.backendSource,
      portions: record.portions,
    );

    test('eggs scores Egg, whole, raw as it scores Egg', () {
      final record = BackendSiblingFixtures.eggWholeRaw;

      expect(record.name, 'Egg, whole, raw');
      expect(record.scoringName, 'Egg');
      expect(
        scoreMealForResolution(record, 'eggs'),
        scoreMealForResolution(called(record, 'Egg'), 'eggs'),
      );
      // And not as the description scored whole would — which is what an
      // OFF product with that name gets: every token past the one that
      // matched costs, 0.75 against 0.375.
      expect(scoreMealForResolution(record, 'eggs'), closeTo(0.75, 1e-9));
      expect(
        scoreMealForResolution(
          called(record, 'Egg, whole, raw', source: MealSourceEntity.off),
          'eggs',
        ),
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
    // so the winner is the tie-break's: the shortest description, then
    // the most labelled portions.
    test('apple resolves to Apple, raw', () {
      // 10 characters against 12 for dried and for baked.
      expect(
        names(resolve('apple', backend: BackendSiblingFixtures.apple)).first,
        'Apple, raw',
      );
    });

    test('banana resolves to Banana, raw', () {
      // 11 against 13.
      expect(
        names(resolve('banana', backend: BackendSiblingFixtures.banana)).first,
        'Banana, raw',
      );
    });

    test('rye over white: the shorter description beats more portions', () {
      // "Bread, white" carries 7 deliverable portions to rye's 5 and is
      // the everyday form; "Bread, rye" is two characters shorter. The
      // only family in these fixtures where the two keys disagree, so the
      // real-row proof that the length is consulted before the portions:
      // the pool is listed rye first, but reversing it changes nothing.
      // This is the key order on two rows, not the miss the app makes on
      // `bread` — rye is outside the hundred the backend sends, and the
      // app lands on pita; see the real-pool group below.
      expect(
        names(resolve('bread', backend: BackendSiblingFixtures.bread)).first,
        'Bread, rye',
      );
      expect(
        names(
          resolve(
            'bread',
            backend: BackendSiblingFixtures.bread.reversed.toList(),
          ),
        ).first,
        'Bread, rye',
      );
      expect(
        scoreMealForResolution(BackendSiblingFixtures.breadRye, 'bread'),
        1.0,
      );
      expect(
        scoreMealForResolution(BackendSiblingFixtures.breadWhite, 'bread'),
        1.0,
      );
      expect(BackendSiblingFixtures.breadWhite.portions, hasLength(7));
      expect(BackendSiblingFixtures.breadRye.portions, hasLength(5));
    });

    test('milk resolves to Milk, NFS, and the portions order the rest', () {
      // "Milk, NFS" is 9 characters to 11 for whole and for human, with
      // whole listed after human in the fixture. Whole and human tie on
      // the length, and the portions key is what is left: whole carries
      // three deliverable portions to human's two (the decision's "5" was
      // a raw row count; of "Milk, NFS"'s six rows two are `Guideline
      // amount` and one `Quantity not specified`, and the RPC drops those).
      // The only real-row proof here that the portions are consulted at
      // all.
      final ranked = resolve('milk', backend: BackendSiblingFixtures.milk);

      expect(names(ranked), ['Milk, NFS', 'Milk, whole', 'Milk, human']);
      expect(BackendSiblingFixtures.milkWhole.name!.length, 11);
      expect(BackendSiblingFixtures.milkHuman.name!.length, 11);
      expect(BackendSiblingFixtures.milkWhole.portions, hasLength(3));
      expect(BackendSiblingFixtures.milkHuman.portions, hasLength(2));
    });

    test('egg resolves to Egg, creamed: the known miss', () {
      // All four are titled "Egg" and score 1.0 on the query, so the
      // length key is reached, and "Egg, creamed" is 12 characters to 15
      // for "Egg, whole, raw" (#1170). The everyday form loses here, and
      // it is pinned as lost: the rule that picks it — most portions
      // first, which gave "Egg, whole, boiled or poached" its 3 to 2 —
      // picks the french fries over the potato in the large families, and
      // the siblings are one tap away on the review screen.
      final ranked = resolve('egg', backend: BackendSiblingFixtures.egg);

      expect(names(ranked).first, 'Egg, creamed');
      for (final record in BackendSiblingFixtures.egg) {
        expect(scoreMealForResolution(record, 'egg'), 1.0);
      }
      // The rest follow by description length: whole raw (15), yolk only
      // (19), boiled or poached (29).
      expect(names(ranked), [
        'Egg, creamed',
        'Egg, whole, raw',
        'Egg, yolk only, raw',
        'Egg, whole, boiled or poached',
      ]);
    });

    test('rice resolves to Rice, cooked, NFS', () {
      // The decision accepted "rice" landing on a Puerto Rican variant
      // because the two tie on their title and it reckoned the variant had
      // more portions. The length key settles it before any portion is
      // counted: the plain record's 17 characters beat the variant's 48.
      expect(
        names(resolve('rice', backend: BackendSiblingFixtures.rice)).first,
        'Rice, cooked, NFS',
      );
    });

    test('Bread, rice and Chips, rice stay under the plain record on rice', () {
      // Both are in the live pool for "rice", and scored on their
      // descriptions they outscored the plain record — two tokens against
      // three, a miss no tie-break could reach. Their titles are "Bread"
      // and "Chips", which the query matches nothing of; the `rice` they
      // carry past the title is named by the query and counts, so each
      // scores 0.667 — what an OFF product called "Bread rice" scores —
      // and the plain record's exact title, 1.0, is never tied.
      final pool = [
        BackendSiblingFixtures.breadRice,
        BackendSiblingFixtures.chipsRice,
        ...BackendSiblingFixtures.rice,
      ];

      expect(
        scoreMealForResolution(BackendSiblingFixtures.breadRice, 'rice'),
        closeTo(0.667, 1e-3),
      );
      expect(
        scoreMealForResolution(BackendSiblingFixtures.chipsRice, 'rice'),
        closeTo(0.667, 1e-3),
      );
      expect(
        scoreMealForResolution(BackendSiblingFixtures.riceCookedNfs, 'rice'),
        1.0,
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
      // the length key decides: stewed's 34 characters to 38 for
      // rotisserie, 51 for NS as to cooking method and 68 for baked, which
      // carries the most portions (9 to 8) and won while the portions came
      // first. Stewed is the shortest survey description in the pool the
      // app is handed too — 98 rows, all inside the backend's hundred — so
      // this is the app's answer; c78b5a38's fixture left it out and
      // pinned rotisserie.
      expect(winners, {'Chicken breast, stewed, skin eaten'});
    });

    test('the portionless SR Legacy record never wins chicken breast', () {
      // It ties every survey record on the title, and at 34 characters it
      // ties stewed for the shortest description in the pool, so without
      // the penalty the portions key would put it second — stewed's 8 to
      // its none. The penalty is what puts it last instead: 0.85 against
      // 1.0, and the tie-break is never reached for it.
      final ranked = resolve(
        'chicken breast',
        backend: BackendSiblingFixtures.chickenBreast,
      );

      expect(
        names(ranked).indexOf('Chicken breast, roll, oven-roasted'),
        greaterThan(0),
      );
      expect(
        scoreMealForResolution(
          BackendSiblingFixtures.chickenBreastRollSrLegacy,
          'chicken breast',
        ),
        closeTo(0.85, 1e-9),
      );
      expect(names(ranked).last, 'Chicken breast, roll, oven-roasted');
    });

    test('rankForResolution is stable when every key ties', () {
      // Two real survey records that tie on all three keys for "rice":
      // titled "Bread" and "Chips" with `rice` behind each, so 0.667 each,
      // then eleven characters each and five deliverable portions each.
      // What is left is the order they came in. (Two records cannot
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

  group('a qualifier in the query picks the sibling that carries it', () {
    // The review's finding against the title-only revision: on a qualified
    // query every sibling tied on the title and the tie-break logged the
    // everyday form — `dried apple` → "Apple, raw" at 0.667, not flagged,
    // and dried apple is some four times the kcal of raw. The pools are
    // listed with the everyday form first, and it is the shortest
    // description and the most portioned, so that neither the input order
    // nor either tie-break key can be what picks the winner.
    test(
      'dried apple resolves to Apple, dried over the shorter, most-portioned raw',
      () {
        final ranked = resolve(
          'dried apple',
          backend: [
            BackendSiblingFixtures.appleRaw,
            BackendSiblingFixtures.appleDried,
            BackendSiblingFixtures.appleBaked,
          ],
        );

        expect(names(ranked).first, 'Apple, dried');
        expect(
          scoreMealForResolution(
            BackendSiblingFixtures.appleDried,
            'dried apple',
          ),
          1.0,
        );
        // The siblings keep the title-only score: the qualifier they carry is
        // not the one named, and costs them nothing either.
        expect(
          scoreMealForResolution(
            BackendSiblingFixtures.appleRaw,
            'dried apple',
          ),
          closeTo(0.667, 1e-3),
        );
        expect(
          scoreMealForResolution(
            BackendSiblingFixtures.appleBaked,
            'dried apple',
          ),
          closeTo(0.667, 1e-3),
        );
      },
    );

    test('rye bread resolves to Bread, rye by score, not by the tie-break', () {
      // Rye is the shorter description and wins `bread` on that key too,
      // so the order alone cannot tell the two apart; the scores can. On
      // `rye bread` the named qualifier puts rye at 1.0 and white at
      // 0.667, and the tie-break is never consulted.
      final ranked = resolve(
        'rye bread',
        backend: [
          BackendSiblingFixtures.breadWhite,
          BackendSiblingFixtures.breadRye,
        ],
      );

      expect(names(ranked), ['Bread, rye', 'Bread, white']);
      expect(
        scoreMealForResolution(BackendSiblingFixtures.breadRye, 'rye bread'),
        1.0,
      );
      expect(
        scoreMealForResolution(BackendSiblingFixtures.breadWhite, 'rye bread'),
        closeTo(0.667, 1e-3),
      );
    });

    test('egg yolk resolves to the yolk record, not the boiled egg', () {
      final ranked = resolve(
        'egg yolk',
        backend: [
          BackendSiblingFixtures.eggWholeBoiledOrPoached,
          BackendSiblingFixtures.eggWholeRaw,
          BackendSiblingFixtures.eggCreamed,
          BackendSiblingFixtures.eggYolkOnlyRaw,
        ],
      );

      expect(names(ranked).first, 'Egg, yolk only, raw');
      expect(
        scoreMealForResolution(
          BackendSiblingFixtures.eggYolkOnlyRaw,
          'egg yolk',
        ),
        1.0,
      );
      expect(
        scoreMealForResolution(
          BackendSiblingFixtures.eggWholeBoiledOrPoached,
          'egg yolk',
        ),
        closeTo(0.667, 1e-3),
      );
    });

    test('the qualifier is matched as softly as the title: egg yolks', () {
      // `yolks` agrees with `yolk` four letters in, the way `eggs` agrees
      // with `Egg`, so the yolk record is still the one picked and still
      // clears the floor by a distance.
      final ranked = resolve(
        'egg yolks',
        backend: [
          BackendSiblingFixtures.eggWholeBoiledOrPoached,
          BackendSiblingFixtures.eggWholeRaw,
          BackendSiblingFixtures.eggCreamed,
          BackendSiblingFixtures.eggYolkOnlyRaw,
        ],
      );

      expect(names(ranked).first, 'Egg, yolk only, raw');
      expect(
        scoreMealForResolution(
          BackendSiblingFixtures.eggYolkOnlyRaw,
          'egg yolks',
        ),
        closeTo(0.9, 1e-9),
      );
    });

    test('baked banana, whole milk and baked chicken breast', () {
      expect(
        names(
          resolve(
            'baked banana',
            backend: [
              BackendSiblingFixtures.bananaRaw,
              BackendSiblingFixtures.bananaBaked,
            ],
          ),
        ).first,
        'Banana, baked',
      );
      expect(
        names(
          resolve(
            'whole milk',
            backend: [
              BackendSiblingFixtures.milkNfs,
              BackendSiblingFixtures.milkWhole,
              BackendSiblingFixtures.milkHuman,
            ],
          ),
        ).first,
        'Milk, whole',
      );
      // The baked record is the longest description in the family, 68
      // characters, and loses `chicken breast` to stewed's 34 on the
      // length key; on `baked chicken breast` the named qualifier puts it
      // at 1.0 and the tie-break is never consulted.
      expect(
        names(
          resolve(
            'baked chicken breast',
            backend: [
              BackendSiblingFixtures.chickenBreastRotisserie,
              BackendSiblingFixtures.chickenBreastNsCookingMethod,
              BackendSiblingFixtures.chickenBreastBaked,
              BackendSiblingFixtures.chickenBreastRollSrLegacy,
            ],
          ),
        ).first,
        'Chicken breast, baked, broiled, or roasted, skin not eaten, from raw',
      );
    });

    test('a qualifier alone finds the record that carries it', () {
      // `yolk` names no family. The yolk record scores it as the OFF
      // product "Egg yolk" would, 0.667, and its siblings nothing at all.
      final ranked = resolve('yolk', backend: BackendSiblingFixtures.egg);

      expect(names(ranked).first, 'Egg, yolk only, raw');
      expect(
        scoreMealForResolution(BackendSiblingFixtures.eggYolkOnlyRaw, 'yolk'),
        closeTo(0.667, 1e-3),
      );
      expect(
        scoreMealForResolution(BackendSiblingFixtures.eggWholeRaw, 'yolk'),
        0.0,
      );
    });

    test('the Food tab puts the named sibling first by score too', () {
      // The shared ranker is a stable sort, so on the title alone the two
      // tied at 0.667 and the list order — the cache's, on a warm cache —
      // decided. Now "Milk, whole" is scored as "Milk whole", the 0.9 cap,
      // and goes first from either input order.
      final nfs = BackendSiblingFixtures.milkNfs;
      final whole = BackendSiblingFixtures.milkWhole;

      expect(scoreMealRelevance(whole, 'whole milk'), closeTo(0.9, 1e-9));
      expect(scoreMealRelevance(nfs, 'whole milk'), closeTo(0.667, 1e-3));
      expect(
        names(rankMealsByRelevance([nfs, whole], 'whole milk')).first,
        'Milk, whole',
      );
      // And on the bare title the two still tie at 1.0, as pinned above.
      expect(scoreMealRelevance(whole, 'milk'), 1.0);
      expect(scoreMealRelevance(nfs, 'milk'), 1.0);
    });
  });

  group('the whole Potato family, handed to the cut on its own (#1170)', () {
    // The data source cuts what the backend sends to twenty before any
    // entity exists, and the resolver picks among those twenty. Scored on
    // the whole description, the record the resolver would pick among a
    // family was cut before it was scored; scored on the title with the
    // same tie-break, the shortest-described of the family is inside the
    // twenty. The real 106-record "Potato" family, through the cut and
    // then the resolver's own path, each record carrying the portions the
    // backend delivers for it.
    //
    // This is the family handed to the cut alone, which the app never does
    // for `potato`: the backend's own hundred hold none of the family, and
    // the app's answer is a beef stew — pinned in the real-pool group
    // below. What this group pins is what the client's cut does with a
    // family when one reaches it.
    MealEntity fresh(SpFoodDTO row) =>
        BackendPoolFixtures.fresh(row, BackendPoolFixtures.potatoPortions);

    test('potato resolves to Potato, NFS out of the family\'s twenty', () {
      // The measurement the revised tie-break rests on: "Potato, NFS"
      // carries 4 deliverable portions and "Potato, french fries, fast
      // food" 12, so most-portions-first logged the fries. The shortest
      // description is the generic record.
      final survivors = rankAndTruncateFoodsByName(
        BackendPoolFixtures.potato,
        'potato',
      );
      final page = [for (final row in survivors) fresh(row)];

      final ranked = resolve('potato', backend: page);

      expect(ranked, hasLength(20));
      expect(names(ranked).first, 'Potato, NFS');
      expect(ranked.first.code, '${BackendPoolFixtures.potatoNfs}');
      expect(ranked.first.portions, hasLength(4));
      expect(scoreMealForResolution(ranked.first, 'potato'), 1.0);
    });

    test('and to the same record out of the whole family', () {
      // The cut kept what the resolver would have picked from all 106,
      // in either order — and not the most-portioned record, which is a
      // fries record at 12 and scores the same 1.0.
      final family = [for (final row in BackendPoolFixtures.potato) fresh(row)];
      final fries = family.singleWhere(
        (m) => m.code == '${BackendPoolFixtures.potatoFrenchFriesFastFood}',
      );

      expect(fries.name, 'Potato, french fries, fast food');
      expect(fries.portions, hasLength(12));
      expect(scoreMealForResolution(fries, 'potato'), 1.0);
      expect(names(resolve('potato', backend: family)).first, 'Potato, NFS');
      expect(
        names(resolve('potato', backend: family.reversed.toList())).first,
        'Potato, NFS',
      );
    });

    test('the portionless record is penalised, whatever its length', () {
      // "Potato, cooked, as ingredient" is 29 characters, shorter than
      // most of the family; at 0.85 the length key never sees it.
      final family = [for (final row in BackendPoolFixtures.potato) fresh(row)];
      final ingredient = family.singleWhere(
        (m) => m.code == '${BackendPoolFixtures.potatoCookedAsIngredient}',
      );

      expect(ingredient.portions, isEmpty);
      expect(scoreMealForResolution(ingredient, 'potato'), closeTo(0.85, 1e-9));
      expect(names(resolve('potato', backend: family)).last, ingredient.name);
    });

    test('french fries resolves to Potato, french fries, NFS', () {
      // The sixteen fries records score 0.8 — the named `french fries`
      // with the title — and the shortest of them is the plain one, over
      // the fast-food record's 12 portions.
      final survivors = rankAndTruncateFoodsByName(
        BackendPoolFixtures.potato,
        'french fries',
      );
      final page = [for (final row in survivors) fresh(row)];

      final ranked = resolve('french fries', backend: page);

      expect(names(ranked).first, 'Potato, french fries, NFS');
      expect(
        scoreMealForResolution(ranked.first, 'french fries'),
        closeTo(0.8, 1e-9),
      );
      expect(
        names(ranked).take(16),
        everyElement(startsWith('Potato, french fries')),
      );
    });
  });

  group('the pools the app is handed (#1170 review)', () {
    // `search_food_summary(term, null, 100)` as the backend answered it,
    // through the cut and then the resolver's own path, each record with
    // the portions the backend delivers for it. The backend's hundred are
    // the first hundred matches by deliverable portion, then id: a cut
    // made before any client code runs, which no client-side rule can
    // reach past. Measured over the eighteen families the tie-break
    // decision listed, sixteen resolve on their real pool as listed
    // (egg -> creamed, milk, apple, banana, orange juice, cheese, beef,
    // pasta, coffee -> Latte, tea -> ginger, pork, turkey, soup, crackers,
    // muffin, pretzels); potato and bread do not, and these pin what they
    // do instead.
    test('potato resolves to a beef stew at 0.5: the backend\'s cut', () {
      // 712 rows match `potato`, and the hundred lowest-id ones with a
      // portion are all dishes; "Potato, NFS" is rank 128, the family 128
      // to 488. The client's cut cannot keep what it was never sent. What
      // survives is scored as the shared ranker scores: no title is
      // "Potato", no qualifier is the exact token `potato` (the dishes
      // carry `potatoes`), so ten rows whose title contains the word take
      // 0.2 and the rest tie at nothing, shortest first. The resolver then
      // reads `potatoes` by prefix as a named qualifier and puts the
      // stew's "Stewed" + `potatoes` at 0.5 — above the 0.45 floor, so it
      // is logged as settled, not flagged. That is the app's answer for
      // `potato` today, and it is the backend's cut, not this branch's,
      // that makes it.
      final survivors = rankAndTruncateFoodsByName(
        BackendPoolFixtures.potatoSearch,
        'potato',
      );
      final page = [
        for (final row in survivors)
          BackendPoolFixtures.fresh(
            row,
            BackendPoolFixtures.potatoSearchPortions,
          ),
      ];

      final ranked = resolve('potato', backend: page);

      expect(BackendPoolFixtures.potatoSearch, hasLength(100));
      expect(
        BackendPoolFixtures.potatoSearch.map((r) => r.shortTitle),
        isNot(contains('Potato')),
      );
      expect(
        BackendPoolFixtures.potatoSearch.map((r) => r.foodId),
        isNot(contains(BackendPoolFixtures.potatoNfs)),
      );
      expect(ranked, hasLength(20));
      expect(
        names(ranked).first,
        'Stewed, seasoned, ground beef with potatoes, Mexican style',
      );
      expect(
        ranked.first.code,
        '${BackendPoolFixtures.stewedBeefWithPotatoes}',
      );
      expect(
        scoreMealForResolution(ranked.first, 'potato'),
        closeTo(0.5, 1e-9),
      );
      expect(
        scoreMealForResolution(ranked.first, 'potato'),
        greaterThanOrEqualTo(kResolutionConfidenceFloor),
      );
      expect(ranked.map((m) => m.scoringName), isNot(contains('Potato')));
    });

    test('bread resolves to Bread, pita: the known miss', () {
      // 540 rows match `bread`; thirty-one of the hundred are titled
      // "Bread" and tie at 1.0, and the cut keeps the twenty shortest of
      // them. "Bread, rye" is rank 157 and never arrives, so the miss
      // c78b5a38 pinned on the two-row fixture — rye over white — is not
      // the one the app makes. Pita and naan are eleven characters each,
      // the shortest inside the hundred, and the portions key settles it:
      // pita's 5 to naan's 3. White, the everyday form, is twelve and
      // carries 7.
      final survivors = rankAndTruncateFoodsByName(
        BackendPoolFixtures.breadSearch,
        'bread',
      );
      final page = [
        for (final row in survivors)
          BackendPoolFixtures.fresh(
            row,
            BackendPoolFixtures.breadSearchPortions,
          ),
      ];

      final ranked = resolve('bread', backend: page);

      expect(
        BackendPoolFixtures.breadSearch.map((r) => r.foodId),
        isNot(contains(BackendPoolFixtures.breadRye)),
      );
      expect(ranked, hasLength(20));
      expect(names(ranked).take(3), [
        'Bread, pita',
        'Bread, naan',
        'Bread, white',
      ]);
      expect(ranked.first.code, '${BackendPoolFixtures.breadPita}');
      expect(ranked.first.portions, hasLength(5));
      expect(ranked[1].portions, hasLength(3));
      expect(ranked[2].portions, hasLength(7));
      expect(scoreMealForResolution(ranked.first, 'bread'), 1.0);
      expect(names(ranked), everyElement(startsWith('Bread, ')));
    });
  });

  group(
    'where the cut and the resolver read a pool differently (#1170 review)',
    () {
      // c78b5a38 said the twenty survivors and the resolver apply one rule,
      // so the resolver's pick is inside the twenty by construction. They
      // share the title derivation and the tie-break, not the rule: the cut
      // names a qualifier by exact token (`textRelevanceScore`, the shared
      // ranker's reading) where the resolver names it by soft prefix
      // (`_namedQualifiers`), and the cut runs before any portion is fetched
      // where the resolver takes 0.15 off a record with none. Each is a way
      // for the record the resolver would pick from the whole pool to be cut
      // before it is scored, and each is pinned here as it stands.
      MealEntity fresh(SpFoodDTO row) =>
          BackendPoolFixtures.fresh(row, BackendPoolFixtures.potatoPortions);

      test('a qualifier the query names only by prefix: cheesy potato', () {
        // Over the whole family the resolver reads `cheesy` as naming
        // `cheese` (0.833 by prefix) and picks "Potato, french fries, with
        // cheese" at 0.917. The cut has no `cheesy` token to intersect, so
        // every row scores 0.667 on the title and the twenty shortest
        // survive, none longer than 30 characters; the 33-character record
        // is cut, and the resolver logs "Potato, NFS" at 0.667 from what is
        // left.
        const query = 'cheesy potato';
        final family = [
          for (final row in BackendPoolFixtures.potato) fresh(row),
        ];
        final fromFamily = resolve(query, backend: family).first;
        final survivors = rankAndTruncateFoodsByName(
          BackendPoolFixtures.potato,
          query,
        );
        final fromPage = resolve(
          query,
          backend: [for (final row in survivors) fresh(row)],
        ).first;

        expect(fromFamily.name, 'Potato, french fries, with cheese');
        expect(scoreMealForResolution(fromFamily, query), closeTo(0.917, 1e-3));
        expect(
          survivors.map((r) => '${r.foodId}'),
          isNot(contains(fromFamily.code)),
        );
        expect(
          survivors.map((r) => r.name!.length),
          everyElement(lessThanOrEqualTo(30)),
        );
        expect(fromPage.name, 'Potato, NFS');
        expect(scoreMealForResolution(fromPage, query), closeTo(0.667, 1e-3));
      });

      test('a family whose shortest members carry no portions', () {
        // Twenty-five portionless SR Legacy-style rows and one survey record
        // with nine portions, all titled "Chicken breast". Over the whole
        // pool the penalty leaves the survey record alone at 1.0. The cut
        // knows no portions, ties the twenty-six on the title and keeps the
        // twenty shortest — the portionless rows — and the resolver logs one
        // of them at 0.85.
        const query = 'chicken breast';
        SpFoodDTO row(int id, String name, String source) => SpFoodDTO(
          foodId: id,
          source: source,
          sourceCode: '$id',
          name: name,
        );
        final rows = [
          for (var i = 0; i < 25; i++)
            row(
              i,
              'Chicken breast, roll ${i.toString().padLeft(2, '0')}',
              'fdc_sr_legacy',
            ),
          row(99, 'Chicken breast, baked or broiled, skin eaten', 'fdc_survey'),
        ];
        final portions = {
          for (final r in rows) r.foodId!: r.foodId == 99 ? 9 : 0,
        };
        MealEntity entity(SpFoodDTO r) =>
            BackendPoolFixtures.fresh(r, portions);

        final fromPool = resolve(
          query,
          backend: [for (final r in rows) entity(r)],
        ).first;
        final survivors = rankAndTruncateFoodsByName(rows, query);
        final fromPage = resolve(
          query,
          backend: [for (final r in survivors) entity(r)],
        ).first;

        expect(fromPool.name, 'Chicken breast, baked or broiled, skin eaten');
        expect(scoreMealForResolution(fromPool, query), 1.0);
        expect(survivors.map((r) => r.foodId), isNot(contains(99)));
        expect(fromPage.name, 'Chicken breast, roll 00');
        expect(scoreMealForResolution(fromPage, query), closeTo(0.85, 1e-9));
      });
    },
  );
}
