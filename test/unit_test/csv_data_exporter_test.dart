import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';

void main() {
  group('CsvDataExporter intake round-trip', () {
    test('a full-featured intake row survives a CSV round-trip', () {
      final original = _intake(
        id: 'intake-1',
        type: IntakeTypeDBO.breakfast,
        unit: 'g',
        amount: 120.5,
        when: DateTime.utc(2026, 5, 13, 8, 15),
        meal: _meal(
          code: '1234567890123',
          name: 'Whole Milk 3.25%',
          brands: 'Acme Dairy',
          source: MealSourceDBO.off,
          servingQuantity: 250,
          servingUnit: 'ml',
          servingSize: '250 ml',
          nutriments: _nutriments(kcal: 61, carbs: 4.8, fat: 3.3, protein: 3.2),
        ),
      );

      final csv = CsvDataExporter.intakesToCsv([original]);
      final parsed = CsvDataExporter.parseIntakesFromCsv(csv);

      expect(parsed, hasLength(1));
      _expectIntakeEqual(parsed.single, original);
    });

    test('multiple intakes round-trip in order', () {
      final intakes = [
        _intake(
          id: 'a',
          when: DateTime.utc(2026, 5, 10, 8),
          meal: _meal(name: 'Apple', nutriments: _nutriments(kcal: 52)),
        ),
        _intake(
          id: 'b',
          type: IntakeTypeDBO.lunch,
          when: DateTime.utc(2026, 5, 10, 12, 30),
          meal: _meal(name: 'Banana', nutriments: _nutriments(kcal: 89)),
        ),
        _intake(
          id: 'c',
          type: IntakeTypeDBO.dinner,
          when: DateTime.utc(2026, 5, 10, 19),
          meal: _meal(
            // Names with commas exercise the quote-on-write path. If we
            // got that wrong, the round-trip would over-split.
            name: 'Granola, oats and nuts',
            nutriments: _nutriments(kcal: 450),
          ),
        ),
      ];

      final csv = CsvDataExporter.intakesToCsv(intakes);
      final parsed = CsvDataExporter.parseIntakesFromCsv(csv);

      expect(parsed.map((i) => i.id).toList(), ['a', 'b', 'c']);
      expect(parsed[2].meal.name, 'Granola, oats and nuts');
    });

    test('nullable nutriments stay null after round-trip', () {
      final intake = _intake(
        meal: _meal(
          name: 'Sparse meal',
          // Only kcal present; everything else null.
          nutriments: MealNutrimentsDBO(
            energyKcal100: 100,
            carbohydrates100: null,
            fat100: null,
            proteins100: null,
            sugars100: null,
            saturatedFat100: null,
            fiber100: null,
          ),
        ),
      );

      final csv = CsvDataExporter.intakesToCsv([intake]);
      final parsed = CsvDataExporter.parseIntakesFromCsv(csv).single;

      expect(parsed.meal.nutriments.energyKcal100, 100);
      expect(parsed.meal.nutriments.carbohydrates100, isNull);
      expect(parsed.meal.nutriments.fat100, isNull);
      expect(parsed.meal.nutriments.proteins100, isNull);
      expect(parsed.meal.nutriments.iron100, isNull);
    });

    test('exported CSV starts with the documented header row', () {
      final csv = CsvDataExporter.intakesToCsv([]);
      final header = csv.split('\n').first;
      expect(header, CsvDataExporter.intakeColumns.join(','));
    });
  });

  group('CsvDataExporter user-activity round-trip', () {
    test('a full activity row survives a CSV round-trip including tags', () {
      final activity = UserActivityDBO(
        'act-1',
        45,
        320.5,
        DateTime.utc(2026, 5, 13, 18),
        PhysicalActivityDBO(
          '01010',
          'Running, 8 km/h',
          'Running, 8 km/h (7.5 min/km)',
          8.3,
          const ['cardio', 'outdoor'],
          PhysicalActivityTypeDBO.running,
        ),
      );

      final csv = CsvDataExporter.userActivitiesToCsv([activity]);
      final parsed =
          CsvDataExporter.parseUserActivitiesFromCsv(csv).single;

      expect(parsed.id, 'act-1');
      expect(parsed.duration, 45);
      expect(parsed.burnedKcal, 320.5);
      expect(parsed.date, activity.date);
      expect(parsed.physicalActivityDBO.code, '01010');
      // The specific-activity contains a comma, so the export must quote
      // it; if it didn't, this assertion would catch the over-split.
      expect(parsed.physicalActivityDBO.specificActivity, 'Running, 8 km/h');
      expect(parsed.physicalActivityDBO.mets, 8.3);
      expect(parsed.physicalActivityDBO.tags, ['cardio', 'outdoor']);
      expect(
        parsed.physicalActivityDBO.type,
        PhysicalActivityTypeDBO.running,
      );
    });

    test('an activity with no tags round-trips to an empty list', () {
      final activity = UserActivityDBO(
        'act-2',
        20,
        100,
        DateTime.utc(2026, 5, 13, 7),
        PhysicalActivityDBO(
          '02020',
          'Walking',
          'Walking, leisure',
          3.5,
          const [],
          PhysicalActivityTypeDBO.sport,
        ),
      );

      final csv = CsvDataExporter.userActivitiesToCsv([activity]);
      final parsed =
          CsvDataExporter.parseUserActivitiesFromCsv(csv).single;

      expect(parsed.physicalActivityDBO.tags, isEmpty);
    });
  });

  group('CsvDataExporter tracked-day round-trip', () {
    test('a full tracked-day row survives a CSV round-trip', () {
      final day = TrackedDayDBO(
        day: DateTime.utc(2026, 5, 13),
        calorieGoal: 2200,
        caloriesTracked: 1850.25,
        carbsGoal: 330,
        carbsTracked: 270,
        fatGoal: 61.5,
        fatTracked: 55,
        proteinGoal: 110,
        proteinTracked: 95.75,
      );

      final csv = CsvDataExporter.trackedDaysToCsv([day]);
      final parsed = CsvDataExporter.parseTrackedDaysFromCsv(csv).single;

      expect(parsed.day, day.day);
      expect(parsed.calorieGoal, 2200);
      expect(parsed.caloriesTracked, 1850.25);
      expect(parsed.carbsGoal, 330);
      expect(parsed.carbsTracked, 270);
      expect(parsed.fatGoal, 61.5);
      expect(parsed.fatTracked, 55);
      expect(parsed.proteinGoal, 110);
      expect(parsed.proteinTracked, 95.75);
    });

    test('null macro fields stay null after round-trip', () {
      final day = TrackedDayDBO(
        day: DateTime.utc(2026, 5, 14),
        calorieGoal: 2000,
        caloriesTracked: 1500,
      );

      final csv = CsvDataExporter.trackedDaysToCsv([day]);
      final parsed = CsvDataExporter.parseTrackedDaysFromCsv(csv).single;

      expect(parsed.carbsGoal, isNull);
      expect(parsed.carbsTracked, isNull);
      expect(parsed.fatGoal, isNull);
      expect(parsed.fatTracked, isNull);
      expect(parsed.proteinGoal, isNull);
      expect(parsed.proteinTracked, isNull);
    });
  });
}

