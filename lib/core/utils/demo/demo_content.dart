import 'dart:math';

import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_custom_activity_template_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/demo/unsplash_attribution.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// Shared, duration-agnostic demo content: the curated food set, activity
/// pool, recipes, and the algorithm that turns a day's macro targets into
/// realistic intake entries. Both the dev-only 365-day QA fixture
/// (`lib/dev/main_dev.dart`) and the production "try it with sample data"
/// onboarding flow build on this — only how many days and how strict the
/// adherence is (see `demo_seeder.dart`'s `DemoSeedOptions`) differs
/// between them.
///
/// Fixed seed for [demoRng]. Re-applied via [resetDemoRng] at the start of
/// every `seedDemoData` call so a second try-demo / `just dev_seed` in the
/// same process reproduces the same fixture rather than continuing the
/// previous run's RNG stream.
const demoRngSeed = 1337;

/// The current-streak guarantee and all day-to-day randomisation (which
/// foods/portions/times are picked) read off this single fixed-seed
/// generator, so the data looks organically noisy (no obvious repeating
/// cycle in the calorie/water graphs) while still being reproducible
/// across runs — handy for a dev tool where you want the same fixture
/// every time you reseed, not a new random one.
var demoRng = Random(demoRngSeed);

/// Reset [demoRng] to a fresh `Random([demoRngSeed])`. Called by
/// `seedDemoData` before generating content.
void resetDemoRng() => demoRng = Random(demoRngSeed);

/// [hour]:00 plus up to 44 random minutes, so logged times don't land on
/// the exact same clock minute every single day.
DateTime jitteredTime(DateTime day, int hour) =>
    DateTime(day.year, day.month, day.day, hour, demoRng.nextInt(45));

/// The fixed set of foods used to build every day's intake and the
/// recipes. Grouped so [buildDailyIntakes] and [seedRecipes] don't have
/// to know how they were constructed.
typedef DemoFoods = ({
  MealEntity oatmeal,
  MealEntity brownRice,
  MealEntity wholegrainBread,
  MealEntity chickenBreast,
  MealEntity greekYogurt,
  MealEntity salmon,
  MealEntity oliveOil,
  MealEntity almonds,
  MealEntity banana,
  MealEntity apple,
  MealEntity broccoli,
});

/// A per-100g nutrient snapshot broad enough to cover what the diary's
/// micronutrient panel aggregates (see `DailyNutrientPanel`, which sums
/// straight off logged intakes' [MealNutrimentsEntity] — there's no
/// separate "tracked micros" store to seed). Values below are
/// approximate real-world figures for each food, not lab-precise, but
/// plausible enough that the panel shows realistic numbers instead of
/// zeroes.
MealEntity _meal(
  String name, {
  required double kcal100,
  required double carbs100,
  required double fat100,
  required double protein100,
  double? sugars100,
  double? satFat100,
  double? fiber100,
  double? monounsaturatedFat100,
  double? polyunsaturatedFat100,
  double? cholesterol100,
  double? sodium100,
  double? potassium100,
  double? magnesium100,
  double? calcium100,
  double? iron100,
  double? zinc100,
  double? phosphorus100,
  double? vitaminA100,
  double? vitaminC100,
  double? vitaminD100,
  double? vitaminB6100,
  double? vitaminB12100,
  double? niacin100,
  // A curated Unsplash photo id (see unsplash_attribution.dart) — every
  // demo food gets one, so this isn't optional the way a real OFF/FDC
  // search result's photo would be.
  required String photoId,
}) => MealEntity(
  code: IdGenerator.getUniqueID(),
  name: name,
  url: null,
  thumbnailImageUrl: unsplashImageUrl(photoId, width: 200),
  mainImageUrl: unsplashImageUrl(photoId, width: 800),
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  source: MealSourceEntity.custom,
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal100,
    carbohydrates100: carbs100,
    fat100: fat100,
    proteins100: protein100,
    sugars100: sugars100 ?? carbs100 * 0.3,
    saturatedFat100: satFat100 ?? fat100 * 0.35,
    fiber100: fiber100 ?? 2.0,
    monounsaturatedFat100: monounsaturatedFat100,
    polyunsaturatedFat100: polyunsaturatedFat100,
    cholesterol100: cholesterol100,
    sodium100: sodium100,
    potassium100: potassium100,
    magnesium100: magnesium100,
    calcium100: calcium100,
    iron100: iron100,
    zinc100: zinc100,
    phosphorus100: phosphorus100,
    vitaminA100: vitaminA100,
    vitaminC100: vitaminC100,
    vitaminD100: vitaminD100,
    vitaminB6100: vitaminB6100,
    vitaminB12100: vitaminB12100,
    niacin100: niacin100,
  ),
);

