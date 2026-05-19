import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/utils/shared_payload_router.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_activity_payload.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_meal_payload.dart';
import 'package:opennutritracker/features/recipes/domain/entity/shared_recipe_payload.dart';

MealEntity _meal(String code, String name) => MealEntity(
      code: code,
      name: name,
      brands: null,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom,
    );

IntakeEntity _intake(MealEntity meal) => IntakeEntity(
      id: 'intake_1',
      meal: meal,
      amount: 100,
      unit: 'g',
      dateTime: DateTime(2026, 4, 27),
      type: IntakeTypeEntity.breakfast,
    );

UserActivityEntity _activity(String code, double duration) => UserActivityEntity(
      'ua-$code',
      duration,
      duration * 5,
      DateTime(2026, 4, 27),
      PhysicalActivityEntity(
        code,
        'Activity $code',
        '',
        5.0,
        const <String>[],
        PhysicalActivityTypeEntity.conditioningExercise,
      ),
    );

RecipeEntity _recipe() {
  final flour = _meal('flour', 'Flour');
  return RecipeEntity(
    id: 'recipe-1',
    name: 'Plain Bread',
    description: null,
    ingredients: [
      RecipeIngredientEntity(
        snapshotMeal: flour,
        amount: 200,
        unit: 'g',
        convertedAmountG: 200,
      ),
    ],
    totalWeightG: 200,
    aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
    createdAt: DateTime.utc(2024, 1, 1),
    updatedAt: DateTime.utc(2024, 1, 2),
    servingsCount: 4,
  );
}

void main() {
  group('classifySharedPayload', () {
    test('classifies an encoded meal payload as meal', () {
      final code = SharedMealPayload.fromIntakeList(
        [_intake(_meal('custom-1', 'Homemade Soup'))],
      ).toJsonString();

      expect(classifySharedPayload(code), SharedPayloadKind.meal);
    });

    test('classifies an encoded activity payload as activity', () {
      final code = SharedActivityPayload.fromUserActivityList(
        [_activity('01010', 30)],
      ).toJsonString();

      expect(classifySharedPayload(code), SharedPayloadKind.activity);
    });

    test('classifies an encoded recipe payload as recipe', () {
      final code = SharedRecipePayload.fromRecipe(_recipe()).toJsonString();

      expect(classifySharedPayload(code), SharedPayloadKind.recipe);
    });

    test('returns null for an empty string', () {
      expect(classifySharedPayload(''), isNull);
    });

    test('returns null for a plain product barcode', () {
      // Real OFF barcode for Dr. Oetker Pizza — the standard scanner
      // should fall through to product lookup, not misroute it as a
      // shared payload.
      expect(classifySharedPayload('4001724039143'), isNull);
    });

    test('returns null for arbitrary text', () {
      expect(classifySharedPayload('hello world'), isNull);
      expect(classifySharedPayload('https://example.com'), isNull);
    });

    test('returns null for a JSON array that matches none of the schemas', () {
      // Looks payload-ish (List with a leading int) but the inner shape
      // doesn't match meal, activity, or recipe.
      expect(classifySharedPayload('[1,"unexpected",{}]'), isNull);
    });

    test('does not cross-classify meal as activity', () {
      // Regression guard for the ordering in classifySharedPayload:
      // an activity parser would happily accept a meal's first inner
      // array as items unless the meal kind is tried first.
      final mealCode = SharedMealPayload.fromIntakeList(
        [_intake(_meal('custom-1', 'A'))],
      ).toJsonString();

      expect(classifySharedPayload(mealCode), isNot(SharedPayloadKind.activity));
      expect(classifySharedPayload(mealCode), isNot(SharedPayloadKind.recipe));
    });

    test('does not cross-classify activity as meal or recipe', () {
      final activityCode = SharedActivityPayload.fromUserActivityList(
        [_activity('01010', 30)],
      ).toJsonString();

      expect(
        classifySharedPayload(activityCode),
        isNot(SharedPayloadKind.meal),
      );
      expect(
        classifySharedPayload(activityCode),
        isNot(SharedPayloadKind.recipe),
      );
    });

    test('does not cross-classify recipe as meal or activity', () {
      final recipeCode = SharedRecipePayload.fromRecipe(_recipe()).toJsonString();

      expect(classifySharedPayload(recipeCode), isNot(SharedPayloadKind.meal));
      expect(
        classifySharedPayload(recipeCode),
        isNot(SharedPayloadKind.activity),
      );
    });
  });
}