// --- Fixtures --------------------------------------------------------------

IntakeDBO _intake({
  String id = 'intake-x',
  IntakeTypeDBO type = IntakeTypeDBO.snack,
  String unit = 'g',
  double amount = 100,
  DateTime? when,
  MealDBO? meal,
}) {
  return IntakeDBO(
    id: id,
    unit: unit,
    amount: amount,
    type: type,
    meal: meal ?? _meal(),
    dateTime: when ?? DateTime.utc(2026, 1, 1),
  );
}

MealDBO _meal({
  String? code,
  String? name = 'Sample meal',
  String? brands,
  MealSourceDBO source = MealSourceDBO.custom,
  String? mealQuantity = '100',
  String? mealUnit = 'g',
  double? servingQuantity,
  String? servingUnit,
  String? servingSize,
  MealNutrimentsDBO? nutriments,
}) {
  return MealDBO(
    code: code,
    name: name,
    brands: brands,
    thumbnailImageUrl: null,
    mainImageUrl: null,
    url: null,
    mealQuantity: mealQuantity,
    mealUnit: mealUnit,
    servingQuantity: servingQuantity,
    servingUnit: servingUnit,
    servingSize: servingSize,
    source: source,
    nutriments: nutriments ?? _nutriments(),
  );
}

MealNutrimentsDBO _nutriments({
  double? kcal = 100,
  double? carbs,
  double? fat,
  double? protein,
}) {
  return MealNutrimentsDBO(
    energyKcal100: kcal,
    carbohydrates100: carbs,
    fat100: fat,
    proteins100: protein,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  );
}

void _expectIntakeEqual(IntakeDBO actual, IntakeDBO expected) {
  expect(actual.id, expected.id);
  expect(actual.unit, expected.unit);
  expect(actual.amount, expected.amount);
  expect(actual.type, expected.type);
  expect(actual.dateTime, expected.dateTime);
  expect(actual.meal.code, expected.meal.code);
  expect(actual.meal.name, expected.meal.name);
  expect(actual.meal.brands, expected.meal.brands);
  expect(actual.meal.source, expected.meal.source);
  expect(actual.meal.mealQuantity, expected.meal.mealQuantity);
  expect(actual.meal.mealUnit, expected.meal.mealUnit);
  expect(actual.meal.servingQuantity, expected.meal.servingQuantity);
  expect(actual.meal.servingUnit, expected.meal.servingUnit);
  expect(actual.meal.servingSize, expected.meal.servingSize);
  expect(actual.meal.nutriments.energyKcal100,
      expected.meal.nutriments.energyKcal100);
  expect(actual.meal.nutriments.carbohydrates100,
      expected.meal.nutriments.carbohydrates100);
  expect(actual.meal.nutriments.fat100, expected.meal.nutriments.fat100);
  expect(actual.meal.nutriments.proteins100,
      expected.meal.nutriments.proteins100);
}