/// Builds every demo food, each with its curated Unsplash photo id (see
/// unsplash_attribution.dart) — a fixed, hand-picked set rather than a
/// live search, so this needs no network access and returns synchronously.
DemoFoods buildDemoFoods() {
  final oatmeal = _meal(
    'Oatmeal',
    photoId: '1548807371-30dc1bbe6cb5',
    kcal100: 150,
    carbs100: 27,
    fat100: 3,
    protein100: 5,
    fiber100: 4,
    sodium100: 6,
    potassium100: 143,
    magnesium100: 63,
    calcium100: 21,
    iron100: 1.7,
    zinc100: 1.3,
    phosphorus100: 180,
    vitaminB6100: 0.05,
    niacin100: 0.4,
    monounsaturatedFat100: 1.0,
    polyunsaturatedFat100: 1.1,
  );
  final brownRice = _meal(
    'Brown rice',
    photoId: '1593357849627-cbbc9fda6b05',
    kcal100: 123,
    carbs100: 26,
    fat100: 1,
    protein100: 3,
    fiber100: 1.8,
    sodium100: 5,
    potassium100: 86,
    magnesium100: 43,
    calcium100: 10,
    iron100: 0.5,
    zinc100: 0.6,
    phosphorus100: 83,
    vitaminB6100: 0.15,
    niacin100: 1.5,
    monounsaturatedFat100: 0.3,
    polyunsaturatedFat100: 0.3,
  );
  // Deliberately not a low-carb-density food like potatoes (20g/100g) —
  // hitting a high daily carb target with a low-density food needs an
  // unrealistically large gram amount (900g+ was showing up in testing).
  final wholegrainBread = _meal(
    'Wholegrain bread',
    photoId: '1552056413-b8b5eed0170b',
    kcal100: 265,
    carbs100: 49,
    fat100: 3.5,
    protein100: 9,
    fiber100: 7,
    sodium100: 400,
    potassium100: 230,
    magnesium100: 65,
    calcium100: 100,
    iron100: 2.5,
    zinc100: 1.5,
    phosphorus100: 200,
    vitaminB6100: 0.1,
    niacin100: 4.0,
    monounsaturatedFat100: 0.4,
    polyunsaturatedFat100: 1.2,
  );
  final chickenBreast = _meal(
    'Chicken breast',
    photoId: '1762631934518-f75e233413ca',
    kcal100: 165,
    carbs100: 0,
    fat100: 3.6,
    protein100: 31,
    satFat100: 1,
    cholesterol100: 85,
    sodium100: 74,
    potassium100: 256,
    magnesium100: 29,
    calcium100: 15,
    iron100: 1.0,
    zinc100: 1.0,
    phosphorus100: 220,
    vitaminB6100: 0.6,
    vitaminB12100: 0.3,
    niacin100: 13.7,
    monounsaturatedFat100: 1.24,
    polyunsaturatedFat100: 0.8,
  );
  final greekYogurt = _meal(
    'Greek yogurt',
    photoId: '1571212515416-fef01fc43637',
    kcal100: 59,
    carbs100: 3.6,
    fat100: 0.4,
    protein100: 10,
    sugars100: 3.6,
    cholesterol100: 5,
    sodium100: 36,
    potassium100: 141,
    magnesium100: 11,
    calcium100: 110,
    iron100: 0.05,
    zinc100: 0.5,
    phosphorus100: 135,
    vitaminB6100: 0.05,
    vitaminB12100: 0.5,
    monounsaturatedFat100: 0.1,
  );
  final salmon = _meal(
    'Salmon fillet',
    photoId: '1739785938237-73b3654200d5',
    kcal100: 208,
    carbs100: 0,
    fat100: 13,
    protein100: 20,
    satFat100: 3.1,
    cholesterol100: 55,
    sodium100: 59,
    potassium100: 363,
    magnesium100: 27,
    calcium100: 9,
    iron100: 0.3,
    zinc100: 0.4,
    phosphorus100: 240,
    vitaminD100: 11,
    vitaminB12100: 3.2,
    niacin100: 8.0,
    monounsaturatedFat100: 3.8,
    polyunsaturatedFat100: 3.9,
  );
  final oliveOil = _meal(
    'Olive oil',
    photoId: '1757801333069-f7b3cabaec4a',
    kcal100: 884,
    carbs100: 0,
    fat100: 100,
    protein100: 0,
    satFat100: 14,
    monounsaturatedFat100: 73,
    polyunsaturatedFat100: 11,
  );
  final almonds = _meal(
    'Almonds',
    photoId: '1627820752174-acae1b399128',
    kcal100: 579,
    carbs100: 22,
    fat100: 50,
    protein100: 21,
    fiber100: 12.5,
    sodium100: 1,
    potassium100: 733,
    magnesium100: 270,
    calcium100: 269,
    iron100: 3.7,
    zinc100: 3.1,
    phosphorus100: 481,
    vitaminB6100: 0.14,
    niacin100: 3.6,
    monounsaturatedFat100: 31,
    polyunsaturatedFat100: 12,
  );
  final banana = _meal(
    'Banana',
    photoId: '1757332050958-b797a022c910',
    kcal100: 89,
    carbs100: 23,
    fat100: 0.3,
    protein100: 1.1,
    sugars100: 12,
    fiber100: 2.6,
    sodium100: 1,
    potassium100: 358,
    magnesium100: 27,
    calcium100: 5,
    iron100: 0.26,
    zinc100: 0.15,
    phosphorus100: 22,
    vitaminB6100: 0.37,
    vitaminC100: 8.7,
    niacin100: 0.7,
  );
  final apple = _meal(
    'Apple',
    photoId: '1567306226416-28f0efdc88ce',
    kcal100: 52,
    carbs100: 14,
    fat100: 0.2,
    protein100: 0.3,
    sugars100: 10,
    fiber100: 2.4,
    sodium100: 1,
    potassium100: 107,
    magnesium100: 5,
    calcium100: 6,
    iron100: 0.12,
    vitaminC100: 4.6,
    niacin100: 0.09,
  );
  final broccoli = _meal(
    'Broccoli',
    photoId: '1646161762904-043f71f256f1',
    kcal100: 35,
    carbs100: 7,
    fat100: 0.4,
    protein100: 2.4,
    fiber100: 3.3,
    sodium100: 33,
    potassium100: 316,
    magnesium100: 21,
    calcium100: 47,
    iron100: 0.7,
    zinc100: 0.4,
    phosphorus100: 66,
    vitaminA100: 31,
    vitaminC100: 89,
    vitaminB6100: 0.18,
    niacin100: 0.6,
  );

  return (
    oatmeal: oatmeal,
    brownRice: brownRice,
    wholegrainBread: wholegrainBread,
    chickenBreast: chickenBreast,
    greekYogurt: greekYogurt,
    salmon: salmon,
    oliveOil: oliveOil,
    almonds: almonds,
    banana: banana,
    apple: apple,
    broccoli: broccoli,
  );
}

