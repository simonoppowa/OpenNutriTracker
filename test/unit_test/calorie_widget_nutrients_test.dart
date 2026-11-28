import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/utils/calc/dri_reference.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_nutrients.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';

import '../fixture/user_entity_fixtures.dart';

IntakeEntity _intake({
  required double grams,
  double? fiber,
  double? sodium,
  double? vitaminB12,
}) => IntakeEntity(
  id: 'i-$grams',
  unit: 'g',
  amount: grams,
  type: IntakeTypeEntity.breakfast,
  dateTime: DateTime(2026, 9, 23, 8),
  meal: MealEntity(
    code: 'test',
    name: 'test meal',
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    source: MealSourceEntity.custom,
    nutriments: MealNutrimentsEntity(
      energyKcal100: 100,
      carbohydrates100: 0,
      fat100: 0,
      proteins100: 0,
      sugars100: null,
      saturatedFat100: null,
      fiber100: fiber,
      sodium100: sodium,
      vitaminB12100: vitaminB12,
    ),
  ),
);

TrackedDayEntity _trackedDay({
  double? fibreGoal,
  double? sodiumGoal,
  double? ironGoal,
}) => TrackedDayEntity(
  day: DateTime(2026, 9, 23),
  calorieGoal: 2000,
  caloriesTracked: 0,
  fibreGoal: fibreGoal,
  sodiumGoal: sodiumGoal,
  ironGoal: ironGoal,
);

CalorieWidgetNutrient _byId(List<CalorieWidgetNutrient> list, String id) =>
    list.singleWhere((nutrient) => nutrient.id == id);

