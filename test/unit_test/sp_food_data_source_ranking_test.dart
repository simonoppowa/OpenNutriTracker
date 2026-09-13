import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';

import '../fixture/backend_pool_fixtures.dart';

SpFoodDTO _food(String name, {int foodId = 0}) => SpFoodDTO(
      foodId: foodId,
      source: 'off',
      sourceCode: 'off',
      name: name,
    );

List<String> _names(List<SpFoodDTO> foods) => [for (final f in foods) f.name!];

List<String> _descriptions(List<Map<String, dynamic>> rows) => [
  for (final r in rows) r[SPConst.translationDescription] as String,
];

Map<String, dynamic> _translationRow(int foodId, String description) => {
      SPConst.translationFoodId: foodId,
      SPConst.translationDescription: description,
      SPConst.translationSource: 'human',
    };

void main() {
  group('rankAndTruncateFoodsByName', () {
    test('ranks the most relevant food first', () {
      final exact = _food('Milk');
      final loose = _food('Milk Chocolate Hazelnut Spread');
      final unrelated = _food('Chicken Breast');

      final ranked = rankAndTruncateFoodsByName([unrelated, loose, exact], 'milk');

      expect(ranked.map((f) => f.name), ['Milk', 'Milk Chocolate Hazelnut Spread', 'Chicken Breast']);
    });

    test('truncates to SPConst.maxNumberOfItems', () {
      final foods = List.generate(SPConst.maxNumberOfItems + 30, (i) => _food('Milk item $i'));

      final ranked = rankAndTruncateFoodsByName(foods, 'milk');

      expect(ranked, hasLength(SPConst.maxNumberOfItems));
    });

    // Regression: a naive `.limit(20)` applied *before* ranking would drop
    // a genuinely-best match if Postgres happened to return it outside the
    // first 20 rows (arbitrary/physical order, since there's no ORDER BY —
    // see SpFoodDataSource._candidatePoolSize). This proves the exact match
    // survives truncation even when it's the very last candidate handed in.
    test('a genuinely-best match is not lost to truncation even when it arrives last', () {
      final fillerMatches =
          List.generate(SPConst.maxNumberOfItems + 10, (i) => _food('Milk filler $i'));
      final bestMatch = _food('Milk');
      final candidates = [...fillerMatches, bestMatch];

      final ranked = rankAndTruncateFoodsByName(candidates, 'milk');

      expect(ranked.first.name, 'Milk');
    });

    test('does not mutate the input list', () {
      final unrelated = _food('Chicken Breast');
      final exact = _food('Milk');
      final input = [unrelated, exact];

      rankAndTruncateFoodsByName(input, 'milk');

      expect(input, [unrelated, exact]);
    });
  });

  group('rankAndTruncateTranslationRows', () {
    test('ranks the most relevant translated description first', () {
      final exact = _translationRow(1, 'Milch');
      final loose = _translationRow(2, 'Milch-Schokoladen-Aufstrich mit Haselnuss');
      final unrelated = _translationRow(3, 'Hähnchenbrust');

      final ranked = rankAndTruncateTranslationRows([unrelated, loose, exact], 'Milch');

      expect(
        ranked.map((r) => r[SPConst.translationFoodId]),
        [1, 2, 3],
      );
    });

    test('truncates to SPConst.maxNumberOfItems', () {
      final rows = List.generate(
        SPConst.maxNumberOfItems + 30,
        (i) => _translationRow(i, 'Milch Eintrag $i'),
      );

      final ranked = rankAndTruncateTranslationRows(rows, 'Milch');

      expect(ranked, hasLength(SPConst.maxNumberOfItems));
    });

    // Same regression as rankAndTruncateFoodsByName, but for the raw
    // food_translation rows ranked ahead of the food_summary fetch.
    test('a genuinely-best match is not lost to truncation even when it arrives last', () {
      final fillerRows = List.generate(
        SPConst.maxNumberOfItems + 10,
        (i) => _translationRow(i, 'Milch Eintrag $i'),
      );
      final bestRow = _translationRow(999, 'Milch');
      final candidates = [...fillerRows, bestRow];

      final ranked = rankAndTruncateTranslationRows(candidates, 'Milch');

      expect(ranked.first[SPConst.translationFoodId], 999);
    });

    test('does not mutate the input list', () {
      final unrelated = _translationRow(1, 'Hähnchenbrust');
      final exact = _translationRow(2, 'Milch');
      final input = [unrelated, exact];

      rankAndTruncateTranslationRows(input, 'Milch');

      expect(input, [unrelated, exact]);
    });
  });

  group('scored on the title plus the qualifiers the query names (#1170)', () {
    // The twenty rows kept here are the resolver's whole world for the
    // query, and they were chosen by a different rule from the one the
    // resolver applies among them: the whole description was scored, so a
    // family of same-titled siblings did not tie here as it ties there,
    // and the sibling the resolver would pick could be cut before it was
    // scored. The row is now scored as its entity will be — `deriveTitle`
    // plus the qualifiers the query names — and ties break on the shorter
    // description, then the backend's order.
    test(
      'a family of same-titled rows ties and the shortest survives first',
      () {
        // Listed longest first, so the order is the length key's and not
        // the input's.
        final family = [
          _food('Egg, whole, boiled or poached', foodId: 1),
          _food('Egg, yolk only, raw', foodId: 2),
          _food('Egg, whole, raw', foodId: 3),
          _food('Egg, creamed', foodId: 4),
        ];

        expect(_names(rankAndTruncateFoodsByName(family, 'egg')), [
          'Egg, creamed',
          'Egg, whole, raw',
          'Egg, yolk only, raw',
          'Egg, whole, boiled or poached',
        ]);
      },
    );

    test('the shortest description survives even when it arrives last', () {
      // Every row is titled "Milk" and scores 1.0 on `milk`; without the
      // length key the stable sort keeps the backend's order among them
      // and the row that arrived last — the generic one — is the one cut.
      final fillers = List.generate(
        SPConst.maxNumberOfItems + 10,
        (i) => _food('Milk, whole, fortified, variant $i', foodId: i),
      );
      final generic = _food('Milk, NFS', foodId: 999);

      final ranked = rankAndTruncateFoodsByName([...fillers, generic], 'milk');

      expect(ranked, hasLength(SPConst.maxNumberOfItems));
      expect(ranked.first.name, 'Milk, NFS');
    });

    test('two rows that differ only in length keep the shorter first', () {
      final longer = _food('Milk, whole', foodId: 1);
      final shorter = _food('Milk, NFS', foodId: 2);

      expect(_names(rankAndTruncateFoodsByName([longer, shorter], 'milk')), [
        'Milk, NFS',
        'Milk, whole',
      ]);
      expect(_names(rankAndTruncateFoodsByName([shorter, longer], 'milk')), [
        'Milk, NFS',
        'Milk, whole',
      ]);
    });

    test('equal scores and lengths keep the backend\'s order', () {
      // "Milk, whole" and "Milk, human" are eleven characters each.
      final whole = _food('Milk, whole', foodId: 1);
      final human = _food('Milk, human', foodId: 2);

      expect(_names(rankAndTruncateFoodsByName([human, whole], 'milk')), [
        'Milk, human',
        'Milk, whole',
      ]);
      expect(_names(rankAndTruncateFoodsByName([whole, human], 'milk')), [
        'Milk, whole',
        'Milk, human',
      ]);
    });

    test('the backend\'s order survives a pool too large for insertion sort', () {
      // Two rows cannot tell a stable sort from `List.sort`: Dart
      // insertion-sorts anything under 32 elements, and that happens to be
      // stable. Above it the dual-pivot quicksort moves equal elements, so
      // forty rows that tie on the score and on the length — every one
      // titled "Milk", every description sixteen characters — are what
      // actually pins "stable after that": the twenty kept are the first
      // twenty sent, in the order they were sent. (The forty-record case
      // in resolver_relevance_test pins the resolver's sort the same way.)
      final rows = [
        for (var i = 10; i < 50; i++) _food('Milk, variant $i', foodId: i),
      ];

      final survivors = rankAndTruncateFoodsByName(rows, 'milk');

      expect(survivors.map((f) => f.foodId), [for (var i = 10; i < 30; i++) i]);
    });

    test('the shorter description wins even with more, shorter words', () {
      // Two real potato rows. Scored on the whole description the
      // four-token fries record (0.75) outscored the six-token canned one
      // (0.683) and took its place in the twenty; scored on the title
      // both are 1.0, and 28 characters beat 32.
      final canned = _food('Potato, canned, NS as to fat', foodId: 2709399);
      final fries = _food('Potato, french fries, restaurant', foodId: 2709462);

      expect(_names(rankAndTruncateFoodsByName([fries, canned], 'potato')), [
        'Potato, canned, NS as to fat',
        'Potato, french fries, restaurant',
      ]);
    });

    test('a qualifier the query names outscores the family', () {
      // Scored on the title alone "Apple, dried" would tie its siblings
      // and lose to the shorter "Apple, raw"; the `dried` the query names
      // is read off the description and it scores as "Apple dried" does.
      final family = [
        _food('Apple, raw', foodId: 1),
        _food('Apple, baked', foodId: 2),
        _food('Apple, dried', foodId: 3),
      ];

      expect(
        _names(rankAndTruncateFoodsByName(family, 'dried apple')).first,
        'Apple, dried',
      );
      expect(
        _names(rankAndTruncateFoodsByName(family, 'apple')).first,
        'Apple, raw',
      );
    });

    test('a qualifier the query does not name costs nothing', () {
      // "Bread, rice" on `bread` is scored as "Bread", and ties a plain
      // "Bread" row rather than trailing it.
      final ranked = rankAndTruncateFoodsByName([
        _food('Bread, rice', foodId: 1),
        _food('Bread', foodId: 2),
      ], 'bread');

      // Same score, so the shorter description: "Bread" (5) first.
      expect(_names(ranked), ['Bread', 'Bread, rice']);
    });

    test('a translated description is scored the same way', () {
      final family = [
        _translationRow(1, 'Milch, menschliche'),
        _translationRow(2, 'Milch, NFS'),
        _translationRow(3, 'Milch, laktosefrei, Vollmilch'),
      ];

      expect(_descriptions(rankAndTruncateTranslationRows(family, 'Milch')), [
        'Milch, NFS',
        'Milch, menschliche',
        'Milch, laktosefrei, Vollmilch',
      ]);
      expect(
        _descriptions(
          rankAndTruncateTranslationRows(family, 'laktosefrei Milch'),
        ).first,
        'Milch, laktosefrei, Vollmilch',
      );
    });
  });

  group('the whole Potato family, handed to the cut on its own (#1170)', () {
    // 106 survey records titled "Potato", in the order they take among
    // themselves in the backend's ordering. Scored on the whole description
    // the twenty with the fewest tokens survived; scored on the title all
    // 106 tie, and the twenty shortest survive.
    //
    // The app never hands the cut this pool for `potato`: the backend's
    // own hundred — the first hundred matches by deliverable portion, then
    // id — hold none of the family, and the group after this one pins what
    // the cut is actually handed. This group pins what the cut does with a
    // family when one reaches it.
    test('potato keeps Potato, NFS, and puts it first', () {
      final survivors = rankAndTruncateFoodsByName(
        BackendPoolFixtures.potato,
        'potato',
      );

      expect(survivors, hasLength(SPConst.maxNumberOfItems));
      expect(survivors.first.foodId, BackendPoolFixtures.potatoNfs);
      expect(survivors.first.name, 'Potato, NFS');
    });

    test('the survivors are the family\'s twenty shortest descriptions', () {
      // What the resolver's length key relies on when a family reaches the
      // cut: whatever it would pick among the family by that key is inside
      // the twenty. Every survivor is no longer than any record that was
      // cut.
      final pool = BackendPoolFixtures.potato;
      final survivors = rankAndTruncateFoodsByName(pool, 'potato');
      final kept = {for (final f in survivors) f.foodId};
      final cut = pool.where((f) => !kept.contains(f.foodId));

      final longestKept = survivors
          .map((f) => f.name!.length)
          .reduce((a, b) => a > b ? a : b);
      final shortestCut = cut
          .map((f) => f.name!.length)
          .reduce((a, b) => a < b ? a : b);
      expect(cut, hasLength(pool.length - SPConst.maxNumberOfItems));
      expect(longestKept, lessThanOrEqualTo(shortestCut));
      // Among the survivors, the length order holds throughout.
      expect(
        survivors.map((f) => f.name!.length),
        [for (final f in survivors) f.name!.length]..sort(),
      );
    });

    test('Potato, NFS survives from the far end of the pool', () {
      // Reversed, the generic record is the 106th row in. Without the
      // length key the stable sort would keep it there, and cut it.
      final reversed = BackendPoolFixtures.potato.reversed.toList();

      final survivors = rankAndTruncateFoodsByName(reversed, 'potato');

      expect(survivors.first.name, 'Potato, NFS');
    });

    test('french fries keeps the fries records', () {
      // Sixteen records carry `french fries` past the title; scored as
      // "Potato french fries" each is 0.8 against the query, and the rest
      // of the family scores at most 0.5 (`fries` alone, on home fries).
      final survivors = rankAndTruncateFoodsByName(
        BackendPoolFixtures.potato,
        'french fries',
      );

      final fries = _names(
        survivors,
      ).where((n) => n.startsWith('Potato, french fries'));
      expect(fries, hasLength(16));
      expect(
        _names(survivors).take(16),
        everyElement(startsWith('Potato, french fries')),
      );
      expect(survivors.first.name, 'Potato, french fries, NFS');
      expect(_names(survivors), isNot(contains('Potato, NFS')));
    });
  });

  group('the pool the app is handed for potato, through the cut (#1170 review)', () {
    // `search_food_summary('potato', null, 100)` as the backend answered
    // it. 712 rows match; the hundred lowest-id ones with a portion are
    // all dishes, "Potato, NFS" is rank 128, and the family sits at 128 to
    // 488. The cut cannot keep what it was never sent, and c78b5a38's
    // "inside the twenty by construction" was measured on the family, not
    // on this.
    test('no row titled Potato is in the pool, so none survives', () {
      final pool = BackendPoolFixtures.potatoSearch;

      final survivors = rankAndTruncateFoodsByName(pool, 'potato');

      expect(pool, hasLength(100));
      expect(pool.map((f) => f.shortTitle), isNot(contains('Potato')));
      expect(
        pool.map((f) => f.foodId),
        isNot(contains(BackendPoolFixtures.potatoNfs)),
      );
      expect(survivors, hasLength(SPConst.maxNumberOfItems));
      expect(_names(survivors), isNot(contains('Potato, NFS')));
      expect(
        survivors.map((f) => f.name!.startsWith('Potato')),
        everyElement(isFalse),
      );
    });

    test('the survivors are ten titles holding the word, then the shortest', () {
      // No title is "Potato" and no qualifier is the exact token `potato`
      // — the dishes carry `potatoes` — so the shared ranker's contains
      // bonus is all there is: the ten rows whose title holds the word
      // ("Beef and potatoes", "Beef stew with potatoes") score 0.2,
      // shortest first, and the other ten are the shortest of the rest, at
      // nothing. The stew the resolver goes on to log survives here at
      // nothing, 58 characters, in the backend's order among the zeros.
      final survivors = rankAndTruncateFoodsByName(
        BackendPoolFixtures.potatoSearch,
        'potato',
      );

      bool titleHoldsPotato(SpFoodDTO f) =>
          f.shortTitle!.toLowerCase().contains('potato');
      expect(_names(survivors).first, 'Beef and potatoes, no sauce');
      expect(survivors.take(10).map(titleHoldsPotato), everyElement(isTrue));
      expect(survivors.skip(10).map(titleHoldsPotato), everyElement(isFalse));
      expect(
        survivors.map((f) => f.foodId),
        contains(BackendPoolFixtures.stewedBeefWithPotatoes),
      );
    });
  });

  group('the pool the app is handed for bread, through the cut (#1170 review)', () {
    // `search_food_summary('bread', null, 100)` as the backend answered
    // it. 540 rows match; thirty-one of the hundred are titled "Bread",
    // and "Bread, rye" (2707755) is rank 157, outside them.
    test('bread keeps the twenty shortest Bread titles; rye was never sent', () {
      final pool = BackendPoolFixtures.breadSearch;

      final survivors = rankAndTruncateFoodsByName(pool, 'bread');

      expect(pool, hasLength(100));
      expect(pool.where((f) => f.shortTitle == 'Bread'), hasLength(31));
      expect(
        pool.map((f) => f.foodId),
        isNot(contains(BackendPoolFixtures.breadRye)),
      );
      expect(survivors, hasLength(SPConst.maxNumberOfItems));
      expect(_names(survivors), everyElement(startsWith('Bread, ')));
      // Naan (2707613) and pita (2707616) are eleven characters each and
      // keep the backend's order here; the resolver's portions key is what
      // puts pita first among the entities.
      expect(_names(survivors).take(3), [
        'Bread, naan',
        'Bread, pita',
        'Bread, white',
      ]);
      expect(
        survivors.map((f) => f.name!.length),
        [for (final f in survivors) f.name!.length]..sort(),
      );
    });
  });

  group('the real German Milch pool through the cut (#1170)', () {
    // The 100 `food_translation` rows the backend answers `Milch` with.
    // Nineteen are titled "Milch" and tie at 1.0; the generic one,
    // 2705384's "Milch, NFS", is the shortest of them. Scored on the whole
    // description it tied "Milch, menschliche" at the 0.9 cap — two tokens
    // each — and the backend's order put menschliche first.
    test('Milch keeps Milch, NFS, and puts it first', () {
      final survivors = rankAndTruncateTranslationRows(
        BackendPoolFixtures.milch,
        'Milch',
      );

      expect(survivors, hasLength(SPConst.maxNumberOfItems));
      expect(survivors.first[SPConst.translationFoodId], 2705384);
      expect(survivors.first[SPConst.translationDescription], 'Milch, NFS');
    });

    test('every row titled Milch survives', () {
      final survivors = rankAndTruncateTranslationRows(
        BackendPoolFixtures.milch,
        'Milch',
      );

      final titledMilch = _descriptions(
        survivors,
      ).where((d) => d.startsWith('Milch, '));
      expect(titledMilch, hasLength(19));
      expect(
        _descriptions(survivors).take(19),
        everyElement(startsWith('Milch, ')),
      );
    });

    test('Milch, NFS survives from the far end of the pool', () {
      final reversed = BackendPoolFixtures.milch.reversed.toList();

      final survivors = rankAndTruncateTranslationRows(reversed, 'Milch');

      expect(survivors.first[SPConst.translationDescription], 'Milch, NFS');
    });
  });
}
