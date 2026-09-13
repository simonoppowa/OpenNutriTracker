import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_ingredient_dbo.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

final _log = Logger('OffMicronutrientRepair');

/// Brings Open Food Facts rows written before #775 into the app's units
/// (#1152).
///
/// Open Food Facts sends every `<nutrient>_100g` field in grams. Until #775,
/// `MealNutrimentsEntity.fromOffNutriments` copied those values through
/// unconverted, so every mineral was stored a thousand times too small and
/// vitamins A, D and B12 a million times too small — on the intake, on the
/// cached product, and on any recipe ingredient snapshotted from it. #775
/// fixed the mapping for new writes only.
///
/// The stored numbers cannot tell the two conventions apart on their own:
/// a 400 mg sodium food written as `0.4` looks exactly like a genuinely
/// low-sodium food. What tells them apart is [MealDBO.dataVersion]: a build
/// that carries #775 also carries this field and stamps every row it
/// writes, so an Open Food Facts row without it was written by the old
/// mapping. That holds because no build with #775 and without the stamp
/// ever shipped — the two land in the same release.
///
/// Every row is either fully repaired and stamped in one write, or not
/// touched at all, so a pass can stop anywhere (the app killed, a box that
/// fails to write) and the next pass picks up exactly the rows that are
/// still unstamped. Rows from any other source are never rewritten: the
/// Supabase view and FDC already deliver app units, and a custom meal holds
/// what the user typed.
class OffMicronutrientRepair {
  // The same two factors #775 added to `fromOffNutriments`.
  static const _gToMg = 1000.0;
  static const _gToUg = 1000000.0;

  static final _computeRecipeNutrition = ComputeRecipeNutritionUseCase();

  /// True for an Open Food Facts row still holding the grams the API sent.
  static bool needsRepair(MealDBO meal) =>
      meal.source == MealSourceDBO.off &&
      (meal.dataVersion ?? 0) < MealDBO.dataVersionOffMicronutrientsInAppUnits;

  /// The same [meal] when nothing needs doing, otherwise a copy with the
  /// micronutrients scaled and [MealDBO.dataVersion] stamped. Macros, the
  /// three lipid fields and nulls pass through: they were never wrong.
  static MealDBO repairMeal(MealDBO meal) {
    if (!needsRepair(meal)) return meal;
    final n = meal.nutriments;
    return MealDBO(
      code: meal.code,
      name: meal.name,
      brands: meal.brands,
      thumbnailImageUrl: meal.thumbnailImageUrl,
      mainImageUrl: meal.mainImageUrl,
      url: meal.url,
      mealQuantity: meal.mealQuantity,
      mealUnit: meal.mealUnit,
      servingQuantity: meal.servingQuantity,
      servingUnit: meal.servingUnit,
      servingSize: meal.servingSize,
      source: meal.source,
      nutriments: MealNutrimentsDBO(
        energyKcal100: n.energyKcal100,
        carbohydrates100: n.carbohydrates100,
        fat100: n.fat100,
        proteins100: n.proteins100,
        sugars100: n.sugars100,
        saturatedFat100: n.saturatedFat100,
        fiber100: n.fiber100,
        monounsaturatedFat100: n.monounsaturatedFat100,
        polyunsaturatedFat100: n.polyunsaturatedFat100,
        transFat100: n.transFat100,
        cholesterol100: _scale(n.cholesterol100, _gToMg),
        sodium100: _scale(n.sodium100, _gToMg),
        potassium100: _scale(n.potassium100, _gToMg),
        magnesium100: _scale(n.magnesium100, _gToMg),
        calcium100: _scale(n.calcium100, _gToMg),
        iron100: _scale(n.iron100, _gToMg),
        zinc100: _scale(n.zinc100, _gToMg),
        phosphorus100: _scale(n.phosphorus100, _gToMg),
        vitaminA100: _scale(n.vitaminA100, _gToUg),
        vitaminC100: _scale(n.vitaminC100, _gToMg),
        vitaminD100: _scale(n.vitaminD100, _gToUg),
        vitaminB6100: _scale(n.vitaminB6100, _gToMg),
        vitaminB12100: _scale(n.vitaminB12100, _gToUg),
        niacin100: _scale(n.niacin100, _gToMg),
      ),
      localImagePath: meal.localImagePath,
      detailed: meal.detailed,
      backendSource: meal.backendSource,
      machineTranslatedName: meal.machineTranslatedName,
      dataVersion: MealDBO.dataVersionOffMicronutrientsInAppUnits,
    );
  }

  static double? _scale(double? value, double factor) =>
      value == null ? null : value * factor;

