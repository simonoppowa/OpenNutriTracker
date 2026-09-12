import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';

MealEntity _meal({
  required String name,
  String? code,
  String? brands,
  MealSourceEntity source = MealSourceEntity.off,
  bool detailed = false,
  bool machineTranslatedName = false,
}) {
  return MealEntity(
    code: code ?? name,
    name: name,
    brands: brands,
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    nutriments: MealNutrimentsEntity.empty(),
    source: source,
    detailed: detailed,
    machineTranslatedName: machineTranslatedName,
  );
}

void main() {
  group('scoreMealRelevance', () {
    test('scores an exact name match at the maximum', () {
      final meal = _meal(name: 'Milk');
      expect(scoreMealRelevance(meal, 'Milk'), 1.0);
    });

    test('is case- and whitespace-insensitive for exact matches', () {
      final meal = _meal(name: '  Milk  ');
      expect(scoreMealRelevance(meal, 'milk'), 1.0);
    });

    test('scores a prefix match higher than an unrelated match', () {
      final prefixMatch = _meal(name: 'Milk Chocolate Bar');
      final unrelated = _meal(name: 'Chicken Breast');
      expect(scoreMealRelevance(prefixMatch, 'milk'), greaterThan(scoreMealRelevance(unrelated, 'milk')));
    });

    test('scores a closer name match higher than a looser one', () {
      final close = _meal(name: 'Whole Milk');
      final loose = _meal(name: 'Milk Chocolate Hazelnut Spread');
      expect(scoreMealRelevance(close, 'milk'), greaterThan(scoreMealRelevance(loose, 'milk')));
    });

    // Regression for a real search hit on-device: a short two-word name
    // ("Milk & hazelnut") racks up enough dice/contains/prefix bonus to
    // saturate at the same ceiling as a true exact match ("Milk"), which
    // let it win on the OFF popularity tie-break instead of losing outright.
    test('an exact match always outscores a strong-but-not-exact match', () {
      final exact = _meal(name: 'Milk');
      final strongPartial = _meal(name: 'Milk & Hazelnut');
      expect(scoreMealRelevance(exact, 'milk'), greaterThan(scoreMealRelevance(strongPartial, 'milk')));
    });

    test('an exact match outscores a strong partial even with the worst-case tie-breakers', () {
      final exactButTranslated = _meal(name: 'Milk', machineTranslatedName: true);
      final partialButDetailed = _meal(name: 'Milk & Hazelnut', detailed: true);
      expect(
        scoreMealRelevance(exactButTranslated, 'milk'),
        greaterThan(scoreMealRelevance(partialButDetailed, 'milk')),
      );
    });

    test('returns 0 for a completely unrelated name', () {
      final meal = _meal(name: 'Chicken Breast');
      expect(scoreMealRelevance(meal, 'milk'), 0.0);
    });

    test('returns 0 for an empty query', () {
      final meal = _meal(name: 'Milk');
      expect(scoreMealRelevance(meal, ''), 0.0);
    });

    test('returns 0 for a meal with no name and no brand', () {
      final meal = _meal(name: '');
      expect(scoreMealRelevance(meal, 'milk'), 0.0);
    });

    test('the token-overlap component is order-independent for multi-word queries', () {
      // Neither ordering of the query appears contiguously in the name (the
      // matching tokens are separated by other words), which isolates the
      // dice/token-overlap component from the substring/prefix bonuses —
      // those are deliberately order-sensitive, and from the exact-match
      // shortcut, which is a literal string comparison and so isn't
      // order-independent (e.g. "milk chocolate" and "chocolate milk" name
      // genuinely different foods; treating a reordered query as a full
      // exact match would be wrong).
      final meal = _meal(name: 'Chicken And Spicy Sauce Wrap');
      expect(scoreMealRelevance(meal, 'spicy chicken'), scoreMealRelevance(meal, 'chicken spicy'));
    });

    test('falls back to brand match, but weighted below a name match', () {
      final brandMatch = _meal(name: 'Chocolate Bar', brands: 'Nestle');
      final nameMatch = _meal(name: 'Nestle');
      expect(scoreMealRelevance(brandMatch, 'nestle'), greaterThan(0.0));
      expect(scoreMealRelevance(nameMatch, 'nestle'), greaterThan(scoreMealRelevance(brandMatch, 'nestle')));
    });

    test('nudges a detailed record above an otherwise-identical thin one', () {
      final detailed = _meal(name: 'Whole Milk', detailed: true);
      final thin = _meal(name: 'Whole Milk', detailed: false);
      expect(scoreMealRelevance(detailed, 'milk'), greaterThan(scoreMealRelevance(thin, 'milk')));
    });

    test('nudges a machine-translated name below an otherwise-identical original', () {
      final translated = _meal(name: 'Whole Milk', machineTranslatedName: true);
      final original = _meal(name: 'Whole Milk', machineTranslatedName: false);
      expect(scoreMealRelevance(translated, 'milk'), lessThan(scoreMealRelevance(original, 'milk')));
    });

    test('never returns a score outside [0, 1]', () {
      final meal = _meal(name: 'Milk', brands: 'Milk', detailed: true);
      final score = scoreMealRelevance(meal, 'milk');
      expect(score, inInclusiveRange(0.0, 1.0));
    });

    // #1164: a backend record shows its full description and is scored on
    // its title — the description up to its first comma — so "Egg, whole,
    // raw" scores on `egg` exactly as it did while "Egg" was its name.
    test('scores a backend record on its title, not its description', () {
      final titled = _meal(name: 'Egg, whole, raw', source: MealSourceEntity.fdc);
      final named = _meal(name: 'Egg', source: MealSourceEntity.fdc);
      // The same text as an OFF product name is scored whole.
      final byDescription = _meal(name: 'Egg, whole, raw', source: MealSourceEntity.off);

      expect(titled.scoringName, 'Egg');
      expect(scoreMealRelevance(titled, 'egg'), 1.0);
      expect(scoreMealRelevance(titled, 'egg'), scoreMealRelevance(named, 'egg'));
      expect(byDescription.scoringName, 'Egg, whole, raw');
      expect(scoreMealRelevance(byDescription, 'egg'), lessThan(1.0));
    });

    test('a meal that is not a backend record is scored on its name as before', () {
      final off = _meal(name: 'Egg noodles');

      expect(off.scoringName, 'Egg noodles');
      // dice 0.667 + contains 0.2 + prefix 0.15, capped at 0.9
      expect(scoreMealRelevance(off, 'egg'), closeTo(0.9, 1e-9));
    });

    // #1164 review: scored on the title alone, `whole milk` tied "Milk,
    // whole" and "Milk, NFS" at 0.667 and the list order decided. A
    // qualifier the query names joins the title; one it does not is never
    // read.
    test('scores a qualifier the query names with the title', () {
      final whole = _meal(name: 'Milk, whole', source: MealSourceEntity.fdc);
      final nfs = _meal(name: 'Milk, NFS', source: MealSourceEntity.fdc);

      expect(whole.scoringQualifiers, 'whole');
      // As "Milk whole": dice 1.0, no contains or prefix on the title, so
      // the 0.9 cap — the score an OFF product "Milk, whole" gets too.
      expect(scoreMealRelevance(whole, 'whole milk'), closeTo(0.9, 1e-9));
      expect(
        scoreMealRelevance(whole, 'whole milk'),
        scoreMealRelevance(_meal(name: 'Milk, whole'), 'whole milk'),
      );
      // The sibling is scored on its title: "Milk" against two tokens.
      expect(scoreMealRelevance(nfs, 'whole milk'), closeTo(2 / 3, 1e-9));
      // And on the bare title both are exact.
      expect(scoreMealRelevance(whole, 'milk'), 1.0);
      expect(scoreMealRelevance(nfs, 'milk'), 1.0);
    });

    test('the named qualifier is matched exactly, like every token here', () {
      // This ranker's Dice is over exact tokens — `eggs` scores nothing on
      // `Egg` — and the qualifier is held to the same rule.
      final yolk = _meal(name: 'Egg, yolk only, raw', source: MealSourceEntity.fdc);

      expect(scoreMealRelevance(yolk, 'egg yolk'), closeTo(0.9, 1e-9));
      expect(scoreMealRelevance(yolk, 'egg yolks'), closeTo(2 / 3, 1e-9));
    });
  });

  group('rankMealsByRelevance', () {
    test('sorts the most relevant meal first regardless of source order', () {
      final exact = _meal(name: 'Milk', source: MealSourceEntity.fdc);
      final loose = _meal(name: 'Milk Chocolate Spread', source: MealSourceEntity.off);
      final unrelated = _meal(name: 'Chicken Breast', source: MealSourceEntity.off);

      final ranked = rankMealsByRelevance([unrelated, loose, exact], 'milk');

      expect(ranked.map((m) => m.name), ['Milk', 'Milk Chocolate Spread', 'Chicken Breast']);
    });

    test('keeps the original relative order for equally-scored meals', () {
      final first = _meal(name: 'Milk', source: MealSourceEntity.off);
      final second = _meal(name: 'Milk', source: MealSourceEntity.fdc);

      final ranked = rankMealsByRelevance([first, second], 'milk');

      expect(ranked[0].source, MealSourceEntity.off);
      expect(ranked[1].source, MealSourceEntity.fdc);
    });

    test('does not mutate the input list', () {
      final unrelated = _meal(name: 'Chicken Breast');
      final exact = _meal(name: 'Milk');
      final input = [unrelated, exact];

      rankMealsByRelevance(input, 'milk');

      expect(input, [unrelated, exact]);
    });

    test('ranks a backend record by its title (#1164)', () {
      // "Egg noodles" scores the 0.9 cap on `egg` by name; the survey
      // record's description would score 0.85 (three tokens) and lose, but
      // its title is an exact match and it goes first.
      final noodles = _meal(name: 'Egg noodles', code: 'off');
      final wholeRaw = _meal(name: 'Egg, whole, raw', code: '2707152', source: MealSourceEntity.fdc);

      final ranked = rankMealsByRelevance([noodles, wholeRaw], 'egg');

      expect(ranked.map((m) => m.name), ['Egg, whole, raw', 'Egg noodles']);
    });

    test('ranks the sibling whose qualifier the query names first (#1164)', () {
      // Listed after its sibling, so that a tie — which the stable sort
      // would leave in this order — is told apart from a win by score.
      final nfs = _meal(name: 'Milk, NFS', code: '2705384', source: MealSourceEntity.fdc);
      final whole = _meal(name: 'Milk, whole', code: '2705385', source: MealSourceEntity.fdc);

      final ranked = rankMealsByRelevance([nfs, whole], 'whole milk');

      expect(ranked.map((m) => m.name), ['Milk, whole', 'Milk, NFS']);
    });
  });

  group('textRelevanceScore', () {
    test('scores an exact match at the maximum', () {
      expect(textRelevanceScore('Milk', 'Milk'), 1.0);
    });

    test('ranks a closer match above a looser one, same as scoreMealRelevance', () {
      expect(
        textRelevanceScore('Whole Milk', 'milk'),
        greaterThan(textRelevanceScore('Milk Chocolate Hazelnut Spread', 'milk')),
      );
    });

    test('returns 0 for an empty query', () {
      expect(textRelevanceScore('Milk', ''), 0.0);
    });

    test('returns 0 for null text', () {
      expect(textRelevanceScore(null, 'milk'), 0.0);
    });
  });

  group('mergeAndRankMeals', () {
    test('collapses a custom meal that independently surfaced in both source lists', () {
      final ownMilk = _meal(name: 'My Milk', source: MealSourceEntity.custom);

      final merged = mergeAndRankMeals([ownMilk], [ownMilk], 'milk');

      expect(merged, [ownMilk]);
    });

    test('collapses a recipe that independently surfaced in both source lists', () {
      final recipe = _meal(name: 'My Smoothie', source: MealSourceEntity.recipe);

      final merged = mergeAndRankMeals([recipe], [recipe], 'smoothie');

      expect(merged, [recipe]);
    });

    test('collapses the same OFF product surfaced under two barcodes', () {
      final firstBarcode = _meal(name: 'Whole Milk', code: '4000000000001');
      final secondBarcode = _meal(name: 'Whole Milk', code: '4000000000002');

      final merged = mergeAndRankMeals([firstBarcode, secondBarcode], [], 'milk');

      expect(merged, hasLength(1));
    });

    test('keeps the higher-scoring copy when collapsing an OFF near-duplicate', () {
      final thin = _meal(name: 'Whole Milk', code: 'thin', detailed: false);
      final detailed = _meal(name: 'Whole Milk', code: 'detailed', detailed: true);

      final merged = mergeAndRankMeals([thin, detailed], [], 'milk');

      expect(merged, [detailed]);
    });

    // #1164: same-named backend records are distinct foods, not copies. 555
    // short_title groups cover 4,215 of the 5,432 survey records, and while
    // those records were shown by short title "Egg, yolk only, raw" folded
    // into "Egg" beside "Egg, whole, raw" and was gone from the list.
    test('never collapses a backend record into a same-named OFF product', () {
      final offMilk = _meal(name: 'Whole Milk', source: MealSourceEntity.off);
      final fdcMilk = _meal(name: 'Whole Milk', source: MealSourceEntity.fdc);

      final merged = mergeAndRankMeals([offMilk], [fdcMilk], 'milk');

      expect(merged, containsAll([offMilk, fdcMilk]));
      expect(merged, hasLength(2));
    });

    test('never collapses two same-named backend records into each other', () {
      final wholeRaw = _meal(name: 'Egg', code: '2707152', source: MealSourceEntity.fdc);
      final yolkOnly = _meal(name: 'Egg', code: '2707172', source: MealSourceEntity.fdc);

      final merged = mergeAndRankMeals([], [wholeRaw, yolkOnly], 'egg');

      expect(merged, [wholeRaw, yolkOnly]);
    });

    test('never collapses two codeless backend records with different names', () {
      // The backend key is `source:code`; without a code it falls back to
      // the record's identity, not to an empty string, so two codeless
      // records do not share a key and quietly become one entry.
      MealEntity codeless(String name) => MealEntity(
        code: null,
        name: name,
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: 'g',
        servingSize: null,
        nutriments: MealNutrimentsEntity.empty(),
        source: MealSourceEntity.fdc,
      );
      final wholeRaw = codeless('Egg, whole, raw');
      final yolkOnly = codeless('Egg, yolk only, raw');

      final merged = mergeAndRankMeals([], [wholeRaw, yolkOnly], 'egg');

      expect(merged, containsAll([wholeRaw, yolkOnly]));
      expect(merged, hasLength(2));
    });

    test('never collapses a backend record, even a lower-scoring one, into a detailed OFF copy', () {
      // The collapse used to keep the higher-scoring copy of a pair; with
      // backend records out of it, the score no longer decides whether the
      // backend record survives at all.
      final detailedOff = _meal(name: 'Whole Milk', source: MealSourceEntity.off, detailed: true);
      final translatedFdc = _meal(name: 'Whole Milk', source: MealSourceEntity.fdc, machineTranslatedName: true);

      final merged = mergeAndRankMeals([detailedOff], [translatedFdc], 'milk');

      expect(merged, [detailedOff, translatedFdc]);
    });

    test('collapses same-name OFF products that also declare the same brand', () {
      final firstBarcode = _meal(name: 'Whole Milk', brands: 'Horizon', code: 'a');
      final secondBarcode = _meal(name: 'Whole Milk', brands: 'Horizon', code: 'b');

      final merged = mergeAndRankMeals([firstBarcode, secondBarcode], [], 'milk');

      expect(merged, hasLength(1));
    });

    test('does not collapse same-name OFF products that declare different brands', () {
      final horizonMilk = _meal(name: 'Whole Milk', brands: 'Horizon', code: 'a');
      final storeMilk = _meal(name: 'Whole Milk', brands: 'Store Brand', code: 'b');

      final merged = mergeAndRankMeals([horizonMilk, storeMilk], [], 'milk');

      expect(merged, containsAll([horizonMilk, storeMilk]));
      expect(merged, hasLength(2));
    });

    test('does not collapse an unbranded OFF entry into a same-named branded one', () {
      final genericMilk = _meal(name: 'Milk', code: 'a');
      final brandedMilk = _meal(name: 'Milk', brands: 'Horizon', code: 'b');

      final merged = mergeAndRankMeals([genericMilk, brandedMilk], [], 'milk');

      expect(merged, containsAll([genericMilk, brandedMilk]));
      expect(merged, hasLength(2));
    });

    test('does not collapse near-duplicates within the own-meals tier', () {
      final customMilk = _meal(name: 'Milk', source: MealSourceEntity.custom);
      final recipeMilk = _meal(name: 'Milk', source: MealSourceEntity.recipe);

      final merged = mergeAndRankMeals([customMilk], [recipeMilk], 'milk');

      expect(merged, containsAll([customMilk, recipeMilk]));
      expect(merged, hasLength(2));
    });

    test('never collapses distinctly-named meals just because both lack a name', () {
      final unnamedFirst = _meal(name: '', code: 'a');
      final unnamedSecond = _meal(name: '', code: 'b');

      final merged = mergeAndRankMeals([unnamedFirst, unnamedSecond], [], 'milk');

      expect(merged, containsAll([unnamedFirst, unnamedSecond]));
      expect(merged, hasLength(2));
    });

    test('keeps a loosely-matching own meal ahead of a closely-matching remote one', () {
      final ownMeal = _meal(name: 'My Milk Blend', source: MealSourceEntity.custom);
      final remoteMeal = _meal(name: 'Milk', source: MealSourceEntity.off);

      final merged = mergeAndRankMeals([remoteMeal], [ownMeal], 'milk');

      expect(merged, [ownMeal, remoteMeal]);
    });

    test('relevance-sorts within the own-meals tier instead of leaving source order', () {
      final looseOwn = _meal(name: 'Chocolate Milk Blend', source: MealSourceEntity.custom);
      final exactOwn = _meal(name: 'Milk', source: MealSourceEntity.recipe);

      final merged = mergeAndRankMeals([looseOwn], [exactOwn], 'milk');

      expect(merged, [exactOwn, looseOwn]);
    });

    test('relevance-sorts remote results across both sources instead of grouping by source', () {
      final looseOff = _meal(name: 'Milk Chocolate Spread', source: MealSourceEntity.off);
      final exactFdc = _meal(name: 'Milk', source: MealSourceEntity.fdc);

      final merged = mergeAndRankMeals([looseOff], [exactFdc], 'milk');

      expect(merged, [exactFdc, looseOff]);
    });
  });
}
