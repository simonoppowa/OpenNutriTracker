import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../fixture/meal_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// #1276: an intake stores a snapshot of the meal it logged, and Recents is
/// built from those snapshots — so after a recipe was edited, Recents kept
/// showing and logging the old name, nutrition and servings.
void main() {
  late IntakeRepository intakeRepo;
  late RecipeRepository recipeRepo;
  late GetIntakeUsecase usecase;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    registerHiveAdaptersOnce();
    final provider = FakeHiveDBProvider(
      intakeBox: await Hive.openBox<IntakeDBO>('recent_refresh_intake'),
      recipeBox: await Hive.openBox<RecipeDBO>('recent_refresh_recipe'),
    );
    intakeRepo = IntakeRepository(IntakeDataSource(provider));
    recipeRepo = RecipeRepository(RecipeDataSource(provider));
    usecase = GetIntakeUsecase(intakeRepo, recipeRepo);
  });

  tearDown(() async => Hive.deleteFromDisk());

  RecipeEntity soup({
    String name = 'Soup',
    double kcal = 90,
    int? servingsCount = 4,
  }) {
    return RecipeEntity(
      id: 'soup-1',
      name: name,
      description: null,
      ingredients: const [],
      totalWeightG: 800,
      aggregatedNutrimentsPer100: MealNutrimentsEntity(
        energyKcal100: kcal,
        carbohydrates100: null,
        fat100: null,
        proteins100: null,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
      servingsCount: servingsCount,
    );
  }

  Future<void> log(String id, MealEntity meal, {String unit = 'g'}) =>
      intakeRepo.addIntake(
        IntakeEntity(
          id: id,
          unit: unit,
          amount: 250,
          type: IntakeTypeEntity.lunch,
          meal: meal,
          dateTime: DateTime(2026, 9, 20, 12),
        ),
      );

  test('an edited recipe shows up in Recents as it is now', () async {
    await recipeRepo.saveRecipe(soup());
    await log('lunch', soup().toMealEntity());

    await recipeRepo.saveRecipe(
      soup(name: 'Tomato soup', kcal: 120, servingsCount: 2),
    );

    final recent = await usecase.getRecentIntake();
    final meal = recent.single.meal;
    expect(meal.name, 'Tomato soup');
    expect(meal.nutriments.energyKcal100, 120);
    expect(meal.servingQuantity, 400);
    // The intake itself is untouched; only the meal it offers to re-log is.
    expect(recent.single.id, 'lunch');
    expect(recent.single.amount, 250);
  });

  test('the logged entry keeps the snapshot it was logged with', () async {
    await recipeRepo.saveRecipe(soup());
    await log('lunch', soup().toMealEntity());
    await recipeRepo.saveRecipe(soup(name: 'Tomato soup', kcal: 120));

    // History is a record of what was eaten, so it must not follow edits.
    final logged = await intakeRepo.getIntakeById('lunch');
    expect(logged!.meal.name, 'Soup');
    expect(logged.meal.nutriments.energyKcal100, 90);
  });

  test('a deleted recipe still offers its last snapshot', () async {
    await recipeRepo.saveRecipe(soup());
    await log('lunch', soup().toMealEntity());
    await recipeRepo.deleteRecipe('soup-1');

    final recent = await usecase.getRecentIntake();
    expect(recent.single.meal.name, 'Soup');
  });

  test('foods that are not recipes pass through unchanged', () async {
    await log('breakfast', MealEntityFixtures.mealOne);

    final recent = await usecase.getRecentIntake();
    expect(recent.single.meal.code, MealEntityFixtures.mealOne.code);
    expect(recent.single.meal.name, MealEntityFixtures.mealOne.name);
  });
}
