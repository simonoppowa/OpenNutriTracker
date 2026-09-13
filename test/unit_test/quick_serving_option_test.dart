import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/util/quick_serving_option.dart';

// Locks in what the meal-detail sheet's quick-serving chip row is meant
// to show for each shape of food — the trio of ×-multipliers when the
// backend gave us a scalable serving, the 100 g shortcut whenever the
// unit dropdown would offer grams, both together for a solid with a
// serving, and nothing at all when the food is exclusively a liquid
// with no scalable serving (so 100 g would be a wrong unit).

const _nutriments = MealNutrimentsEntity(
  energyKcal100: 100,
  carbohydrates100: 10,
  fat100: 5,
  proteins100: 5,
  sugars100: 2,
  saturatedFat100: 1,
  fiber100: 1,
);

MealEntity _meal({
  double? servingQuantity,
  String? servingUnit,
  String? servingSize,
  String? mealUnit,
}) {
  return MealEntity(
    code: 'quick-serving-test',
    name: 'Test product',
    url: null,
    mealQuantity: null,
    mealUnit: mealUnit,
    servingQuantity: servingQuantity,
    servingUnit: servingUnit,
    servingSize: servingSize,
    nutriments: _nutriments,
    source: MealSourceEntity.off,
  );
}

void main() {
  group('quickServingOptionsFor', () {
    test('solid food with a scalable serving offers all four presets', () {
      final options = quickServingOptionsFor(
        _meal(servingQuantity: 30, servingUnit: 'g', mealUnit: 'g'),
        'g',
      );

      expect(options, hasLength(4));
      expect(options.map((o) => o.id).toList(), [
        'half-serving',
        'one-serving',
        'double-serving',
        '100g',
      ]);
      expect(options.map((o) => o.label).toList(), [
        '0.5×',
        '1×',
        '2×',
        '100 g',
      ]);
      expect(options.map((o) => o.unit).toList(), [
        'serving',
        'serving',
        'serving',
        'g',
      ]);
      expect(options.map((o) => o.quantity).toList(), [0.5, 1, 2, 100]);
    });

    test('liquid food with a scalable serving offers only the multipliers', () {
      final options = quickServingOptionsFor(
        _meal(servingQuantity: 250, servingUnit: 'ml', mealUnit: 'ml'),
        'g',
      );

      expect(options.map((o) => o.id).toList(), [
        'half-serving',
        'one-serving',
        'double-serving',
      ]);
      expect(options.every((o) => o.unit == 'serving'), isTrue);
    });

    test('solid food without a serving still offers the 100 g shortcut', () {
      final options = quickServingOptionsFor(_meal(mealUnit: 'g'), 'g');

      expect(options, hasLength(1));
      expect(options.single.id, '100g');
      expect(options.single.label, '100 g');
      expect(options.single.unit, 'g');
      expect(options.single.quantity, 100);
    });

    test(
      'meal with neither solid nor liquid unit (e.g. gml quick-add) still '
      'gets the 100 g shortcut, mirroring the unit dropdown',
      () {
        final options = quickServingOptionsFor(_meal(mealUnit: null), 'g');

        expect(options, hasLength(1));
        expect(options.single.id, '100g');
      },
    );

    test('purely liquid food with no serving gets no chip row', () {
      final options = quickServingOptionsFor(_meal(mealUnit: 'ml'), 'g');

      expect(options, isEmpty);
    });

    test('gram unit label passes through so callers can localise it', () {
      final options = quickServingOptionsFor(_meal(mealUnit: 'g'), 'grams');

      expect(options.single.label, '100 grams');
      expect(options.single.id, '100g');
    });

    test('id values stay ASCII regardless of the localised label', () {
      // Simulates a Cyrillic gram unit (Ukrainian "г") to confirm the id used
      // for Semantics never absorbs the label's script — that identifier is
      // meant for accessibility + integration tests, not for display.
      final options = quickServingOptionsFor(
        _meal(servingQuantity: 30, mealUnit: 'g'),
        'г',
      );

      final gramChip = options.singleWhere((o) => o.unit == 'g');
      expect(gramChip.label, '100 г');
      expect(gramChip.id, '100g');
    });

    test('scalableServingQuantity recovers from servingSize when quantity is '
        'missing', () {
      final options = quickServingOptionsFor(
        _meal(servingSize: '1 slice (30 g)', mealUnit: 'g'),
        'g',
      );

      expect(options.map((o) => o.id).toList(), [
        'half-serving',
        'one-serving',
        'double-serving',
        '100g',
      ]);
    });
  });
}
