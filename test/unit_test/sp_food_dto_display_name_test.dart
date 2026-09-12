import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

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
}
