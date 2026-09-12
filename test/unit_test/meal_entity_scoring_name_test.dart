import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/backend_title.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

import '../fixture/backend_sibling_fixtures.dart';

MealEntity meal(
  String? name, {
  MealSourceEntity source = MealSourceEntity.fdc,
}) => MealEntity(
  code: name ?? 'nameless',
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: source,
  backendSource: source == MealSourceEntity.fdc ? 'fdc_survey' : null,
);

/// `MealEntity.scoringName` (#1164): the title the scorers match a backend
/// record on is derived from its name, not carried from the backend or
/// persisted. The backend's `short_title` column measured equal to the
/// name up to its first comma on every FDC row and 7,135 of 7,140 BLS
/// rows, so the fixtures' real titles are what the derivation is held to.
/// `MealEntity.scoringQualifiers` is the rest of the same name, which the
/// scorers read only where the query names one of its words.
void main() {
  group('the derived title equals the backend short title', () {
    test('on every fixture row', () {
      // The fixtures carry the column as the backend serves it — survey,
      // SR Legacy, Foundation and BLS rows among them — and the derivation
      // must land on it for each. A row where it did not would be scored
      // on different text from what the persisted column would have given.
      final rows = BackendSiblingFixtures.all;
      expect(rows, hasLength(27));

      for (final record in rows) {
        expect(
          record.scoringName,
          BackendSiblingFixtures.shortTitleOf(record),
          reason: record.name,
        );
      }
    });

    test('a multi-word title survives whole', () {
      // The comma is the boundary, not the space: "Chicken breast" and
      // "Orange juice" are the titles the backend has for these.
      expect(
        BackendSiblingFixtures.chickenBreastBaked.scoringName,
        'Chicken breast',
      );
      expect(
        BackendSiblingFixtures.orangeJuice100Nfs.scoringName,
        'Orange juice',
      );
    });
  });

  group('a localized name derives a localized title', () {
    test('Milch, menschliche derives Milch', () {
      // The point a persisted English title would have got wrong: a
      // German reader's query is German, and "Milk" scores nothing on it.
      expect(meal('Milch, menschliche').scoringName, 'Milch');
    });

    test('and scores against Milch as a record called Milch does', () {
      final translated = meal('Milch, menschliche');
      final called = meal('Milch');

      expect(
        scoreMealForResolution(translated, 'Milch'),
        scoreMealForResolution(called, 'Milch'),
      );
      expect(
        scoreMealRelevance(translated, 'Milch'),
        scoreMealRelevance(called, 'Milch'),
      );
      expect(scoreMealRelevance(translated, 'Milch'), 1.0);
      // And not as "Milk" would: the English column scores nothing here.
      expect(scoreMealRelevance(meal('Milk, human'), 'Milch'), 0.0);
    });
  });

  group('the edges of the derivation', () {
    test('a name with no comma derives itself', () {
      expect(meal('Orange juice').scoringName, 'Orange juice');
      expect(BackendSiblingFixtures.orangeJuiceBls.scoringName, 'Orange juice');
    });

    test('the title is trimmed', () {
      expect(meal('Egg , whole, raw').scoringName, 'Egg');
    });

    test('nothing before the comma falls back to the whole name', () {
      // An empty title would score nothing on everything; the name at
      // least scores what it did before the derivation existed.
      expect(meal(', whole, raw').scoringName, ', whole, raw');
      expect(meal('  , whole').scoringName, '  , whole');
    });

    test('a nameless record derives nothing', () {
      expect(meal(null).scoringName, isNull);
    });
  });

  group('the qualifiers are the rest of the name', () {
    test(
      'title and qualifiers together are the name, on every fixture row',
      () {
        // The split is at the first comma and nothing is lost to it: put
        // back together with the ", " the backend writes, the two are the
        // description again. A row with no comma has no qualifiers.
        for (final record in BackendSiblingFixtures.all) {
          final qualifiers = record.scoringQualifiers;
          expect(
            qualifiers == null
                ? record.scoringName
                : '${record.scoringName}, $qualifiers',
            record.name,
            reason: record.name,
          );
        }
        expect(
          BackendSiblingFixtures.eggWholeRaw.scoringQualifiers,
          'whole, raw',
        );
        expect(
          BackendSiblingFixtures.chickenBreastBaked.scoringQualifiers,
          'baked, broiled, or roasted, skin not eaten, from raw',
        );
        expect(BackendSiblingFixtures.orangeJuiceBls.scoringQualifiers, isNull);
      },
    );

    test('a comma with nothing after it leaves no qualifiers', () {
      expect(meal('Egg,').scoringQualifiers, isNull);
      expect(meal('Egg, ').scoringQualifiers, isNull);
      expect(meal('Egg,').scoringName, 'Egg');
    });

    test('a name that is not split has no qualifiers', () {
      // Where the title falls back to the whole name, nothing is left over
      // to read past it — the two getters split the same way or not at all.
      expect(meal(', whole, raw').scoringQualifiers, isNull);
      expect(meal('Orange juice').scoringQualifiers, isNull);
      expect(meal(null).scoringQualifiers, isNull);
    });

    test('the qualifiers are trimmed', () {
      expect(meal('Egg ,  whole, raw ').scoringQualifiers, 'whole, raw');
    });
  });

  group('backend records only', () {
    test('an OFF product\'s scoring name is its full name', () {
      final off = meal('Egg, whole, raw', source: MealSourceEntity.off);

      expect(off.scoringName, 'Egg, whole, raw');
      expect(off.scoringQualifiers, isNull);
      // Which is what an OFF product has always been scored on: the three
      // tokens cost it against `eggs` where a backend twin pays nothing.
      expect(scoreMealForResolution(off, 'eggs'), closeTo(0.375, 1e-9));
      expect(
        scoreMealForResolution(meal('Egg, whole, raw'), 'eggs'),
        closeTo(0.6, 1e-9),
      );
    });

    test('a custom meal and a recipe score on the whole name too', () {
      for (final source in [
        MealSourceEntity.custom,
        MealSourceEntity.recipe,
        MealSourceEntity.unknown,
      ]) {
        expect(
          meal('Soup, my own', source: source).scoringName,
          'Soup, my own',
          reason: source.name,
        );
        expect(
          meal('Soup, my own', source: source).scoringQualifiers,
          isNull,
          reason: source.name,
        );
      }
    });
  });

  group('a cached row scores as its fresh twin on the title', () {
    test('through the MealDBO round trip, with no title stored', () {
      final fresh = BackendSiblingFixtures.eggWholeBoiledOrPoached;
      final dbo = MealDBO.fromMealEntity(fresh);
      final cached = MealEntity.fromMealDBO(dbo);

      // Nothing about the title is on the row: the name is, and the title
      // is read off it on both sides.
      expect(dbo.toJson().keys, isNot(contains('searchTitle')));
      expect(cached.name, fresh.name);
      expect(cached.scoringName, 'Egg');
      expect(cached.scoringName, fresh.scoringName);
      expect(cached.scoringQualifiers, fresh.scoringQualifiers);
      expect(cached.portions, isEmpty);

      // The shared ranker sees only the title: identical.
      expect(
        scoreMealRelevance(cached, 'egg'),
        scoreMealRelevance(fresh, 'egg'),
      );
      expect(
        scoreMealRelevance(cached, 'eggs'),
        scoreMealRelevance(fresh, 'eggs'),
      );
      // The resolver sees the title identically and then the portions the
      // cache does not keep — the no-portions penalty is the whole gap.
      expect(scoreMealForResolution(fresh, 'egg'), 1.0);
      expect(scoreMealForResolution(cached, 'egg'), closeTo(0.85, 1e-9));
      expect(
        scoreMealForResolution(cached, 'eggs'),
        closeTo(scoreMealForResolution(fresh, 'eggs') - 0.15, 1e-9),
      );
    });

    test('and through the export JSON, which an import reads back', () {
      // Through the export's own encoding, so a nested object is a map
      // the way an import sees it — and with no title key in it.
      final fresh = BackendSiblingFixtures.riceCookedNfs;
      final exported =
          jsonDecode(jsonEncode(MealDBO.fromMealEntity(fresh)))
              as Map<String, dynamic>;
      final imported = MealEntity.fromMealDBO(MealDBO.fromJson(exported));

      expect(exported.keys, isNot(contains('searchTitle')));
      expect(imported.scoringName, 'Rice');
      expect(scoreMealRelevance(imported, 'rice'), 1.0);
    });
  });

  group('the entity and the data source derive the same title (#1170)', () {
    // `deriveTitle` and `deriveQualifiers` are what the data source scores
    // a raw backend row on before any entity exists; the entity's getters
    // must be the same derivation, or the twenty rows kept and the one
    // picked among them are chosen by two rules.
    test('on every fixture row', () {
      for (final record in BackendSiblingFixtures.all) {
        expect(
          deriveTitle(record.name!),
          record.scoringName,
          reason: record.name,
        );
        expect(
          deriveQualifiers(record.name!),
          record.scoringQualifiers,
          reason: record.name,
        );
        expect(
          deriveTitle(record.name!),
          BackendSiblingFixtures.shortTitleOf(record),
          reason: record.name,
        );
      }
    });

    test('and on the edges', () {
      expect(deriveTitle('Orange juice'), 'Orange juice');
      expect(deriveQualifiers('Orange juice'), isNull);
      expect(deriveTitle('Egg , whole, raw'), 'Egg');
      expect(deriveQualifiers('Egg ,  whole, raw '), 'whole, raw');
      expect(deriveTitle('Egg,'), 'Egg');
      expect(deriveQualifiers('Egg,'), isNull);
      expect(deriveQualifiers('Egg, '), isNull);
      expect(deriveTitle(', whole, raw'), ', whole, raw');
      expect(deriveQualifiers(', whole, raw'), isNull);
      expect(deriveTitle('  , whole'), '  , whole');
      expect(deriveTitle(''), '');
      expect(deriveQualifiers(''), isNull);
    });

    test('the helper knows nothing of the source; the entity does', () {
      // The data source's rows are always backend rows, so it derives
      // without asking. The entity guards, because an OFF product name
      // with a comma in it is not split.
      expect(deriveTitle('Egg, whole, raw'), 'Egg');
      expect(
        meal('Egg, whole, raw', source: MealSourceEntity.off).scoringName,
        'Egg, whole, raw',
      );
    });
  });
}