  /// The same [intake] when its meal needs nothing, otherwise a copy
  /// carrying the repaired meal. Amount, unit, type and date are kept.
  static IntakeDBO repairIntake(IntakeDBO intake) {
    final meal = repairMeal(intake.meal);
    if (identical(meal, intake.meal)) return intake;
    return IntakeDBO(
      id: intake.id,
      unit: intake.unit,
      amount: intake.amount,
      type: intake.type,
      meal: meal,
      dateTime: intake.dateTime,
    );
  }

  /// The same [recipe] when no ingredient needs repairing, otherwise a copy
  /// with those snapshots repaired and the per-100 g aggregate recomputed
  /// from the repaired list, the way `SaveRecipeUseCase` computes it. The
  /// stored total weight is passed back in as the override so a recipe
  /// whose weight the user had set by hand keeps it; for the others it
  /// equals the ingredient sum anyway. Timestamps are left alone — this is
  /// a repair, not an edit.
  static RecipeDBO repairRecipe(RecipeDBO recipe) {
    var changed = false;
    final ingredients = <RecipeIngredientDBO>[];
    for (final ingredient in recipe.ingredients) {
      final meal = repairMeal(ingredient.snapshotMeal);
      if (identical(meal, ingredient.snapshotMeal)) {
        ingredients.add(ingredient);
        continue;
      }
      changed = true;
      ingredients.add(
        RecipeIngredientDBO(
          snapshotMeal: meal,
          amount: ingredient.amount,
          unit: ingredient.unit,
          convertedAmountG: ingredient.convertedAmountG,
        ),
      );
    }
    if (!changed) return recipe;

    final aggregate = _computeRecipeNutrition.compute(
      ingredients.map(RecipeIngredientEntity.fromDBO).toList(),
      totalWeightOverride: recipe.totalWeightG,
    );
    return RecipeDBO(
      id: recipe.id,
      name: recipe.name,
      description: recipe.description,
      ingredients: ingredients,
      totalWeightG: recipe.totalWeightG,
      aggregatedNutrimentsPer100: MealNutrimentsDBO.fromProductNutrimentsEntity(
        aggregate.perHundredG,
      ),
      createdAt: recipe.createdAt,
      updatedAt: recipe.updatedAt,
      servingsCount: recipe.servingsCount,
      tags: recipe.tags,
      imagePath: recipe.imagePath,
    );
  }

  /// Repairs every row of [box] that needs it, in one write, and returns
  /// how many were rewritten. A box with nothing to repair is not written
  /// to at all, which is what makes a second pass free.
  static Future<int> repairIntakeBox(Box<IntakeDBO> box) =>
      _repairBox(box, repairIntake);

  /// Same as [repairIntakeBox] for a box of meals — the remote-search cache,
  /// whose Open Food Facts entries are what a re-scan or a re-log of a
  /// known product reads instead of the network.
  static Future<int> repairMealBox(Box<MealDBO> box) =>
      _repairBox(box, repairMeal);

  /// Same as [repairIntakeBox] for the recipe library.
  static Future<int> repairRecipeBox(Box<RecipeDBO> box) =>
      _repairBox(box, repairRecipe);

  static Future<int> _repairBox<T>(Box<T> box, T Function(T) repair) async {
    final repaired = <dynamic, T>{};
    for (final entry in box.toMap().entries) {
      final fixed = repair(entry.value);
      if (!identical(fixed, entry.value)) repaired[entry.key] = fixed;
    }
    if (repaired.isNotEmpty) {
      await box.putAll(repaired);
    }
    return repaired.length;
  }
}

/// Runs the repair over everything the active profile can read: its own
/// intake log plus the shared remote-search cache and recipe library.
///
/// Called on every profile activation — startup and a profile switch —
/// like [ensureConfigInitialized], so each profile's box is repaired before
/// anything reads it. Idempotent: a box with no unstamped Open Food Facts
/// row costs one in-memory scan and no write.
Future<void> ensureOffMicronutrientsRepaired(HiveDBProvider db) async {
  final intakes = await OffMicronutrientRepair.repairIntakeBox(db.intakeBox);
  final cached = await OffMicronutrientRepair.repairMealBox(
    db.cachedOffMealBox,
  );
  final recipes = await OffMicronutrientRepair.repairRecipeBox(db.recipeBox);
  if (intakes + cached + recipes > 0) {
    _log.info(
      'Converted Open Food Facts micronutrients into app units on '
      '$intakes intakes, $cached cached products and $recipes recipes '
      '(#1152)',
    );
  }
}
