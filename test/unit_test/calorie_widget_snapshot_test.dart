import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';

void main() {
  group('CalorieWidgetSnapshot.fromHome', () {
    test('maps supplied intake and goal to rounded kilocalories', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 180.4,
        goalKcal: 2000.6,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 13, 0),
      );

      expect(snapshot.hasData, isTrue);
      expect(snapshot.consumedKcal, 180);
      expect(snapshot.goalKcal, 2001);
      expect(snapshot.dayId, '2026-09-23');
      expect(snapshot.toJson(), {
        'hasData': true,
        'day': '2026-09-23',
        'offsetMinutes': 0,
        'consumed': 180,
        'goal': 2001,
      });
    });

    test('no macro figures are stored as an absent key, not a null', () async {
      // Older readers decode the same snapshot unchanged.
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 10,
        goalKcal: 2000,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 13, 0),
      );

      expect(snapshot.toJson().containsKey('macros'), isFalse);
      expect(CalorieWidgetMacros.fromJson(snapshot.toJson()['macros']), isNull);
    });

    test('macro figures round-trip grams and goals', () async {
      const macros = CalorieWidgetMacros(
        proteinIntakeG: 9,
        proteinGoalG: 75,
        carbsIntakeG: 20,
        carbsGoalG: 300,
        fatsIntakeG: 4,
        fatsGoalG: 67,
      );
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 10,
        goalKcal: 2000,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 13, 0),
        macros: macros,
      );

      expect(snapshot.macros, macros);
      expect(CalorieWidgetMacros.fromJson(snapshot.toJson()['macros']), macros);
    });

    test('a snapshot without a goal carries no macro rows', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 40,
        goalKcal: 0,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 8, 0),
        macros: const CalorieWidgetMacros(
          proteinIntakeG: 9,
          proteinGoalG: 75,
          carbsIntakeG: 20,
          carbsGoalG: 300,
          fatsIntakeG: 4,
          fatsGoalG: 67,
        ),
      );

      expect(snapshot.macros, isNull);
    });

    test('a zero goal is a placeholder, not a progress ring', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 40,
        goalKcal: 0,
        offsetMinutes: 0,
        now: DateTime(2026, 9, 23, 8, 0),
      );

      expect(snapshot.hasData, isFalse);
      expect(snapshot.toJson()['hasData'], isFalse);
      expect(snapshot.toJson()['consumed'], 0);
    });

    test('an out-of-range offset is treated as midnight', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 10,
        goalKcal: 2000,
        offsetMinutes: 24 * 60,
        now: DateTime(2026, 9, 23, 1, 0),
      );

      expect(snapshot.offsetMinutes, 0);
      expect(snapshot.dayId, '2026-09-23');
    });
  });

  group('CalorieWidgetSnapshot water', () {
    CalorieWidgetSnapshot fromHome({
      double goalKcal = 2000,
      CalorieWidgetWater? water,
      CalorieWidgetMacros? macros,
    }) => CalorieWidgetSnapshot.fromHome(
      consumedKcal: 10,
      goalKcal: goalKcal,
      offsetMinutes: 0,
      now: DateTime(2026, 9, 23, 13, 0),
      macros: macros,
      water: water,
    );

    test('water is stored in millilitres next to its goal', () {
      final snapshot = fromHome(
        water: const CalorieWidgetWater(intakeMl: 750, goalMl: 1900),
      );

      expect(snapshot.toJson()['water'], {'ml': 750, 'goalMl': 1900});
    });

    test('no water figures are an absent key, not a null', () {
      final json = fromHome().toJson();

      expect(json.containsKey('water'), isFalse);
      expect(CalorieWidgetWater.fromJson(json['water']), isNull);
    });

    test('water round-trips through JSON', () {
      const water = CalorieWidgetWater(intakeMl: 750, goalMl: 1900);
      final snapshot = fromHome(water: water);

      expect(snapshot.water, water);
      expect(CalorieWidgetWater.fromJson(snapshot.toJson()['water']), water);
    });

    test('a water goal of zero or less hides water', () {
      for (final goal in [0, -500]) {
        final snapshot = fromHome(
          water: CalorieWidgetWater(intakeMl: 300, goalMl: goal),
        );

        expect(snapshot.water, isNull, reason: 'goal $goal');
        expect(snapshot.toJson().containsKey('water'), isFalse);
      }
    });

    test('a snapshot without a calorie goal carries no water', () {
      final snapshot = fromHome(
        goalKcal: 0,
        water: const CalorieWidgetWater(intakeMl: 300, goalMl: 1900),
      );

      expect(snapshot.water, isNull);
    });

    test('water and macros travel together beside the ring keys', () {
      const macros = CalorieWidgetMacros(
        proteinIntakeG: 9,
        proteinGoalG: 75,
        carbsIntakeG: 20,
        carbsGoalG: 300,
        fatsIntakeG: 4,
        fatsGoalG: 67,
      );
      final json = fromHome(
        macros: macros,
        water: const CalorieWidgetWater(intakeMl: 250, goalMl: 1900),
      ).toJson();

      expect(json, {
        'hasData': true,
        'day': '2026-09-23',
        'offsetMinutes': 0,
        'consumed': 10,
        'goal': 2000,
        'macros': macros.toJson(),
        'water': {'ml': 250, 'goalMl': 1900},
      });
    });

    test('reading rounds fractions and floors negatives at zero', () {
      expect(
        CalorieWidgetWater.fromJson({'ml': 750.6, 'goalMl': 1899.4}),
        const CalorieWidgetWater(intakeMl: 751, goalMl: 1899),
      );
      expect(
        CalorieWidgetWater.fromJson({'ml': -20, 'goalMl': 1900}),
        const CalorieWidgetWater(intakeMl: 0, goalMl: 1900),
      );
    });

    test('reading anything that is not a water map gives null', () {
      expect(CalorieWidgetWater.fromJson(null), isNull);
      expect(CalorieWidgetWater.fromJson('750'), isNull);
      expect(CalorieWidgetWater.fromJson(<String, Object?>{}), isNull);
      expect(CalorieWidgetWater.fromJson({'ml': 'x', 'goalMl': 1900}), isNull);
    });

    test('a snapshot written before water existed reads without it', () {
      // The shape an older app wrote: ring keys and labels only.
      final old = <String, Object?>{
        'hasData': true,
        'day': '2026-09-23',
        'offsetMinutes': 0,
        'consumed': 180,
        'goal': 2000,
      };

      expect(CalorieWidgetWater.fromJson(old['water']), isNull);
      expect(CalorieWidgetMacros.fromJson(old['macros']), isNull);
    });
  });

  group('CalorieWidgetSnapshot logical day', () {
    test('a 04:00 boundary files 01:00 under the previous day', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 100,
        goalKcal: 2000,
        offsetMinutes: 4 * 60,
        now: DateTime(2026, 9, 23, 1, 0),
      );

      expect(snapshot.dayId, '2026-09-22');
      expect(snapshot.isCurrentAt(DateTime(2026, 9, 23, 2, 0)), isTrue);
      expect(snapshot.isCurrentAt(DateTime(2026, 9, 23, 5, 0)), isFalse);
    });

    test('the next boundary is the following day at the offset', () {
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 100,
        goalKcal: 2000,
        offsetMinutes: 4 * 60,
        now: DateTime(2026, 9, 23, 1, 0),
      );

      expect(snapshot.nextBoundary(), DateTime(2026, 9, 23, 4, 0));
    });

    test('isCurrentAt follows DayBoundaryCalc for the stored offset', () {
      final now = DateTime(2026, 9, 23, 18, 30);
      final snapshot = CalorieWidgetSnapshot.fromHome(
        consumedKcal: 500,
        goalKcal: 2200,
        offsetMinutes: 0,
        now: now,
      );
      final logical = DayBoundaryCalc.logicalDayOfMinutes(now, 0);

      expect(snapshot.dayId, CalorieWidgetSnapshot.formatDayId(logical));
      expect(snapshot.isCurrentAt(now), isTrue);
      expect(snapshot.isCurrentAt(DateTime(2026, 9, 24, 0, 5)), isFalse);
    });
  });
}
