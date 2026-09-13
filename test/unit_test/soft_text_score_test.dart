import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/util/backend_title.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';
import 'package:opennutritracker/features/add_meal/util/soft_text_score.dart';

import '../fixture/backend_pool_fixtures.dart';

/// The one rule the data source's cut and the resolver share (#1170):
/// which qualifier tokens a query names, and what a title plus those
/// scores. Pinned here on the helper itself; that the two callers agree
/// on real pools is pinned in resolver_sibling_selection_test.
void main() {
  group('namedQualifiers', () {
    Set<String> named(String title, String qualifiers, String query) =>
        namedQualifiers(tokenize(title), tokenize(qualifiers), tokenize(query));

    test('names a qualifier the query holds exactly', () {
      expect(named('Apple', 'dried', 'dried apple'), {'dried'});
      expect(named('Milk', 'whole', 'whole milk'), {'whole'});
    });

    test('names a qualifier by inflection', () {
      // `cheesy` agrees with `cheese` five letters in, `yolks` with `yolk`
      // four, `fried` with `fries` four — all better than with the title.
      expect(named('Potato', 'french fries, with cheese', 'cheesy potato'), {
        'cheese',
      });
      expect(named('Egg', 'yolk only, raw', 'egg yolks'), {'yolk'});
      expect(
        named('Potato', 'french fries, from fresh, fried', 'fried potato'),
        {'fries', 'fried'},
      );
    });

    test('a qualifier the title accounts for better stays out', () {
      // On `rice`, "Puerto Rican" agrees with the query three letters in
      // (0.6); the title agrees exactly, so the qualifier is not named
      // and the record ties its siblings on the title.
      expect(
        named('Rice', 'white, cooked with fat, Puerto Rican style', 'rice'),
        isEmpty,
      );
    });

    test('a qualifier the query does not mention is never named', () {
      expect(named('Egg', 'whole, raw', 'egg'), isEmpty);
      expect(named('Egg', 'whole, raw', 'eggs'), isEmpty);
      expect(named('Bread', 'rice', 'bread'), isEmpty);
    });

    test('a qualifier is named even when the title matches nothing', () {
      // "Bread, rice" on `rice`: the title agrees with nothing, the
      // qualifier exactly.
      expect(named('Bread', 'rice', 'rice'), {'rice'});
    });
  });

  group('scoreText', () {
    test('scores the title plus the named qualifiers, soft Dice', () {
      final query = tokenize('dried apple');

      expect(scoreText('Apple', query, qualifiers: 'dried'), 1.0);
      expect(
        scoreText('Apple', query, qualifiers: 'raw'),
        closeTo(0.667, 1e-3),
      );
      expect(scoreText('Apple', query), closeTo(0.667, 1e-3));
    });

    test('a named qualifier is matched as softly as the title', () {
      expect(
        scoreText('Egg', tokenize('egg yolks'), qualifiers: 'yolk only, raw'),
        closeTo(0.9, 1e-9),
      );
      expect(
        scoreText(
          'Potato',
          tokenize('cheesy potato'),
          qualifiers: 'french fries, with cheese',
        ),
        closeTo(0.917, 1e-3),
      );
    });

    test('nothing for no text, an empty query, or a blank title', () {
      expect(scoreText(null, tokenize('egg')), 0.0);
      expect(scoreText('Egg', tokenize('')), 0.0);
      expect(scoreText('Egg', const {}), 0.0);
      expect(scoreText('  ', tokenize('egg'), qualifiers: 'egg'), 0.0);
    });

    test('inflection tolerance, the reason the scorer exists', () {
      expect(scoreText('Egg', tokenize('eggs')), closeTo(0.75, 1e-9));
      expect(
        scoreText('Cadbury Creme Eggs', tokenize('eggs')),
        closeTo(0.5, 1e-9),
      );
      expect(scoreText('Apricot', tokenize('apple')), 0.0);
    });
  });

  group('tokenize', () {
    test('lower-cases, splits on anything but letters and digits', () {
      expect(tokenize('  Orange juice, 100%,  freshly squeezed '), {
        'orange',
        'juice',
        '100',
        'freshly',
        'squeezed',
      });
      expect(tokenize(null), isEmpty);
      expect(tokenize('   '), isEmpty);
    });
  });

  group('one rule: the cut scores a row as the resolver scores its entity', () {
    // The data source scores `deriveTitle` and `deriveQualifiers` of the
    // raw description with [scoreText]; the resolver scores
    // `MealEntity.scoringName` and `scoringQualifiers` of the entity built
    // from it with the same function, and adds only what the row cannot
    // carry — brand, the quality tie-breakers, the no-portions penalty.
    // With a portion on the entity, the two numbers are the same number,
    // on every row of a real pool and on every query here.
    MealEntity withPortion(String name) => MealEntity(
      code: name,
      name: name,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.fdc,
      portions: const [
        MealPortionEntity(label: '1 cup', gramWeight: 100, localized: false),
      ],
    );

    test('on the potato pool', () {
      for (final query in [
        'potato',
        'cheesy potato',
        'fried potato',
        'fries',
      ]) {
        final queryTokens = tokenize(query);
        for (final row in BackendPoolFixtures.potato) {
          final atTheCut = scoreText(
            deriveTitle(row.name!),
            queryTokens,
            qualifiers: deriveQualifiers(row.name!),
          );
          final inTheResolver = scoreMealForResolution(
            withPortion(row.name!),
            query,
          );
          expect(inTheResolver, atTheCut, reason: '$query: ${row.name}');
        }
      }
    });
  });
}
