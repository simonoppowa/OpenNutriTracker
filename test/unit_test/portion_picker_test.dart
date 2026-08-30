import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/bulk_add_bloc.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';
import 'package:opennutritracker/features/meal_detail/util/meal_quantity_converter.dart';

MealEntity _meal({
  double? servingQuantity,
  List<MealPortionEntity> portions = const [],
}) => MealEntity(
  code: '1',
  name: 'Bread',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: servingQuantity,
  servingUnit: 'g',
  servingSize: null,
  source: MealSourceEntity.fdc,
  nutriments: MealNutrimentsEntity.empty(),
  portions: portions,
);

const _cup = MealPortionEntity(label: '1 cup', gramWeight: 244, localized: false);
const _slice = MealPortionEntity(label: '1 slice', gramWeight: 38, localized: false);
const _ounce = MealPortionEntity(label: '1 oz', gramWeight: 28, localized: false);

BulkAddRow _row(MealEntity meal, String unit) => BulkAddRow(
  resolved: ResolvedMealItem(
    parsed: const ParsedMealItem(query: 'bread'),
    candidates: [meal],
    selectedIndex: 0,
    confidence: 0.9,
  ),
  selectedIndex: 0,
  amountText: '2',
  unit: unit,
);

void main() {
  group('the unit dropdown offers every portion (#864)', () {
    test('one entry per portion, in the backend order', () {
      final row = _row(_meal(portions: [_cup, _slice, _ounce]), 'serving');
      expect(
        row.allowedUnits.where(isPortionUnit),
        ['serving', 'serving#1', 'serving#2'],
      );
    });

    test('a food with no portion list keeps the single serving entry', () {
      // Everything that is not a fresh backend search result: Open Food
      // Facts, custom meals, anything read back from the database.
      final row = _row(_meal(servingQuantity: 30), 'serving');
      expect(row.allowedUnits.where(isPortionUnit), ['serving']);
    });

    test('a food with neither offers no serving at all', () {
      final row = _row(_meal(), 'g');
      expect(row.allowedUnits.where(isPortionUnit), isEmpty);
    });

    test('weights and measures are still offered alongside', () {
      final row = _row(_meal(portions: [_cup, _slice]), 'serving');
      expect(row.allowedUnits, contains('g'));
      expect(row.allowedUnits, contains('oz'));
    });
  });

  group('an amount scales by the portion the user picked', () {
    final meal = _meal(portions: [_cup, _slice, _ounce]);

    test('the first portion, named or not', () {
      expect(convertQuantityToBaseUnit(2, 'serving', meal), 488);
      expect(convertQuantityToBaseUnit(2, 'serving#0', meal), 488);
    });

    test('a later portion scales by its own weight, not the first', () {
      // The whole point: three slices is 114 g, not 732 g.
      expect(convertQuantityToBaseUnit(3, 'serving#1', meal), 114);
      expect(convertQuantityToBaseUnit(2, 'serving#2', meal), 56);
    });

    test('an index past the end does not multiply by another food', () {
      // Reachable when the user picks a different candidate under a chosen
      // unit. Falling back to the record's serving beats scaling by a
      // portion that belongs to something else.
      final short = _meal(servingQuantity: 30, portions: [_cup]);
      expect(convertQuantityToBaseUnit(2, 'serving#9', short), 60);
    });

    test('a food with no portions behaves exactly as before', () {
      expect(
        convertQuantityToBaseUnit(2, 'serving', _meal(servingQuantity: 30)),
        60,
      );
    });

    test('grams and ounces are untouched by any of this', () {
      expect(convertQuantityToBaseUnit(100, 'g', meal), 100);
      expect(convertQuantityToBaseUnit(1, 'oz', meal), closeTo(28.35, 0.01));
    });
  });
}
