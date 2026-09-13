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
    // plus the qualifiers the query names, with the resolver's own scorer
    // — and ties break on the shorter description, then the backend's
    // order.
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

    test(
      'and through the translation cut, which sorts the same way',
      () {
        // Same forty-row tie over `food_translation` rows: every one
        // titled "Milch", every description seventeen characters, so only
        // the sort's stability orders them. `_rankAndTruncate` is shared,
        // but this is the path a German reader's search takes, and a
        // `List.sort` there would be the same bug for them.
        final rows = [
          for (var i = 10; i < 50; i++)
            _translationRow(i, 'Milch, Variante $i'),
        ];

        final survivors = rankAndTruncateTranslationRows(rows, 'Milch');

        expect(survivors.map((r) => r[SPConst.translationFoodId]), [
          for (var i = 10; i < 30; i++) i,
        ]);
      },
    );

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

  group('the pools the app is handed, through the cut (#1170)', () {
    // `search_food_summary(term, null, 100)` as the backend answered it
    // after Backend#10: the rows with a portion first, among them the
    // family the term names by its title, shortest first, then by id. The
    // cut applies the resolver's scorer and its tie-break, so what it
    // keeps is what the resolver would rank first among the hundred, and
    // what the backend already led with.
    test('potato keeps Potato, NFS, and puts it first', () {
      final survivors = rankAndTruncateFoodsByName(
        BackendPoolFixtures.potato,
        'potato',
      );

      expect(BackendPoolFixtures.potato, hasLength(100));
      expect(
        BackendPoolFixtures.potato.map((f) => f.shortTitle),
        everyElement('Potato'),
      );
      expect(survivors, hasLength(SPConst.maxNumberOfItems));
      expect(survivors.first.foodId, BackendPoolFixtures.potatoNfs);
      expect(survivors.first.name, 'Potato, NFS');
    });

    test('the survivors are the family\'s twenty shortest descriptions', () {
      // What the resolver's length key relies on: whatever it would pick
      // among the family by that key is inside the twenty. Every survivor
      // is no longer than any record that was cut.
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
      // Reversed, the generic record is the hundredth row in. Without the
      // length key the stable sort would keep it there, and cut it.
      final reversed = BackendPoolFixtures.potato.reversed.toList();

      final survivors = rankAndTruncateFoodsByName(reversed, 'potato');

      expect(survivors.first.name, 'Potato, NFS');
    });

    test('french fries keeps the fries records', () {
      // Fifteen of the hundred carry `french fries` past the title; scored
      // as "Potato french fries" each is 0.8 against the query, and the
      // rest of the family scores at most 0.5 (`fries` alone, on home
      // fries).
      final survivors = rankAndTruncateFoodsByName(
        BackendPoolFixtures.potato,
        'french fries',
      );

      final fries = _names(
        survivors,
      ).where((n) => n.startsWith('Potato, french fries'));
      expect(fries, hasLength(15));
      expect(
        _names(survivors).take(15),
        everyElement(startsWith('Potato, french fries')),
      );
      expect(survivors.first.name, 'Potato, french fries, NFS');
      expect(_names(survivors), isNot(contains('Potato, NFS')));
    });

    test('bread keeps the twenty shortest Bread titles, rye first', () {
      // 540 rows match `bread`; the hundred the backend now sends are all
      // titled "Bread", and "Bread, rye" (2707755) leads them where the
      // order before Backend#10 left it at rank 157, outside the hundred,
      // and the app landed on pita.
      final pool = BackendPoolFixtures.bread;

      final survivors = rankAndTruncateFoodsByName(pool, 'bread');

      expect(pool, hasLength(100));
      expect(pool.map((f) => f.shortTitle), everyElement('Bread'));
      expect(survivors, hasLength(SPConst.maxNumberOfItems));
      expect(_names(survivors), everyElement(startsWith('Bread, ')));
      expect(survivors.first.foodId, BackendPoolFixtures.breadRye);
      // Rye, soy and nut are ten characters each and keep the backend's
      // order here; naan and pita eleven; white, the everyday form, is
      // twelve.
      expect(_names(survivors).take(8), [
        'Bread, rye',
        'Bread, soy',
        'Bread, nut',
        'Bread, naan',
        'Bread, pita',
        'Bread, puri',
        'Bread, rice',
        'Bread, white',
      ]);
      expect(
        survivors.map((f) => f.name!.length),
        [for (final f in survivors) f.name!.length]..sort(),
      );
    });

    test('orange juice keeps the exact BLS title first, by its length', () {
      // The cut knows no portions: the BLS record "Orange juice" scores
      // 1.0 on its exact title and, at twelve characters, is the shortest
      // of the twenty rows titled "Orange juice" the backend sends, so it
      // is kept first. The survey's "Orange juice, 100%, NFS" is second,
      // and it is the resolver, which sees the portions, that puts it
      // first — see resolver_sibling_selection_test.
      final survivors = rankAndTruncateFoodsByName(
        BackendPoolFixtures.orangeJuice,
        'orange juice',
      );

      expect(BackendPoolFixtures.orangeJuice, hasLength(45));
      expect(survivors.first.foodId, BackendPoolFixtures.orangeJuiceBls);
      expect(survivors[1].foodId, BackendPoolFixtures.orangeJuice100Nfs);
    });
  });

  group('the real German pools through the translation cut (#1170)', () {
    // The 100 `food_translation` rows the backend answers `Milch` and
    // `Kartoffel` with, in the same order as the English search: portion,
    // then title equal to the term, then length. Thirty-two rows are
    // titled "Milch" and tie at 1.0; the generic one, 2705384's "Milch,
    // NFS", is the shortest of them and the first sent. Scored on the
    // whole description it tied "Milch, menschliche" at the shared
    // ranker's 0.9 cap — two tokens each — and the backend's order of the
    // day put menschliche first.
    test('Milch keeps Milch, NFS, and puts it first', () {
      final survivors = rankAndTruncateTranslationRows(
        BackendPoolFixtures.milch,
        'Milch',
      );

      expect(survivors, hasLength(SPConst.maxNumberOfItems));
      expect(survivors.first[SPConst.translationFoodId], 2705384);
      expect(survivors.first[SPConst.translationDescription], 'Milch, NFS');
    });

    test('every survivor is titled Milch', () {
      final survivors = rankAndTruncateTranslationRows(
        BackendPoolFixtures.milch,
        'Milch',
      );

      expect(
        BackendPoolFixtures.milch.where(
          (r) => (r[SPConst.translationDescription] as String).startsWith(
            'Milch, ',
          ),
        ),
        hasLength(32),
      );
      expect(_descriptions(survivors), everyElement(startsWith('Milch, ')));
    });

    test('Milch, NFS survives from the far end of the pool', () {
      final reversed = BackendPoolFixtures.milch.reversed.toList();

      final survivors = rankAndTruncateTranslationRows(reversed, 'Milch');

      expect(survivors.first[SPConst.translationDescription], 'Milch, NFS');
    });

    test('Kartoffel keeps Kartoffel, NFS, and puts it first', () {
      // The German reading of the potato family: 2709382 is "Potato, NFS"
      // in English and "Kartoffel, NFS" in German, and derives "Kartoffel"
      // — the word a German query is matched against.
      final survivors = rankAndTruncateTranslationRows(
        BackendPoolFixtures.kartoffel,
        'Kartoffel',
      );

      expect(survivors, hasLength(SPConst.maxNumberOfItems));
      expect(
        survivors.first[SPConst.translationFoodId],
        BackendPoolFixtures.kartoffelNfs,
      );
      expect(
        survivors.first[SPConst.translationDescription],
        'Kartoffel, NFS',
      );
      expect(
        _descriptions(survivors),
        everyElement(startsWith('Kartoffel, ')),
      );
      expect(
        _descriptions(
          rankAndTruncateTranslationRows(
            BackendPoolFixtures.kartoffel.reversed.toList(),
            'Kartoffel',
          ),
        ).first,
        'Kartoffel, NFS',
      );
    });
  });
}
