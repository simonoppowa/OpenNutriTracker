import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/json_meal_importer.dart';

void main() {
  group('JsonMealImporter.parse', () {
    final fixedNow = DateTime(2026, 5, 13);

    test('parses a single valid object and writes one intake', () {
      const json = '{"name":"Apple","kcal":95,"protein":0.5,"carbs":25,'
          '"fat":0.3,"mealType":"snack","amount":100,"unit":"g",'
          '"date":"2026-05-13"}';

      final result = JsonMealImporter.parse(json, now: fixedNow);

      expect(result.errors, isEmpty);
      expect(result.intakes, hasLength(1));
      final intake = result.intakes.single;
      expect(intake.meal.name, 'Apple');
      expect(intake.amount, 100);
      expect(intake.unit, 'g');
      expect(intake.type, IntakeTypeEntity.snack);
      expect(intake.dateTime, DateTime(2026, 5, 13));
      // Back-projection: 95 kcal in 100 g = 95 per 100 g.
      expect(intake.meal.nutriments.energyKcal100, closeTo(95, 0.001));
      expect(intake.totalKcal, closeTo(95, 0.001));
      expect(intake.totalCarbsGram, closeTo(25, 0.001));
      expect(intake.totalFatsGram, closeTo(0.3, 0.001));
      expect(intake.totalProteinsGram, closeTo(0.5, 0.001));
    });

    test('parses an array of three entries', () {
      const json = '['
          '{"name":"Oats","kcal":150,"protein":5,"carbs":27,"fat":2.5,'
          '"mealType":"breakfast","amount":40,"unit":"g"},'
          '{"name":"Banana","kcal":105,"protein":1.3,"carbs":27,"fat":0.4,'
          '"mealType":"snack","amount":120,"unit":"g"},'
          '{"name":"Chicken","kcal":165,"protein":31,"carbs":0,"fat":3.6,'
          '"mealType":"dinner","amount":100,"unit":"g"}'
          ']';

      final result = JsonMealImporter.parse(json, now: fixedNow);

      expect(result.errors, isEmpty);
      expect(result.intakes, hasLength(3));
      expect(result.intakes[0].meal.name, 'Oats');
      expect(result.intakes[0].type, IntakeTypeEntity.breakfast);
      expect(result.intakes[1].meal.name, 'Banana');
      expect(result.intakes[1].type, IntakeTypeEntity.snack);
      expect(result.intakes[2].meal.name, 'Chicken');
      expect(result.intakes[2].type, IntakeTypeEntity.dinner);
    });

    test('malformed JSON surfaces a parse error and no intakes', () {
      const json = '{"name":"Apple", "kcal":';

      final result = JsonMealImporter.parse(json, now: fixedNow);

      expect(result.intakes, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.single, startsWith('Could not parse:'));
    });

    test('missing required field surfaces a per-entry error', () {
      // No "name" key.
      const json = '{"kcal":95,"protein":0.5,"carbs":25,"fat":0.3}';

      final result = JsonMealImporter.parse(json, now: fixedNow);

      expect(result.intakes, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.single, contains('missing required field'));
      expect(result.errors.single, contains('name'));
    });

    test('defaults: mealType snack, amount 100, unit g, date today', () {
      const json = '{"name":"Apple","kcal":52,"protein":0.3,"carbs":14,"fat":0.2}';

      final result = JsonMealImporter.parse(json, now: fixedNow);

      expect(result.errors, isEmpty);
      final intake = result.intakes.single;
      expect(intake.type, IntakeTypeEntity.snack);
      expect(intake.amount, 100);
      expect(intake.unit, 'g');
      expect(intake.dateTime, DateTime(2026, 5, 13));
    });

    test('rejects an unknown mealType with a clear message', () {
      const json =
          '{"name":"Apple","kcal":52,"protein":0.3,"carbs":14,"fat":0.2,'
          '"mealType":"brunch"}';

      final result = JsonMealImporter.parse(json, now: fixedNow);

      expect(result.intakes, isEmpty);
      expect(result.errors.single, contains('mealType'));
      expect(result.errors.single, contains('brunch'));
    });

    test('rejects a non-positive amount', () {
      const json = '{"name":"Apple","kcal":52,"protein":0.3,"carbs":14,'
          '"fat":0.2,"amount":0}';

      final result = JsonMealImporter.parse(json, now: fixedNow);

      expect(result.intakes, isEmpty);
      expect(result.errors.single, contains('amount'));
    });

    test('rejects a malformed date string', () {
      const json = '{"name":"Apple","kcal":52,"protein":0.3,"carbs":14,'
          '"fat":0.2,"date":"yesterday"}';

      final result = JsonMealImporter.parse(json, now: fixedNow);

      expect(result.intakes, isEmpty);
      expect(result.errors.single, contains('date'));
    });

    test('empty input is reported, not silently treated as zero entries', () {
      final result = JsonMealImporter.parse('   ', now: fixedNow);

      expect(result.intakes, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.single, contains('empty'));
    });

    test('top-level non-object, non-array JSON is reported', () {
      final result = JsonMealImporter.parse('42', now: fixedNow);

      expect(result.intakes, isEmpty);
      expect(result.errors.single, contains('object or an array'));
    });

    test('amount > 100 back-projects nutriments to per-100[unit]', () {
      // 200 kcal at 200 g amount = 100 kcal / 100 g, doubled to land
      // back at 200 kcal for the logged entry.
      const json = '{"name":"Yoghurt","kcal":200,"protein":10,"carbs":20,'
          '"fat":8,"amount":200,"unit":"g"}';

      final result = JsonMealImporter.parse(json, now: fixedNow);

      expect(result.errors, isEmpty);
      final intake = result.intakes.single;
      expect(intake.meal.nutriments.energyKcal100, closeTo(100, 0.001));
      expect(intake.totalKcal, closeTo(200, 0.001));
      expect(intake.totalProteinsGram, closeTo(10, 0.001));
    });
  });

  group('JsonMealImporter.sampleJson', () {
    test('parses cleanly with no errors and produces real intakes', () {
      final result = JsonMealImporter.parse(
        JsonMealImporter.sampleJson(),
        now: DateTime(2026, 5, 13),
      );
      expect(result.errors, isEmpty,
          reason: 'the bundled sample must always be parseable');
      expect(result.intakes, isNotEmpty);
      // Each entry's stored MealEntity should at least have a name.
      for (final intake in result.intakes) {
        expect(intake.meal.name, isNotNull);
        expect(intake.meal.name, isNotEmpty);
      }
    });
  });
}