double _roundToNearest5g(double grams) => grams <= 0 ? 0.0 : max(10.0, (grams / 5).round() * 5.0);

/// Grams of [meal] needed to supply [targetGrams] of the macro read off by
/// [macroPer100] (e.g. `(n) => n.proteins100`). Zero when the food doesn't
/// carry that macro or the target is already met.
double _gramsFor(
  MealEntity meal,
  double targetGrams,
  double? Function(MealNutrimentsEntity) macroPer100,
) {
  final per100 = macroPer100(meal.nutriments) ?? 0;
  if (per100 <= 0 || targetGrams <= 0) return 0;
  return targetGrams / per100 * 100;
}

double _macroGrams(
  MealEntity meal,
  double amount,
  double? Function(MealNutrimentsEntity) macroPer100,
) => (macroPer100(meal.nutriments) ?? 0) * amount / 100;

/// Builds the day's intake by solving for each food's portion in turn —
/// veg and fruit are fixed-size sides; the carb target is split across a
/// breakfast and a dinner starch (rather than one giant bowl of rice);
/// the fat target is split across a dinner oil and a snack-time handful
/// of almonds; and the protein source is sized last, to whatever protein
/// target is left after every other food's contribution is known. Both
/// the splitting and the protein-last ordering exist for the same
/// reason: a single food sized to cover an entire day's target for one
/// macro produces an unrealistic portion (900g+ of rice) and, for
/// protein specifically, routinely overshoots the goal once the other
/// foods' incidental protein is added on top.
///
/// Which foods and what split ratios are chosen is randomised per day
/// (see [demoRng]) rather than rotated through a fixed cycle, so the
/// week doesn't visibly repeat itself.
List<IntakeEntity> buildDailyIntakes(
  DateTime day,
  ({double carbs, double fat, double protein}) targetMacros,
  DemoFoods foods,
) {
  final carbPool = [foods.oatmeal, foods.brownRice, foods.wholegrainBread];
  final proteinPool = [foods.chickenBreast, foods.greekYogurt, foods.salmon];
  final carbMealA = carbPool[demoRng.nextInt(carbPool.length)];
  final carbMealB = carbPool[demoRng.nextInt(carbPool.length)];
  final proteinMeal = proteinPool[demoRng.nextInt(proteinPool.length)];
  final fruitMeal = demoRng.nextBool() ? foods.banana : foods.apple;

  final veggieAmount = 80.0 + demoRng.nextInt(60); // 80-139g
  final fruitAmount = 100.0 + demoRng.nextInt(60); // 100-159g
  final veggieCarb = _macroGrams(foods.broccoli, veggieAmount, (n) => n.carbohydrates100);
  final veggieFat = _macroGrams(foods.broccoli, veggieAmount, (n) => n.fat100);
  final veggieProtein = _macroGrams(foods.broccoli, veggieAmount, (n) => n.proteins100);
  final fruitCarb = _macroGrams(fruitMeal, fruitAmount, (n) => n.carbohydrates100);
  final fruitFat = _macroGrams(fruitMeal, fruitAmount, (n) => n.fat100);
  final fruitProtein = _macroGrams(fruitMeal, fruitAmount, (n) => n.proteins100);

  // Carb target split ~30-60% breakfast / rest dinner starch.
  final carbShareA = 0.3 + demoRng.nextDouble() * 0.3;
  final remainingCarb = targetMacros.carbs - veggieCarb - fruitCarb;
  final carbAmountA = _roundToNearest5g(
    _gramsFor(carbMealA, remainingCarb * carbShareA, (n) => n.carbohydrates100),
  );
  final carbAmountB = _roundToNearest5g(
    _gramsFor(
      carbMealB,
      remainingCarb * (1 - carbShareA),
      (n) => n.carbohydrates100,
    ),
  );
  final carbFat =
      _macroGrams(carbMealA, carbAmountA, (n) => n.fat100) +
      _macroGrams(carbMealB, carbAmountB, (n) => n.fat100);
  final carbProtein =
      _macroGrams(carbMealA, carbAmountA, (n) => n.proteins100) +
      _macroGrams(carbMealB, carbAmountB, (n) => n.proteins100);

  // Fat target split ~50-75% dinner oil / rest a handful of almonds.
  final oilShare = 0.5 + demoRng.nextDouble() * 0.25;
  final remainingFat = targetMacros.fat - veggieFat - fruitFat - carbFat;
  final oilAmount = _roundToNearest5g(
    _gramsFor(foods.oliveOil, remainingFat * oilShare, (n) => n.fat100),
  );
  final almondAmount = _roundToNearest5g(
    _gramsFor(
      foods.almonds,
      remainingFat * (1 - oilShare),
      (n) => n.fat100,
    ),
  );
  final almondProtein = _macroGrams(foods.almonds, almondAmount, (n) => n.proteins100);

  final remainingProtein = targetMacros.protein -
      veggieProtein -
      fruitProtein -
      carbProtein -
      almondProtein;
  final proteinAmount = _roundToNearest5g(
    _gramsFor(proteinMeal, remainingProtein, (n) => n.proteins100),
  );

  return [
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: carbAmountA,
      type: IntakeTypeEntity.breakfast,
      meal: carbMealA,
      dateTime: jitteredTime(day, 8),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: proteinAmount,
      type: IntakeTypeEntity.lunch,
      meal: proteinMeal,
      dateTime: jitteredTime(day, 13),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: veggieAmount,
      type: IntakeTypeEntity.dinner,
      meal: foods.broccoli,
      dateTime: jitteredTime(day, 19),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: carbAmountB,
      type: IntakeTypeEntity.dinner,
      meal: carbMealB,
      dateTime: jitteredTime(day, 19),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: oilAmount,
      type: IntakeTypeEntity.dinner,
      meal: foods.oliveOil,
      dateTime: jitteredTime(day, 19),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: fruitAmount,
      type: IntakeTypeEntity.snack,
      meal: fruitMeal,
      dateTime: jitteredTime(day, 16),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: almondAmount,
      type: IntakeTypeEntity.snack,
      meal: foods.almonds,
      dateTime: jitteredTime(day, 16),
    ),
  ].where((intake) => intake.amount > 0).toList();
}

