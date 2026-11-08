import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../helpers/fake_hive_db_provider.dart';

class _StubIntakeRepository extends IntakeRepository {
  _StubIntakeRepository(this._intakes)
    : super(IntakeDataSource(FakeHiveDBProvider()));

  final List<IntakeDBO> _intakes;

  @override
  Future<List<IntakeDBO>> getAllIntakesDBO() async => _intakes;
}

MealEntity _meal(String name, double kcal) => MealEntity(
  code: null,
  name: name,
  url: null,
  mealQuantity: '100',
  mealUnit: 'ml',
  servingQuantity: 100,
  servingUnit: 'ml',
  servingSize: '',
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal,
    carbohydrates100: 0,
    fat100: 0,
    proteins100: 0,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
);

IntakeDBO _intake(String id, MealEntity meal, DateTime at) => IntakeDBO(
  id: id,
  unit: 'ml',
  amount: 250,
  type: IntakeTypeDBO.snack,
  meal: MealDBO.fromMealEntity(meal),
  dateTime: at,
);

GetIntakeUsecase _usecase(List<IntakeDBO> intakes) => GetIntakeUsecase(
  _StubIntakeRepository(intakes),
  RecipeRepository(RecipeDataSource(FakeHiveDBProvider())),
);

void main() {
  // The Diary calendar marks the days these keys name (#1440), so they
  // follow what was logged and the day boundary, not any row's totals.
  group('getDayKeysWithIntakes', () {
    final coffee = _intake(
      'coffee',
      _meal('Black coffee', 0),
      DateTime(2026, 8, 20, 23, 30),
    );
    final toast = _intake(
      'toast',
      _meal('Toast', 260),
      DateTime(2026, 8, 21, 2),
    );

    test('a zero-calorie entry still names its day', () async {
      final keys = await _usecase([coffee]).getDayKeysWithIntakes(0);

      expect(keys, {'2026-08-20'});
    });

    test('entries are keyed by the day the boundary lists them on', () async {
      final usecase = _usecase([coffee, toast]);

      expect(await usecase.getDayKeysWithIntakes(0), {
        '2026-08-20',
        '2026-08-21',
      });
      // A 03:00 boundary lists the 02:00 toast on the day before.
      expect(await usecase.getDayKeysWithIntakes(180), {'2026-08-20'});
    });

    test('no entries name no days', () async {
      expect(await _usecase([]).getDayKeysWithIntakes(0), isEmpty);
    });
  });
}
