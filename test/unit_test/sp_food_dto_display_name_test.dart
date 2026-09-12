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

  group('scored on the title, shown by the description (#1164)', () {
    // The display change was not meant to be a scoring change: the scorers
    // match on the title, which was the name until #1164, and now derive
    // it from the description (`MealEntity.scoringName`). Nothing is
    // carried over from the DTO for it — the entity reads its own name.
    test(
      'MealEntity.fromSpFood shows the description and scores the title',
      () {
        final meal = MealEntity.fromSpFood(
          row(name: 'Egg, whole, raw', shortTitle: 'Egg'),
        );
        final calledEgg = MealEntity.fromSpFood(row(name: 'Egg'));

        expect(meal.name, 'Egg, whole, raw');
        expect(meal.scoringName, 'Egg');
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

    test('the title is derived from the name, not read off the DTO', () {
      // A row whose short title disagrees with its description — none
      // measured, but the column is the backend's to fill — is scored on
      // the description's title. The DTO's column is not consulted.
      final meal = MealEntity.fromSpFood(
        row(name: 'Egg, whole, raw', shortTitle: 'Something else'),
      );

      expect(meal.scoringName, 'Egg');
      expect(scoreMealRelevance(meal, 'egg'), 1.0);
    });

    test('a translated row is scored on its translation\'s title', () {
      // The query that found it is in its language: "Milch, menschliche"
      // derives "Milch", and a German query for Milch scores it 1.0. The
      // English column would have scored `Milch` against "Milk" at
      // nothing — the reason it is not what is scored.
      final dto = row(
        name: 'Milk, human',
        shortTitle: 'Milk',
        localizedName: 'Milch, menschliche',
      );

      final meal = MealEntity.fromSpFood(dto);

      expect(meal.name, 'Milch, menschliche');
      expect(meal.scoringName, 'Milch');
      expect(scoreMealRelevance(meal, 'Milch'), 1.0);
      expect(
        scoreMealRelevance(meal, 'Milch'),
        scoreMealRelevance(MealEntity.fromSpFood(row(name: 'Milch')), 'Milch'),
      );
    });

    test('the title survives the portion and label decoration', () {
      // `ProductsRepository` rebuilds a fresh search result once or twice
      // before the resolver sees it; the title being read off the name,
      // any copy that keeps the name keeps the title.
      final meal = MealEntity.fromSpFood(
        row(name: 'Egg, whole, raw', shortTitle: 'Egg'),
      );

      final decorated = meal.withServingLabel('1 Ei').withPortions(const [
        MealPortionEntity(label: '1 egg', gramWeight: 50, localized: false),
      ]);

      expect(decorated.scoringName, 'Egg');
      expect(decorated.name, 'Egg, whole, raw');
    });

    test('a row already on disk is scored on its title too', () {
      // A cached row from before #1164 has the short title as its name and
      // no comma; a row cached since has the description. Both derive the
      // same title, so nothing on disk needs migrating or is scored on
      // text it was not scored on before.
      final legacy = MealDBO.fromJson({
        'code': '2707152',
        'name': 'Egg',
        'source': 'fdc',
        'nutriments': <String, dynamic>{},
      });
      final current = MealDBO.fromJson({
        'code': '2707152',
        'name': 'Egg, whole, raw',
        'source': 'fdc',
        'nutriments': <String, dynamic>{},
      });

      final legacyMeal = MealEntity.fromMealDBO(legacy);
      final currentMeal = MealEntity.fromMealDBO(current);

      expect(legacyMeal.scoringName, 'Egg');
      expect(currentMeal.scoringName, 'Egg');
      expect(scoreMealForResolution(legacyMeal, 'eggs'), closeTo(0.6, 1e-9));
      expect(
        scoreMealForResolution(currentMeal, 'eggs'),
        scoreMealForResolution(legacyMeal, 'eggs'),
      );
    });
  });
}
