import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
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
}