const _runningVigorous = PhysicalActivityEntity(
  '12150',
  'Running, vigorous effort',
  'Running at a fast pace',
  12.0,
  [],
  PhysicalActivityTypeEntity.running,
);
const _bicyclingModerate = PhysicalActivityEntity(
  '01015',
  'Bicycling, moderate speed',
  'Bicycling at a moderate speed on flat terrain',
  8.0,
  [],
  PhysicalActivityTypeEntity.bicycling,
);
const _dancingLight = PhysicalActivityEntity(
  '03015',
  'Dancing, light effort',
  'Dancing with light effort, e.g., slow ballroom dancing',
  4.0,
  [],
  PhysicalActivityTypeEntity.dancing,
);
const demoActivityPool = [_runningVigorous, _bicyclingModerate, _dancingLight];

/// 2-4 glasses of randomised size — a fixed "500 + 500 + 300-600" pattern
/// repeating every few days made the Trends water graph look mechanical;
/// real logging is noisier (and some days people just log less).
List<WaterIntakeEntity> buildDailyWater(DateTime day) {
  final glassCount = 2 + demoRng.nextInt(3);
  final hours = [8, 11, 15, 18, 21];
  return [
    for (var i = 0; i < glassCount; i++)
      WaterIntakeEntity(
        id: IdGenerator.getUniqueID(),
        dateTime: jitteredTime(day, hours[i]),
        amountMl: 200 + demoRng.nextInt(5) * 100, // 200-600 ml
      ),
  ];
}

