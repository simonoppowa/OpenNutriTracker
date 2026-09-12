import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

/// A `food_summary` row as the backend serves it: `name` is the full
/// description and `short_title` the concise form (#1164 measured 555 of
/// those covering 4,215 of the 5,432 survey records).
SpFoodDTO row({
  required String name,
  String? shortTitle,
  String? localizedName,
  bool machineTranslated = false,
}) {
  final dto = SpFoodDTO(
    foodId: 2707172,
    source: 'fdc_survey',
    sourceCode: '2707172',
    name: name,
    shortTitle: shortTitle,
  );
  dto.localizedName = localizedName;
  dto.localizedNameIsMachineTranslated = machineTranslated;
  return dto;
}

void main() {
  group('SpFoodDTO.displayName (#1164)', () {
    test('a survey row shows its full description, not its short title', () {
      final dto = row(name: 'Egg, yolk only, raw', shortTitle: 'Egg');

      expect(dto.displayName, 'Egg, yolk only, raw');
    });

    test('a localized name still wins over the description', () {
      final dto = row(
        name: 'Egg, yolk only, raw',
        shortTitle: 'Egg',
        localizedName: 'Ei, nur Eigelb, roh',
      );

      expect(dto.displayName, 'Ei, nur Eigelb, roh');
      expect(dto.displayNameIsMachineTranslated, isFalse);
    });

    test('the short title is still parsed, just not displayed', () {
      // It is a view column and the DTO mirrors the view; dropping the
      // field would be a wider change than the decision made.
      final dto = SpFoodDTO.fromJson({
        'food_id': 2707172,
        'source': 'fdc_survey',
        'source_code': '2707172',
        'name': 'Egg, yolk only, raw',
        'short_title': 'Egg',
      });

      expect(dto.shortTitle, 'Egg');
      expect(dto.displayName, 'Egg, yolk only, raw');
    });

    test('MealEntity.fromSpFood carries the full description as the name', () {
      final meal = MealEntity.fromSpFood(
        row(name: 'Egg, yolk only, raw', shortTitle: 'Egg'),
      );

      expect(meal.name, 'Egg, yolk only, raw');
      expect(meal.source, MealSourceEntity.fdc);
      expect(meal.backendSource, 'fdc_survey');
    });

    test('a machine-translated localized name is flagged on the entity', () {
      final meal = MealEntity.fromSpFood(
        row(
          name: 'Egg, yolk only, raw',
          shortTitle: 'Egg',
          localizedName: 'Ei, nur Eigelb, roh',
          machineTranslated: true,
        ),
      );

      expect(meal.name, 'Ei, nur Eigelb, roh');
      expect(meal.machineTranslatedName, isTrue);
    });
  });

  group('SpFoodDTO.searchTitle (#1164)', () {
    // The display change was not meant to be a scoring change: the scorers
    // read the short title, which was the name until #1164, through
    // `MealEntity.searchTitle`.
    test('an English row is scored on its short title', () {
      final dto = row(name: 'Egg, whole, raw', shortTitle: 'Egg');

      expect(dto.searchTitle, 'Egg');
      expect(dto.displayName, 'Egg, whole, raw');
    });

    test('a translated row is scored on its translation, as it was', () {
      // The query that found it is in its language; the English title
      // would score `Eier` against "Egg" at nothing.
      final dto = row(
        name: 'Egg, whole, raw',
        shortTitle: 'Egg',
        localizedName: 'Ei, ganz, roh',
      );

      expect(dto.searchTitle, isNull);
      expect(MealEntity.fromSpFood(dto).searchTitle, isNull);
    });

    test(
      'MealEntity.fromSpFood shows the description and scores the title',
      () {
        final meal = MealEntity.fromSpFood(
          row(name: 'Egg, whole, raw', shortTitle: 'Egg'),
        );
        final calledEgg = MealEntity.fromSpFood(row(name: 'Egg'));

        expect(meal.name, 'Egg, whole, raw');
        expect(meal.searchTitle, 'Egg');
        expect(
          scoreMealForResolution(meal, 'eggs'),
          scoreMealForResolution(calledEgg, 'eggs'),
        );
        expect(
          scoreMealRelevance(meal, 'egg'),
          scoreMealRelevance(calledEgg, 'egg'),
        );
        expect(scoreMealRelevance(meal, 'egg'), 1.0);
      },
    );

    test('the title survives the portion and label decoration', () {
      // `ProductsRepository` rebuilds a fresh search result once or twice
      // before the resolver sees it; a copy that dropped the title would be
      // scored on its description on the real path and nowhere in a unit
      // test of the scorers.
      final meal = MealEntity.fromSpFood(
        row(name: 'Egg, whole, raw', shortTitle: 'Egg'),
      );

      final decorated = meal.withServingLabel('1 Ei').withPortions(const [
        MealPortionEntity(label: '1 egg', gramWeight: 50, localized: false),
      ]);

      expect(decorated.searchTitle, 'Egg');
      expect(decorated.name, 'Egg, whole, raw');
    });

    test('the title is not persisted', () {
      // Like `portions`: `MealDBO` has no column for it, so a cached copy
      // comes back without one and is scored on its name.
      final meal = MealEntity.fromSpFood(
        row(name: 'Egg, whole, raw', shortTitle: 'Egg'),
      );

      final roundTripped = MealEntity.fromMealDBO(MealDBO.fromMealEntity(meal));

      expect(roundTripped.searchTitle, isNull);
      expect(roundTripped.name, 'Egg, whole, raw');
      expect(
        MealDBO.fromMealEntity(meal).toJson().keys,
        isNot(contains('searchTitle')),
      );
    });
  });
}
