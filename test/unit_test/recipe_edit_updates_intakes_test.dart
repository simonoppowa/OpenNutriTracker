import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

MealEntity _recipeMeal({
  required String code,
  required String name,
  double kcal = 200,
}) {
  return MealEntity(
    code: code,
    name: name,
    url: null,
    mealQuantity: '100',
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: null,
    servingSize: null,
    nutriments: MealNutrimentsEntity(
      energyKcal100: kcal,
      carbohydrates100: 20,
      fat100: 10,
      proteins100: 5,
      sugars100: 5,
      saturatedFat100: 3,
      fiber100: 2,
    ),
    source: MealSourceEntity.recipe,
  );
}

void main() {
  group('remapRecipeOnIntakes', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.init(".");
      registerHiveAdaptersOnce();
    });

    tearDown(() {
      Hive.deleteFromDisk();
    });

    test(
      'updates recipe-sourced intakes and leaves others untouched',
      () async {
        final box = await Hive.openBox<IntakeDBO>('intake_remap_test');
        final ds = IntakeDataSource(FakeHiveDBProvider(intakeBox: box));
        final repo = IntakeRepository(ds);

        final oldRecipeMeal = _recipeMeal(
          code: 'recipe-abc',
          name: 'Old Oatmeal',
          kcal: 200,
        );
        final customMeal = MealEntity(
          code: 'recipe-abc',
          name: 'Same code but custom',
          url: null,
          mealQuantity: null,
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: null,
          servingSize: null,
          nutriments: MealNutrimentsEntity.empty(),
          source: MealSourceEntity.custom,
        );

        await repo.addIntake(
          IntakeEntity(
            id: '1',
            unit: 'g',
            amount: 100,
            type: IntakeTypeEntity.breakfast,
            meal: oldRecipeMeal,
            dateTime: DateTime.utc(2026, 9, 1),
          ),
        );
        await repo.addIntake(
          IntakeEntity(
            id: '2',
            unit: 'g',
            amount: 50,
            type: IntakeTypeEntity.lunch,
            meal: oldRecipeMeal,
            dateTime: DateTime.utc(2026, 9, 2),
          ),
        );
        // Same code but custom source — must NOT be touched.
        await repo.addIntake(
          IntakeEntity(
            id: '3',
            unit: 'g',
            amount: 75,
            type: IntakeTypeEntity.dinner,
            meal: customMeal,
            dateTime: DateTime.utc(2026, 9, 3),
          ),
        );

        final updatedMeal = _recipeMeal(
          code: 'recipe-abc',
          name: 'Updated Oatmeal',
          kcal: 300,
        );
        final newMealDBO = MealDBO.fromMealEntity(updatedMeal);

        final rewrites = await repo.remapRecipeOnIntakes(
          recipeId: 'recipe-abc',
          toMeal: newMealDBO,
        );

        expect(rewrites.length, 2);
        expect(rewrites[0].$1.meal.name, 'Old Oatmeal');
        expect(rewrites[0].$2.meal.name, 'Updated Oatmeal');
        expect(rewrites[1].$1.id, '2');
        expect(rewrites[1].$2.meal.name, 'Updated Oatmeal');

        // Verify the box was actually updated.
        final recent = await repo.getRecentIntake();
        final recipeIntakes = recent
            .where((i) => i.meal.source == MealSourceEntity.recipe)
            .toList();
        for (final intake in recipeIntakes) {
          expect(intake.meal.name, 'Updated Oatmeal');
        }

        // Custom-source intake untouched.
        final customIntakes = recent
            .where((i) => i.meal.source == MealSourceEntity.custom)
            .toList();
        expect(customIntakes.length, 1);
        expect(customIntakes.first.meal.name, 'Same code but custom');
      },
    );
  });
}