MealNutrimentsEntity _emptyRecipeNutriments() => MealNutrimentsEntity.empty();

/// A handful of saved recipes spanning breakfast and dinner, high-protein
/// and lighter options — `SaveRecipeUseCase.save` recomputes the
/// aggregated nutriments from the ingredient list, so only the ingredient
/// amounts need to be realistic.
Future<void> seedRecipes(DateTime now, DemoFoods foods) async {
  RecipeIngredientEntity ingredient(MealEntity meal, double amountG) =>
      RecipeIngredientEntity(
        snapshotMeal: meal,
        amount: amountG,
        unit: 'g',
        convertedAmountG: amountG,
      );

  final recipes = [
    RecipeEntity(
      id: IdGenerator.getUniqueID(),
      name: 'Protein Power Bowl',
      description: 'Grilled chicken over brown rice, meal-prep friendly.',
      ingredients: [
        ingredient(foods.chickenBreast, 200),
        ingredient(foods.brownRice, 150),
      ],
      totalWeightG: 350,
      aggregatedNutrimentsPer100: _emptyRecipeNutriments(),
      createdAt: now,
      updatedAt: now,
      servingsCount: 2,
      tags: const ['high-protein'],
    ),
    RecipeEntity(
      id: IdGenerator.getUniqueID(),
      name: 'Salmon & Greens Bowl',
      description:
          'Pan-seared salmon with rice and steamed broccoli — an easy '
          'omega-3-rich dinner for two.',
      ingredients: [
        ingredient(foods.salmon, 180),
        ingredient(foods.brownRice, 150),
        ingredient(foods.broccoli, 100),
      ],
      totalWeightG: 430,
      aggregatedNutrimentsPer100: _emptyRecipeNutriments(),
      createdAt: now,
      updatedAt: now,
      servingsCount: 2,
      tags: const ['omega-3', 'high-protein'],
    ),
    RecipeEntity(
      id: IdGenerator.getUniqueID(),
      name: 'Morning Oat Bowl',
      description: 'Oatmeal topped with banana and almonds.',
      ingredients: [
        ingredient(foods.oatmeal, 200),
        ingredient(foods.banana, 100),
        ingredient(foods.almonds, 20),
      ],
      totalWeightG: 320,
      aggregatedNutrimentsPer100: _emptyRecipeNutriments(),
      createdAt: now,
      updatedAt: now,
      servingsCount: 1,
      tags: const ['breakfast', 'vegetarian'],
    ),
    RecipeEntity(
      id: IdGenerator.getUniqueID(),
      name: 'Greek Yogurt Parfait',
      description: 'Greek yogurt layered with banana and a scattering of almonds.',
      ingredients: [
        ingredient(foods.greekYogurt, 200),
        ingredient(foods.banana, 80),
        ingredient(foods.almonds, 15),
      ],
      totalWeightG: 295,
      aggregatedNutrimentsPer100: _emptyRecipeNutriments(),
      createdAt: now,
      updatedAt: now,
      servingsCount: 1,
      tags: const ['breakfast', 'high-protein'],
    ),
  ];

  final saveRecipe = locator<SaveRecipeUseCase>();
  for (final recipe in recipes) {
    await saveRecipe.save(recipe);
  }
}

Future<void> seedCustomActivityTemplate() async {
  await locator<AddCustomActivityTemplateUsecase>().addTemplate(
    const CustomActivityTemplateEntity(
      name: 'Gym session',
      typicalKcal: 400,
      notes: 'Full-body strength training',
    ),
  );
}
