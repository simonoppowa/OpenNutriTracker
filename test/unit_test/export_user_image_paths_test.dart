import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';

/// Which user photos belong in a JSON bundle (#1061).
///
/// Export used to gather meal photos from the custom-meal box alone. A meal
/// logged with *Save for next time* off writes no custom-meal record (#249)
/// but keeps `localImagePath` on the intake, so the JSON carried a reference
/// to `meal_images/<id>.webp` that the archive did not contain. Nothing
/// failed — the photo was simply gone after a restore, which is the worst
/// shape for a backup to fail in.
void main() {
  group('ExportDataUsecase.userImagePaths', () {
    // The regression. This is the only source that reaches a one-off entry.
    test('collects a photo that exists only on an intake', () {
      final paths = ExportDataUsecase.userImagePaths(
        recipes: const [],
        customMeals: const [],
        intakes: [_intake(imagePath: 'meal_images/one-off.webp')],
      );

      expect(paths, ['meal_images/one-off.webp']);
    });

    test('collects recipe and custom-meal photos as before', () {
      final paths = ExportDataUsecase.userImagePaths(
        recipes: [_recipe(imagePath: 'recipe_images/r.webp')],
        customMeals: [_meal(imagePath: 'meal_images/saved.webp')],
        intakes: const [],
      );

      expect(paths, ['recipe_images/r.webp', 'meal_images/saved.webp']);
    });

    // The ordinary case — a saved custom meal that has also been logged —
    // reaches this from two sources. Two archive entries under one name
    // would double the bundle for every photographed meal.
    test('a saved meal that was also logged is collected once', () {
      const shared = 'meal_images/saved.webp';
      final paths = ExportDataUsecase.userImagePaths(
        recipes: const [],
        customMeals: [_meal(imagePath: shared)],
        intakes: [_intake(imagePath: shared)],
      );

      expect(paths, [shared]);
    });

    test('two intakes of the same meal contribute one entry', () {
      const shared = 'meal_images/same.webp';
      final paths = ExportDataUsecase.userImagePaths(
        recipes: const [],
        customMeals: const [],
        intakes: [
          _intake(imagePath: shared),
          _intake(imagePath: shared),
        ],
      );

      expect(paths, [shared]);
    });

    test('meals and recipes without a photo contribute nothing', () {
      final paths = ExportDataUsecase.userImagePaths(
        recipes: [_recipe(imagePath: null)],
        customMeals: [_meal(imagePath: null)],
        intakes: [_intake(imagePath: null)],
      );

      expect(paths, isEmpty);
    });

    // `sanitizeRelative` is what keeps a crafted path from escaping the
    // documents directory on import. Filtering here rather than at the file
    // read keeps that single gate in front of every source.
    test('paths that are not a known image slug are dropped', () {
      final paths = ExportDataUsecase.userImagePaths(
        recipes: const [],
        customMeals: const [],
        intakes: [
          _intake(imagePath: '../../etc/passwd'),
          _intake(imagePath: 'meal_images/../../escape.webp'),
          _intake(imagePath: 'not_an_image_dir/x.webp'),
          _intake(imagePath: 'meal_images/'),
          _intake(imagePath: 'meal_images/ok.webp'),
        ],
      );

      expect(paths, ['meal_images/ok.webp']);
    });

    test('order is recipes, then custom meals, then intakes', () {
      final paths = ExportDataUsecase.userImagePaths(
        recipes: [_recipe(imagePath: 'recipe_images/r.webp')],
        customMeals: [_meal(imagePath: 'meal_images/m.webp')],
        intakes: [_intake(imagePath: 'meal_images/i.webp')],
      );

      expect(paths, [
        'recipe_images/r.webp',
        'meal_images/m.webp',
        'meal_images/i.webp',
      ]);
    });
  });
}

IntakeDBO _intake({required String? imagePath}) => IntakeDBO(
  id: 'intake-1',
  unit: 'g',
  amount: 100,
  type: IntakeTypeDBO.snack,
  meal: _meal(imagePath: imagePath),
  dateTime: DateTime.utc(2026, 1, 1),
);

MealDBO _meal({required String? imagePath}) => MealDBO(
  code: null,
  name: 'Sample meal',
  brands: null,
  thumbnailImageUrl: null,
  mainImageUrl: null,
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  source: MealSourceDBO.custom,
  nutriments: MealNutrimentsDBO(
    energyKcal100: 100,
    carbohydrates100: null,
    fat100: null,
    proteins100: null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  localImagePath: imagePath,
);

RecipeDBO _recipe({required String? imagePath}) => RecipeDBO(
  id: 'recipe-1',
  name: 'Sample recipe',
  description: null,
  ingredients: const [],
  totalWeightG: 100,
  aggregatedNutrimentsPer100: MealNutrimentsDBO(
    energyKcal100: 100,
    carbohydrates100: null,
    fat100: null,
    proteins100: null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  servingsCount: null,
  tags: null,
  imagePath: imagePath,
);
