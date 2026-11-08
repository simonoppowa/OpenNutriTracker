import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/meal_pattern_entity.dart';
import 'package:opennutritracker/core/utils/meal_type_suggester.dart';

// Lock the time-of-day → meal-type ranges so a future tweak to the mapping
// trips a failing test instead of silently changing the default. The named
// hours in the boundary tests are the interesting ones: exactly on a range
// edge, and one hour on either side.
void main() {
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(2026, 6, 15, hour, minute);

  group('MealTypeSuggester.suggestFromTime', () {
    test('breakfast covers 04:00 through 10:59', () {
      expect(MealTypeSuggester.suggestFromTime(at(4)),
          IntakeTypeEntity.breakfast);
      expect(MealTypeSuggester.suggestFromTime(at(7)),
          IntakeTypeEntity.breakfast);
      expect(MealTypeSuggester.suggestFromTime(at(10, 59)),
          IntakeTypeEntity.breakfast);
    });

    test('lunch covers 11:00 through 14:59', () {
      expect(
          MealTypeSuggester.suggestFromTime(at(11)), IntakeTypeEntity.lunch);
      expect(MealTypeSuggester.suggestFromTime(at(13, 30)),
          IntakeTypeEntity.lunch);
      expect(MealTypeSuggester.suggestFromTime(at(14, 59)),
          IntakeTypeEntity.lunch);
    });

    test('afternoon 15:00 through 16:59 falls back to snack', () {
      expect(
          MealTypeSuggester.suggestFromTime(at(15)), IntakeTypeEntity.snack);
      expect(MealTypeSuggester.suggestFromTime(at(16, 59)),
          IntakeTypeEntity.snack);
    });

    test('dinner covers 17:00 through 21:59', () {
      expect(
          MealTypeSuggester.suggestFromTime(at(17)), IntakeTypeEntity.dinner);
      expect(MealTypeSuggester.suggestFromTime(at(19, 30)),
          IntakeTypeEntity.dinner);
      expect(MealTypeSuggester.suggestFromTime(at(21, 59)),
          IntakeTypeEntity.dinner);
    });

    test('late night 22:00 through 03:59 falls back to snack', () {
      expect(
          MealTypeSuggester.suggestFromTime(at(22)), IntakeTypeEntity.snack);
      expect(
          MealTypeSuggester.suggestFromTime(at(23, 59)), IntakeTypeEntity.snack);
      expect(MealTypeSuggester.suggestFromTime(at(0)), IntakeTypeEntity.snack);
      expect(
          MealTypeSuggester.suggestFromTime(at(3, 59)), IntakeTypeEntity.snack);
    });

    test('exact range boundaries are deterministic', () {
      // 04:00 → breakfast (not snack)
      expect(MealTypeSuggester.suggestFromTime(at(4)),
          IntakeTypeEntity.breakfast);
      // 11:00 → lunch (not breakfast)
      expect(
          MealTypeSuggester.suggestFromTime(at(11)), IntakeTypeEntity.lunch);
      // 15:00 → snack (not lunch)
      expect(
          MealTypeSuggester.suggestFromTime(at(15)), IntakeTypeEntity.snack);
      // 17:00 → dinner (not snack)
      expect(
          MealTypeSuggester.suggestFromTime(at(17)), IntakeTypeEntity.dinner);
      // 22:00 → snack (not dinner)
      expect(
          MealTypeSuggester.suggestFromTime(at(22)), IntakeTypeEntity.snack);
    });
  });

  // #1305: a meal at a 0 % share has no section on Home or in the Diary
  // unless something is logged in it, so the suggestion must not steer food
  // into it. It moves to the enabled meal whose time window is nearest.
  group('MealTypeSuggester.suggestFromTime with meal shares', () {
    IntakeTypeEntity suggest(DateTime now, Map<String, int> shares) =>
        MealTypeSuggester.suggestFromTime(now, mealSharesPct: shares);

    Map<String, int> shares({
      int breakfast = 30,
      int lunch = 40,
      int dinner = 20,
      int snack = 10,
    }) =>
        {
          ConfigEntity.mealKeyBreakfast: breakfast,
          ConfigEntity.mealKeyLunch: lunch,
          ConfigEntity.mealKeyDinner: dinner,
          ConfigEntity.mealKeySnack: snack,
        };

    test('every share above 0 keeps the time-of-day mapping', () {
      for (var hour = 0; hour < 24; hour++) {
        expect(
          suggest(at(hour, 30), shares()),
          MealTypeSuggester.suggestFromTime(at(hour, 30)),
          reason: 'hour $hour',
        );
      }
    });

    test('OMAD suggests dinner at any hour', () {
      final omad = MealPatternEntity.omad.toSharesMap();
      for (var hour = 0; hour < 24; hour++) {
        expect(suggest(at(hour), omad), IntakeTypeEntity.dinner,
            reason: 'hour $hour');
      }
    });

    test('two-meal splits the lunch window between its neighbours', () {
      final twoMeal = MealPatternEntity.twoMeal.toSharesMap();
      // Lunch runs 11:00–14:59; breakfast ends at 10:59, snack starts at 15:00.
      expect(suggest(at(11), twoMeal), IntakeTypeEntity.breakfast);
      expect(suggest(at(12, 59), twoMeal), IntakeTypeEntity.breakfast);
      expect(suggest(at(13), twoMeal), IntakeTypeEntity.snack);
      expect(suggest(at(14, 59), twoMeal), IntakeTypeEntity.snack);
      // Outside the lunch window nothing changes.
      expect(suggest(at(7), twoMeal), IntakeTypeEntity.breakfast);
      expect(suggest(at(19), twoMeal), IntakeTypeEntity.dinner);
    });

    test('a disabled breakfast moves to the nearer of snack and lunch', () {
      final noBreakfast = shares(breakfast: 0);
      // Night snack ends at 03:59, lunch starts at 11:00.
      expect(suggest(at(5), noBreakfast), IntakeTypeEntity.snack);
      expect(suggest(at(9), noBreakfast), IntakeTypeEntity.lunch);
    });

    test('a disabled snack wraps across midnight to the nearest meal', () {
      final noSnack = shares(snack: 0);
      // Dinner ends at 21:59, breakfast starts at 04:00.
      expect(suggest(at(23), noSnack), IntakeTypeEntity.dinner);
      expect(suggest(at(3), noSnack), IntakeTypeEntity.breakfast);
      // Afternoon snack (15:00–16:59): lunch ends 14:59, dinner starts 17:00.
      expect(suggest(at(15, 30), noSnack), IntakeTypeEntity.lunch);
      expect(suggest(at(16, 30), noSnack), IntakeTypeEntity.dinner);
    });

    test('all shares at 0 falls back to the time-of-day mapping', () {
      final none = shares(breakfast: 0, lunch: 0, dinner: 0, snack: 0);
      expect(suggest(at(7), none), IntakeTypeEntity.breakfast);
      expect(suggest(at(12), none), IntakeTypeEntity.lunch);
      expect(suggest(at(19), none), IntakeTypeEntity.dinner);
      expect(suggest(at(23), none), IntakeTypeEntity.snack);
    });

    test('a missing share counts as 0, matching the Home and Diary sections',
        () {
      final partial = {ConfigEntity.mealKeyDinner: 100};
      expect(suggest(at(7), partial), IntakeTypeEntity.dinner);
      expect(suggest(at(7), const {}), IntakeTypeEntity.breakfast);
    });
  });
}
