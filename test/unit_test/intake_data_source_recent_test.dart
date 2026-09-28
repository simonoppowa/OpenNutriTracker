import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

MealDBO _meal({required String code, required MealSourceDBO source}) => MealDBO(
  code: code,
  name: code,
  brands: null,
  thumbnailImageUrl: null,
  mainImageUrl: null,
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsDBO(
    energyKcal100: 100,
    carbohydrates100: 10,
    fat100: 2,
    proteins100: 5,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: source,
);

IntakeDBO _intake(String id, MealDBO meal, DateTime at) => IntakeDBO(
  id: id,
  unit: 'g',
  amount: 100,
  type: IntakeTypeDBO.lunch,
  meal: meal,
  dateTime: at,
);

void main() {
  group('IntakeDataSource.getRecentlyAddedIntake', () {
    late Box<IntakeDBO> box;
    late IntakeDataSource dataSource;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      box = await Hive.openBox<IntakeDBO>(
        'recent_intake_${DateTime.now().microsecondsSinceEpoch}',
      );
      dataSource = IntakeDataSource(FakeHiveDBProvider(intakeBox: box));
    });

    tearDown(() async {
      await box.deleteFromDisk();
    });

    test('orders entries newest first regardless of meal source', () async {
      await box.addAll([
        _intake(
          'old-custom',
          _meal(code: 'c1', source: MealSourceDBO.custom),
          DateTime.utc(2025, 1, 1),
        ),
        _intake(
          'new-off',
          _meal(code: 'o1', source: MealSourceDBO.off),
          DateTime.utc(2025, 1, 3),
        ),
        _intake(
          'mid-off',
          _meal(code: 'o2', source: MealSourceDBO.off),
          DateTime.utc(2025, 1, 2),
        ),
      ]);

      final recent = await dataSource.getRecentlyAddedIntake();

      expect(recent.map((i) => i.id), ['new-off', 'mid-off', 'old-custom']);
    });

    test('keeps only the latest entry per meal', () async {
      final meal = _meal(code: 'c1', source: MealSourceDBO.custom);
      await box.addAll([
        _intake('first', meal, DateTime.utc(2025, 1, 1)),
        _intake('second', meal, DateTime.utc(2025, 1, 2)),
      ]);

      final recent = await dataSource.getRecentlyAddedIntake();

      expect(recent.map((i) => i.id), ['second']);
    });

    test('respects the number limit after ordering', () async {
      await box.addAll([
        _intake(
          'a',
          _meal(code: 'a', source: MealSourceDBO.off),
          DateTime.utc(2025, 1, 1),
        ),
        _intake(
          'b',
          _meal(code: 'b', source: MealSourceDBO.custom),
          DateTime.utc(2025, 1, 2),
        ),
        _intake(
          'c',
          _meal(code: 'c', source: MealSourceDBO.off),
          DateTime.utc(2025, 1, 3),
        ),
      ]);

      final recent = await dataSource.getRecentlyAddedIntake(number: 2);

      expect(recent.map((i) => i.id), ['c', 'b']);
    });
  });
}
