import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
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
/// are its own cut, made before any client code runs. Since Backend#10
/// (applied 2026-09-13) it orders them by deliverable portion, then title
/// equal to the term, then length, so a family the query names arrives
/// whole and shortest-first; the order before it — portion, then id —
/// handed `potato` a hundred beef stews with the family at ranks 128 to
/// 488, and `bread` a hundred without "Bread, rye", which was rank 157.
/// The family fixtures here are real rows but not that hundred, so the
/// groups on them pin the tie-break; the last groups pin the app's answer
/// on `BackendPoolFixtures`' real pools, through the data source's cut
/// and then the resolver — and that the survivors and the resolver apply
/// one rule, so the resolver's pick from the whole pool is inside the
/// twenty, up to the one thing the cut cannot see (its portions; see
/// `rankAndTruncateFoodsByName`).
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
      // On the pool the app is handed rye leads the hundred and is the
      // app's answer too; see the real-pool group below.
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
      // (On the pool the app is handed the same key lands on "Rice, fried,
      // NFS", 16 — the known miss pinned in the real-pool group below.)
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
      // this is the app's answer, pinned over the real pool in every input
      // order below; c78b5a38's fixture left it out and pinned rotisserie.
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

  group('the pools the app is handed (#1170)', () {
    // `search_food_summary(term, null, 100)` as the backend answered it
    // after Backend#10, through the data source's cut and then the
    // resolver's own path, each record with the portions the backend
    // delivers for it. The backend leads with the rows that carry a
    // portion, among them the family the term names by its title,
    // shortest first; the cut keeps the twenty the resolver would rank
    // first; the resolver picks among those. Each family's answer is
    // asserted twice: from the page the cut hands on, and from the whole
    // hundred with no cut at all — the same record, or the cut lost what
    // the resolver would have picked.
    ({MealEntity fromPage, MealEntity fromPool, List<SpFoodDTO> survivors})
    pick(String query, List<SpFoodDTO> pool, Map<int, int> portions) {
      final survivors = rankAndTruncateFoodsByName(pool, query);
      return (
        fromPage: resolve(
          query,
          backend: BackendPoolFixtures.freshAll(survivors, portions),
        ).first,
        fromPool: resolve(
          query,
          backend: BackendPoolFixtures.freshAll(pool, portions),
        ).first,
        survivors: survivors,
      );
    }

    void expectPick(
      String query,
      List<SpFoodDTO> pool,
      Map<int, int> portions, {
      required String name,
      required int id,
      double score = 1.0,
    }) {
      final picked = pick(query, pool, portions);

      expect(picked.fromPage.name, name, reason: query);
      expect(picked.fromPage.code, '$id', reason: query);
      expect(picked.fromPool.code, '$id', reason: '$query, whole pool');
      expect(
        picked.survivors.map((r) => r.foodId),
        contains(id),
        reason: '$query: the pick is inside the twenty',
      );
      expect(
        scoreMealForResolution(picked.fromPage, query),
        closeTo(score, 1e-3),
        reason: query,
      );
      expect(
        scoreMealForResolution(picked.fromPage, query),
        greaterThanOrEqualTo(kResolutionConfidenceFloor),
        reason: '$query is settled, not flagged',
      );
    }

    test('potato resolves to Potato, NFS', () {
      // The hundred are a hundred rows titled "Potato" and every one scores
      // 1.0, so the length key decides: "Potato, NFS" at eleven characters
      // — 4 deliverable portions; the fast-food fries carry 12, which is
      // what made most-portions-first the wrong key. The order before
      // Backend#10 held no row titled "Potato" at all, and the app logged
      // "Stewed, seasoned, ground beef with potatoes, Mexican style".
      expect(
        BackendPoolFixtures.potato.map((r) => r.shortTitle),
        everyElement('Potato'),
      );
      expectPick(
        'potato',
        BackendPoolFixtures.potato,
        BackendPoolFixtures.potatoPortions,
        name: 'Potato, NFS',
        id: BackendPoolFixtures.potatoNfs,
      );
    });

    test('bread resolves to Bread, rye', () {
      // The miss c78b5a38 pinned on two rows is the app's answer: the
      // hundred are all titled "Bread", rye leads them at ten characters,
      // and white, the everyday form, is twelve. Rye, soy and nut are ten
      // each; rye carries 5 portions to nut's 2 and ties soy's 5, so the
      // last key — the backend's order, which is id order — is what puts
      // rye ahead of soy. Before Backend#10 rye was rank 157 and never
      // arrived, and the app landed on "Bread, pita".
      expectPick(
        'bread',
        BackendPoolFixtures.bread,
        BackendPoolFixtures.breadPortions,
        name: 'Bread, rye',
        id: BackendPoolFixtures.breadRye,
      );
      final ranked = resolve(
        'bread',
        backend: BackendPoolFixtures.freshAll(
          rankAndTruncateFoodsByName(BackendPoolFixtures.bread, 'bread'),
          BackendPoolFixtures.breadPortions,
        ),
      );
      expect(names(ranked).take(4), [
        'Bread, rye',
        'Bread, soy',
        'Bread, nut',
        'Bread, pita',
      ]);
      expect(ranked[0].portions, hasLength(5));
      expect(ranked[1].portions, hasLength(5));
      expect(ranked[2].portions, hasLength(2));
    });

    test(
      'chicken breast resolves to the stewed record in every input order',
      () {
        // Thirty of the 98 rows carry a portion and 38 are titled "Chicken
        // breast". The cut keeps the BLS "Chicken breast, without skin,
        // raw" first — 33 characters, no portion, which the cut cannot see
        // — and stewed's 34 second, tied on length with the SR Legacy roll;
        // the penalty then drops both portionless records to 0.85 and
        // stewed is logged. Rotating the pool through the cut moves the
        // roll above and below stewed and changes nothing.
        final pool = BackendPoolFixtures.chickenBreast;
        final portions = BackendPoolFixtures.chickenBreastPortions;
        final winners = <String>{};
        for (var shift = 0; shift < pool.length; shift++) {
          final rotated = [...pool.skip(shift), ...pool.take(shift)];
          for (final input in [rotated, rotated.reversed.toList()]) {
            final picked = pick('chicken breast', input, portions);
            winners.add(picked.fromPage.name!);
            winners.add(picked.fromPool.name!);
          }
        }

        expect(winners, {'Chicken breast, stewed, skin eaten'});
        final survivors = rankAndTruncateFoodsByName(pool, 'chicken breast');
        expect(
          survivors.first.foodId,
          BackendPoolFixtures.chickenBreastWithoutSkinRawBls,
        );
        expect(survivors[1].foodId, BackendPoolFixtures.chickenBreastStewed);
        expect(
          survivors[2].foodId,
          BackendPoolFixtures.chickenBreastRollSrLegacy,
        );
        expectPick(
          'chicken breast',
          pool,
          portions,
          name: 'Chicken breast, stewed, skin eaten',
          id: BackendPoolFixtures.chickenBreastStewed,
        );
      },
    );

    test('egg resolves to Egg, creamed: the known miss', () {
      // Twenty-seven of the hundred are titled "Egg" and lead the pool;
      // creamed is twelve characters to fifteen for "Egg, whole, raw".
      expectPick(
        'egg',
        BackendPoolFixtures.egg,
        BackendPoolFixtures.eggPortions,
        name: 'Egg, creamed',
        id: BackendPoolFixtures.eggCreamed,
      );
    });

    test('eggs resolves to the same record, above the floor', () {
      // The backend answers `eggs` with a different hundred: the full-text
      // match stems it to `egg`, but no title equals `eggs`, so the
      // title-first key does nothing and the shortest matches of any title
      // arrive — "Egg burrito" and "Taquito, egg" among them. Every "Egg"
      // scores 0.75 on the soft agreement (`eggs` → `egg`), the burrito
      // and the taquito 0.5, and creamed is the shortest at 0.75.
      expect(
        BackendPoolFixtures.eggs.map((r) => r.shortTitle),
        isNot(contains('Eggs')),
      );
      expectPick(
        'eggs',
        BackendPoolFixtures.eggs,
        BackendPoolFixtures.eggsPortions,
        name: 'Egg, creamed',
        id: BackendPoolFixtures.eggCreamed,
        score: 0.75,
      );
    });

    test('milk resolves to Milk, NFS', () {
      expectPick(
        'milk',
        BackendPoolFixtures.milk,
        BackendPoolFixtures.milkPortions,
        name: 'Milk, NFS',
        id: BackendPoolFixtures.milkNfs,
      );
    });

    test('apple resolves to Apple, raw', () {
      // Twenty of the hundred carry a portion, four of them titled
      // "Apple"; raw is ten characters. The BLS "Apple raw" is nine, but
      // has no comma, so its title is the whole name and scores 0.667.
      expectPick(
        'apple',
        BackendPoolFixtures.apple,
        BackendPoolFixtures.applePortions,
        name: 'Apple, raw',
        id: BackendPoolFixtures.appleRaw,
      );
    });

    test('orange juice resolves to the survey record over BLS', () {
      // Nine of the 45 rows carry a portion. The BLS "Orange juice" is the
      // exact title at twelve characters and the cut, which knows no
      // portions, keeps it first; the resolver takes 0.15 off it and the
      // survey's "Orange juice, 100%, NFS" — 1.0, five portions — is
      // logged.
      final picked = pick(
        'orange juice',
        BackendPoolFixtures.orangeJuice,
        BackendPoolFixtures.orangeJuicePortions,
      );

      expect(picked.survivors.first.foodId, BackendPoolFixtures.orangeJuiceBls);
      expectPick(
        'orange juice',
        BackendPoolFixtures.orangeJuice,
        BackendPoolFixtures.orangeJuicePortions,
        name: 'Orange juice, 100%, NFS',
        id: BackendPoolFixtures.orangeJuice100Nfs,
      );
      final ranked = resolve(
        'orange juice',
        backend: BackendPoolFixtures.freshAll(
          picked.survivors,
          BackendPoolFixtures.orangeJuicePortions,
        ),
      );
      final bls = ranked.singleWhere(
        (m) => m.code == '${BackendPoolFixtures.orangeJuiceBls}',
      );
      expect(scoreMealForResolution(bls, 'orange juice'), closeTo(0.85, 1e-9));
      expect(ranked.indexOf(bls), greaterThan(0));
    });

    test('rice resolves to Rice, fried, NFS: the known miss', () {
      // The hundred are all titled "Rice" and tie at 1.0; "Rice, fried,
      // NFS" is sixteen characters to "Rice, cooked, NFS"'s seventeen, so
      // the length key lands on a dish, as it lands on creamed egg. Pinned
      // as it is: the cooked record is second, one tap away on the review
      // screen, and the rule that would pick it — most portions first —
      // picked the french fries over the potato in the large families.
      expectPick(
        'rice',
        BackendPoolFixtures.rice,
        BackendPoolFixtures.ricePortions,
        name: 'Rice, fried, NFS',
        id: BackendPoolFixtures.riceFriedNfs,
      );
      final ranked = resolve(
        'rice',
        backend: BackendPoolFixtures.freshAll(
          rankAndTruncateFoodsByName(BackendPoolFixtures.rice, 'rice'),
          BackendPoolFixtures.ricePortions,
        ),
      );
      expect(names(ranked).take(2), ['Rice, fried, NFS', 'Rice, cooked, NFS']);
      expect(ranked[1].code, '${BackendPoolFixtures.riceCookedNfs}');
    });

    test('carrots resolves to Carrots, raw', () {
      expectPick(
        'carrots',
        BackendPoolFixtures.carrots,
        BackendPoolFixtures.carrotsPortions,
        name: 'Carrots, raw',
        id: BackendPoolFixtures.carrotsRaw,
      );
    });

    test('a qualifier in the query picks the sibling that carries it', () {
      // The named qualifier puts one record above the family and the
      // tie-break is never consulted — on the real pools, through the cut.
      expectPick(
        'dried apple',
        BackendPoolFixtures.apple,
        BackendPoolFixtures.applePortions,
        name: 'Apple, dried',
        id: BackendPoolFixtures.appleDried,
      );
      expectPick(
        'whole milk',
        BackendPoolFixtures.milk,
        BackendPoolFixtures.milkPortions,
        name: 'Milk, whole',
        id: BackendPoolFixtures.milkWhole,
      );
      expectPick(
        'egg yolk',
        BackendPoolFixtures.egg,
        BackendPoolFixtures.eggPortions,
        name: 'Egg, yolk only, raw',
        id: BackendPoolFixtures.eggYolkOnlyRaw,
      );
      expectPick(
        'rye bread',
        BackendPoolFixtures.bread,
        BackendPoolFixtures.breadPortions,
        name: 'Bread, rye',
        id: BackendPoolFixtures.breadRye,
      );
      expectPick(
        'french fries',
        BackendPoolFixtures.potato,
        BackendPoolFixtures.potatoPortions,
        name: 'Potato, french fries, NFS',
        id: BackendPoolFixtures.potatoFrenchFriesNfs,
        score: 0.8,
      );
    });
  });

  group('the German pools through the translation cut (#1170)', () {
    // `search_food_translation(term, 'de', 100)` as the backend answered
    // it, through `rankAndTruncateTranslationRows` and then the resolver,
    // each entity carrying the translated description as its name — which
    // is what `SpFoodDataSource._searchByTranslation` puts on the DTO —
    // and the portions the backend delivers for it. Every Milch row is a
    // machine translation and loses 0.03; so is every Kartoffel row that
    // survives.
    SpFoodDTO translated(Map<String, dynamic> row) {
      final dto = SpFoodDTO(
        foodId: row[SPConst.translationFoodId] as int,
        source: 'fdc_survey',
        sourceCode: '${row[SPConst.translationFoodId]}',
        name: row[SPConst.translationDescription] as String,
      );
      dto.localizedName = row[SPConst.translationDescription] as String;
      dto.localizedNameIsMachineTranslated =
          row[SPConst.translationSource] == SPConst.translationSourceMachine;
      return dto;
    }

    List<MealEntity> page(
      String query,
      List<Map<String, dynamic>> pool,
      Map<int, int> portions,
    ) => BackendPoolFixtures.freshAll([
      for (final row in rankAndTruncateTranslationRows(pool, query))
        translated(row),
    ], portions);

    test('Milch resolves to Milch, NFS', () {
      final ranked = resolve(
        'Milch',
        backend: page(
          'Milch',
          BackendPoolFixtures.milch,
          BackendPoolFixtures.milchPortions,
        ),
      );

      expect(ranked.first.name, 'Milch, NFS');
      expect(ranked.first.code, '${BackendPoolFixtures.milchNfs}');
      expect(ranked.first.scoringName, 'Milch');
      expect(ranked.first.machineTranslatedName, isTrue);
      expect(
        scoreMealForResolution(ranked.first, 'Milch'),
        closeTo(0.97, 1e-9),
      );
    });

    test('Kartoffel resolves to Kartoffel, NFS', () {
      // The same record as `potato`, read in German.
      final ranked = resolve(
        'Kartoffel',
        backend: page(
          'Kartoffel',
          BackendPoolFixtures.kartoffel,
          BackendPoolFixtures.kartoffelPortions,
        ),
      );

      expect(ranked.first.name, 'Kartoffel, NFS');
      expect(ranked.first.code, '${BackendPoolFixtures.kartoffelNfs}');
      expect(BackendPoolFixtures.kartoffelNfs, BackendPoolFixtures.potatoNfs);
      expect(ranked.first.portions, hasLength(4));
    });
  });

  group('the cut and the resolver apply one rule (#1170)', () {
    // c78b5a38 said the twenty survivors and the resolver apply one rule,
    // so the resolver's pick is inside the twenty by construction; the
    // #1170 review found they shared the title derivation and the
    // tie-break but not the rule — the cut named a qualifier by the exact
    // token and the resolver by soft prefix — and the claim was withdrawn.
    // Both now score with `scoreText` and name with `namedQualifiers`
    // (soft_text_score.dart), so the claim is back, and the group above
    // asserts it on every real pool. What it still does not cover is the
    // one thing the cut cannot see: it runs before any portion is fetched,
    // where the resolver's penalty and its portions key read them. The
    // last tests pin that hole where it bites and where it does not.
    test('a qualifier named by inflection: cheesy potato', () {
      // `cheesy` agrees with `cheese` five letters in (0.833) and with no
      // title token at all, so the qualifier is named — at the cut as in
      // the resolver — and the thirteen rows carrying `cheese` score
      // 0.917 over the family's 0.667. The shortest of them, "Potato,
      // french fries, with cheese" at 33 characters, is kept first and
      // picked. With the cut naming by exact token there was no `cheesy`
      // to intersect, every row scored 0.667, the twenty shortest survived
      // — none longer than 30 — and the resolver logged "Potato, NFS".
      const query = 'cheesy potato';
      final pool = BackendPoolFixtures.potato;
      final portions = BackendPoolFixtures.potatoPortions;
      final survivors = rankAndTruncateFoodsByName(pool, query);
      final fromPage = resolve(
        query,
        backend: BackendPoolFixtures.freshAll(survivors, portions),
      ).first;
      final fromPool = resolve(
        query,
        backend: BackendPoolFixtures.freshAll(pool, portions),
      ).first;

      expect(fromPool.name, 'Potato, french fries, with cheese');
      expect(fromPage.code, fromPool.code);
      expect(
        survivors.first.foodId,
        BackendPoolFixtures.potatoFrenchFriesWithCheese,
      );
      expect(scoreMealForResolution(fromPage, query), closeTo(0.917, 1e-3));
      expect(survivors.where((r) => r.name!.contains('cheese')), hasLength(13));
      expect(
        survivors.take(13).map((r) => r.name!.contains('cheese')),
        everyElement(isTrue),
      );
      expect(
        scoreMealForResolution(
          BackendPoolFixtures.fresh(
            pool.singleWhere((r) => r.foodId == BackendPoolFixtures.potatoNfs),
            portions,
          ),
          query,
        ),
        closeTo(0.667, 1e-3),
      );
    });

    test('a qualifier named by inflection: fried potato', () {
      // `fried` agrees with `fries` four letters in (0.8) and with `fried`
      // exactly, so "Potato, french fries, from fresh, fried" carries two
      // named qualifiers and scores 0.96; the home fries, with `fries`
      // alone, 0.9; the rest of the family 0.667. The shortest of the two
      // records carrying `fried` is picked, at the cut as in the resolver.
      const query = 'fried potato';
      final pool = BackendPoolFixtures.potato;
      final portions = BackendPoolFixtures.potatoPortions;
      final survivors = rankAndTruncateFoodsByName(pool, query);
      final fromPage = resolve(
        query,
        backend: BackendPoolFixtures.freshAll(survivors, portions),
      ).first;
      final fromPool = resolve(
        query,
        backend: BackendPoolFixtures.freshAll(pool, portions),
      ).first;

      expect(fromPool.name, 'Potato, french fries, from fresh, fried');
      expect(fromPage.code, fromPool.code);
      expect(
        survivors.first.foodId,
        BackendPoolFixtures.potatoFrenchFriesFromFreshFried,
      );
      expect(scoreMealForResolution(fromPage, query), closeTo(0.96, 1e-3));
    });

    test('the one hole: a family whose shortest members carry no portions', () {
      // Twenty-five portionless SR Legacy-style rows and one survey record
      // with nine portions, all titled "Chicken breast". Over the whole
      // pool the penalty leaves the survey record alone at 1.0. The cut
      // knows no portions, ties the twenty-six on the title and keeps the
      // twenty shortest — the portionless rows — and the resolver logs one
      // of them at 0.85. On the pools the backend sends this needs fewer
      // than twenty portion-bearing rows in the pool, because the backend
      // leads with them, and twenty portionless rows that score as well
      // and are no longer than the pick; no real pool here has both.
      const query = 'chicken breast';
      SpFoodDTO row(int id, String name, String source) =>
          SpFoodDTO(foodId: id, source: source, sourceCode: '$id', name: name);
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
      MealEntity entity(SpFoodDTO r) => BackendPoolFixtures.fresh(r, portions);

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

    test(
      'where the hole does not bite: orange juice, nine portion-bearing rows',
      () {
        // The pool with the fewest portion-bearing rows here. Twenty rows
        // are titled "Orange juice" and only one portionless one — the
        // BLS record, twelve characters — is shorter than the survey's
        // "Orange juice, 100%, NFS", so the survey record is second at the
        // cut and first in the resolver. Nineteen more portionless rows
        // no longer than 23 characters would have cut it.
        final pool = BackendPoolFixtures.orangeJuice;
        final portions = BackendPoolFixtures.orangeJuicePortions;
        final survivors = rankAndTruncateFoodsByName(pool, 'orange juice');

        expect(pool.where((r) => portions[r.foodId]! > 0), hasLength(9));
        expect(survivors[1].foodId, BackendPoolFixtures.orangeJuice100Nfs);
        expect(
          survivors.where(
            (r) => portions[r.foodId] == 0 && r.name!.length <= 23,
          ),
          hasLength(1),
        );
      },
    );
  });
}
