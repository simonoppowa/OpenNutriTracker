import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';

MealEntity _meal({
  required String name,
  String? brands,
  MealSourceEntity source = MealSourceEntity.off,
  bool detailed = false,
  bool machineTranslatedName = false,
}) {
  return MealEntity(
    code: name,
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

    test('collapses the same unbranded food surfaced by two different sources', () {
      final offMilk = _meal(name: 'Whole Milk', source: MealSourceEntity.off);
      final fdcMilk = _meal(name: 'Whole Milk', source: MealSourceEntity.fdc);

      final merged = mergeAndRankMeals([offMilk], [fdcMilk], 'milk');

      expect(merged, hasLength(1));
    });

    test('keeps the higher-scoring copy when collapsing a cross-source near-duplicate', () {
      final thinOff = _meal(name: 'Whole Milk', source: MealSourceEntity.off, detailed: false);
      final detailedFdc = _meal(name: 'Whole Milk', source: MealSourceEntity.fdc, detailed: true);

      final merged = mergeAndRankMeals([thinOff], [detailedFdc], 'milk');

      expect(merged, [detailedFdc]);
    });

    test('collapses same-name meals that also declare the same brand', () {
      final offBranded = _meal(name: 'Whole Milk', brands: 'Horizon', source: MealSourceEntity.off);
      final fdcBranded = _meal(name: 'Whole Milk', brands: 'Horizon', source: MealSourceEntity.fdc);

      final merged = mergeAndRankMeals([offBranded], [fdcBranded], 'milk');

      expect(merged, hasLength(1));
    });

    test('does not collapse same-name meals that declare different brands', () {
      final horizonMilk = _meal(name: 'Whole Milk', brands: 'Horizon', source: MealSourceEntity.off);
      final storeMilk = _meal(name: 'Whole Milk', brands: 'Store Brand', source: MealSourceEntity.fdc);

      final merged = mergeAndRankMeals([horizonMilk], [storeMilk], 'milk');

      expect(merged, containsAll([horizonMilk, storeMilk]));
      expect(merged, hasLength(2));
    });

    test('does not collapse an unbranded entry into a same-named branded one', () {
      final genericMilk = _meal(name: 'Milk', source: MealSourceEntity.off);
      final brandedMilk = _meal(name: 'Milk', brands: 'Horizon', source: MealSourceEntity.fdc);

      final merged = mergeAndRankMeals([genericMilk], [brandedMilk], 'milk');

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
      final unnamedOff = _meal(name: '', source: MealSourceEntity.off);
      final unnamedFdc = _meal(name: '', source: MealSourceEntity.fdc);

      final merged = mergeAndRankMeals([unnamedOff], [unnamedFdc], 'milk');

      expect(merged, containsAll([unnamedOff, unnamedFdc]));
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