void main() {
  group('CalorieWidgetNutrient JSON', () {
    test('stores id, consumed, goal and unit', () {
      const nutrient = CalorieWidgetNutrient(
        id: 'fiber',
        consumed: 12.5,
        goal: 30,
        unit: 'g',
      );

      expect(nutrient.toJson(), {
        'id': 'fiber',
        'consumed': 12.5,
        'goal': 30.0,
        'unit': 'g',
      });
    });

    test('a nutrient with no goal leaves the key out, not a null', () {
      const nutrient = CalorieWidgetNutrient(
        id: 'sodium',
        consumed: 800,
        unit: 'mg',
      );

      expect(nutrient.toJson().containsKey('goal'), isFalse);
      expect(nutrient.toJson(), {
        'id': 'sodium',
        'consumed': 800.0,
        'unit': 'mg',
      });
    });

    test('a nutrient round-trips through JSON', () {
      const nutrient = CalorieWidgetNutrient(
        id: 'vitamin_b12',
        consumed: 1.3,
        goal: 2.4,
        unit: 'µg',
      );

      expect(CalorieWidgetNutrient.fromJson(nutrient.toJson()), nutrient);
    });

    test('a goal of zero or less reads as no goal', () {
      for (final goal in [0, -5]) {
        final nutrient = CalorieWidgetNutrient.fromJson({
          'id': 'iron',
          'consumed': 4,
          'goal': goal,
          'unit': 'mg',
        });

        expect(nutrient, isNotNull, reason: 'goal $goal');
        expect(nutrient!.goal, isNull, reason: 'goal $goal');
      }
    });

    test('a negative or non-finite amount reads as zero', () {
      final negative = CalorieWidgetNutrient.fromJson({
        'id': 'iron',
        'consumed': -3,
        'unit': 'mg',
      });
      final infinite = CalorieWidgetNutrient.fromJson({
        'id': 'iron',
        'consumed': double.infinity,
        'unit': 'mg',
      });

      expect(negative!.consumed, 0);
      expect(infinite!.consumed, 0);
    });

    test('an entry without an id, an amount or a unit is not read', () {
      for (final entry in <Object?>[
        {'consumed': 1, 'unit': 'g'},
        {'id': 'fiber', 'unit': 'g'},
        {'id': 'fiber', 'consumed': 1},
        {'id': '', 'consumed': 1, 'unit': 'g'},
        {'id': 'fiber', 'consumed': 'many', 'unit': 'g'},
        'fiber',
        null,
      ]) {
        expect(CalorieWidgetNutrient.fromJson(entry), isNull, reason: '$entry');
      }
    });

    test('a list skips what it cannot read and keeps the rest', () {
      final list = CalorieWidgetNutrient.listFromJson([
        {'id': 'fiber', 'consumed': 1, 'unit': 'g'},
        'junk',
        {'id': 'iron', 'consumed': 2, 'unit': 'mg'},
      ]);

      expect(list.map((nutrient) => nutrient.id), ['fiber', 'iron']);
    });

    test('an old write with no list, or something else, reads as empty', () {
      expect(CalorieWidgetNutrient.listFromJson(null), isEmpty);
      expect(CalorieWidgetNutrient.listFromJson('fiber'), isEmpty);
      expect(CalorieWidgetNutrient.listFromJson({'fiber': 1}), isEmpty);
    });
  });

  group('CalorieWidgetNutrients.forDay', () {
    final intakes = [
      _intake(grams: 200, fiber: 5, sodium: 400, vitaminB12: 0.5),
      _intake(grams: 100, fiber: 3, sodium: 100),
    ];

    test('lists the panel nutrients in panel order, in their own units', () {
      final list = CalorieWidgetNutrients.forDay(
        intakes: intakes,
        visibility: const {},
      );

      expect(list.map((nutrient) => nutrient.id), NutrientPanelKeys.all);
      expect(list.map((nutrient) => nutrient.unit), [
        'g',
        'mg',
        'g',
        'g',
        'mg',
        'mg',
        'mg',
        'µg',
        'µg',
        'mg',
      ]);
    });

    test('sums the intakes the way the panel does', () {
      final list = CalorieWidgetNutrients.forDay(
        intakes: intakes,
        visibility: const {},
      );
      final totals = NutrientPanelTotals.fromIntakes(intakes);

      // 200 g x 5/100 + 100 g x 3/100 = 13 g of fibre.
      expect(_byId(list, NutrientPanelKeys.fiber).consumed, 13);
      expect(_byId(list, NutrientPanelKeys.fiber).consumed, totals.fiberG);
      expect(_byId(list, NutrientPanelKeys.sodium).consumed, 900);
      expect(_byId(list, NutrientPanelKeys.vitaminB12).consumed, 1);
      expect(_byId(list, NutrientPanelKeys.iron).consumed, 0);
    });

    test('rounds to one decimal place', () {
      final list = CalorieWidgetNutrients.forDay(
        intakes: [_intake(grams: 100, vitaminB12: 1.2345)],
        visibility: const {},
      );

      expect(_byId(list, NutrientPanelKeys.vitaminB12).consumed, 1.2);
    });

    test('a hidden nutrient is left out and the others stay', () {
      final list = CalorieWidgetNutrients.forDay(
        intakes: intakes,
        visibility: const {
          NutrientPanelKeys.sodium: false,
          NutrientPanelKeys.fiber: true,
        },
      );

      expect(
        list.any((nutrient) => nutrient.id == NutrientPanelKeys.sodium),
        isFalse,
      );
      expect(list, hasLength(NutrientPanelKeys.all.length - 1));
      expect(list.first.id, NutrientPanelKeys.fiber);
    });

    test('every nutrient hidden gives an empty list', () {
      final list = CalorieWidgetNutrients.forDay(
        intakes: intakes,
        visibility: {for (final key in NutrientPanelKeys.all) key: false},
      );

      expect(list, isEmpty);
    });

    test('no intakes give zeros, not an empty list', () {
      final list = CalorieWidgetNutrients.forDay(
        intakes: const [],
        visibility: const {},
      );

      expect(list, hasLength(NutrientPanelKeys.all.length));
      expect(list.every((nutrient) => nutrient.consumed == 0), isTrue);
    });

    test('the goal is the day\'s own goal when the person set one', () {
      final list = CalorieWidgetNutrients.forDay(
        intakes: intakes,
        visibility: const {},
        user: UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight,
        trackedDay: _trackedDay(fibreGoal: 42, sodiumGoal: 1500),
      );

      expect(_byId(list, NutrientPanelKeys.fiber).goal, 42);
      expect(_byId(list, NutrientPanelKeys.sodium).goal, 1500);
    });

    test('with no goal of their own, the goal is the published reference', () {
      final user = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
      final list = CalorieWidgetNutrients.forDay(
        intakes: intakes,
        visibility: const {},
        user: user,
      );

      final dri = getReferenceFor(
        nutrient: NutrientPanelKeys.fiber,
        user: user,
      );
      expect(dri, isNotNull);
      expect(_byId(list, NutrientPanelKeys.fiber).goal, dri!.amount);
      // Saturated fat has no IOM row: the panel's own default.
      expect(
        _byId(list, NutrientPanelKeys.saturatedFat).goal,
        DailyNutrientPanel.defaultSaturatedFatRefG,
      );
    });

    test('with no user and no day, the goals are the panel defaults', () {
      final list = CalorieWidgetNutrients.forDay(
        intakes: intakes,
        visibility: const {},
      );

      expect(
        _byId(list, NutrientPanelKeys.fiber).goal,
        DailyNutrientPanel.defaultFibreRefG,
      );
      expect(_byId(list, NutrientPanelKeys.iron).goal, 14);
      expect(
        _byId(list, NutrientPanelKeys.magnesium).goal,
        DailyNutrientPanel.defaultMagnesiumRefMg,
      );
    });

    test('a goal set to zero is left out, not shown as a zero target', () {
      final list = CalorieWidgetNutrients.forDay(
        intakes: intakes,
        visibility: const {},
        trackedDay: _trackedDay(sodiumGoal: 0),
      );

      expect(_byId(list, NutrientPanelKeys.sodium).goal, isNull);
    });
  });

  group('DailyNutrientPanel.referenceFor', () {
    test('answers what the panel\'s own resolvers answer', () {
      final day = _trackedDay(fibreGoal: 31, sodiumGoal: 1800, ironGoal: 9);

      expect(
        DailyNutrientPanel.referenceFor(NutrientPanelKeys.fiber, null, day),
        DailyNutrientPanel.resolveFibreReference(day),
      );
      expect(
        DailyNutrientPanel.referenceFor(NutrientPanelKeys.sodium, null, day),
        DailyNutrientPanel.resolveSodiumReference(day),
      );
      expect(
        DailyNutrientPanel.referenceFor(NutrientPanelKeys.iron, null, day),
        9,
      );
      expect(
        DailyNutrientPanel.referenceFor(
          NutrientPanelKeys.saturatedFat,
          null,
          null,
        ),
        DailyNutrientPanel.resolveSatFatReference(null),
      );
      expect(
        DailyNutrientPanel.referenceFor(NutrientPanelKeys.sugar, null, null),
        DailyNutrientPanel.resolveSugarsReference(null),
      );
    });

    test('has an answer for every panel key and none for another', () {
      for (final key in NutrientPanelKeys.all) {
        expect(
          DailyNutrientPanel.referenceFor(key, null, null),
          isNotNull,
          reason: key,
        );
      }
      expect(DailyNutrientPanel.referenceFor('calories', null, null), isNull);
    });
  });
}
