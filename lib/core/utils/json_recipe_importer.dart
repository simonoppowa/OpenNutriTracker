import 'dart:convert';

import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

class JsonRecipeImportResult {
  final List<RecipeEntity> recipes;
  final List<String> errors;

  const JsonRecipeImportResult({required this.recipes, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

/// Lenient JSON-paste importer for full custom recipes. Accepts either a
/// single recipe object or a JSON array of them. Mirrors the CSV recipe
/// importer's shape: ingredients carry per-100g nutrition (matching how
/// most food labels and nutrition databases report values), and the
/// importer multiplies that against each ingredient's `amount` to derive
/// the aggregated recipe nutriments.
///
/// Every parse path is defensive against null and unexpected types. A
/// malformed field surfaces as a per-entry error string rather than a
/// crash — the recipe is skipped, every other recipe in the same paste
/// continues to parse, and the user sees a concrete reason for the skip.
///
/// Expected shape:
///
/// ```
/// {
///   "name": "Vanilla Cake",
///   "description": "Classic vanilla sponge",   // optional
///   "servings": 8,                              // optional
///   "totalWeight": 1500,                        // optional (g; otherwise summed from ingredients)
///   "tags": ["dessert", "baking"],              // optional
///   "ingredients": [
///     {
///       "name": "Flour",
///       "amount": 200,           // amount of this ingredient in `unit`
///       "unit": "g",             // g, ml, etc.
///       "kcalPer100": 340,
///       "carbsPer100": 70,
///       "proteinPer100": 10,
///       "fatPer100": 1
///     }
///   ]
/// }
/// ```
class JsonRecipeImporter {
  static const _kName = 'name';
  static const _kDescription = 'description';
  static const _kServings = 'servings';
  static const _kTotalWeight = 'totalWeight';
  static const _kTags = 'tags';
  static const _kIngredients = 'ingredients';

  static const _kIngName = 'name';
  static const _kIngAmount = 'amount';
  static const _kIngUnit = 'unit';
  static const _kIngKcal = 'kcalPer100';
  static const _kIngCarbs = 'carbsPer100';
  static const _kIngProtein = 'proteinPer100';
  static const _kIngFat = 'fatPer100';

  /// Parse a JSON blob. Top-level may be a single recipe object or an array
  /// of recipe objects. The result always returns — never throws — so the
  /// caller can render the error list without try/catch noise.
  static JsonRecipeImportResult parse(String jsonContent) {
    final trimmed = jsonContent.trim();
    if (trimmed.isEmpty) {
      return const JsonRecipeImportResult(
        recipes: [],
        errors: ['JSON is empty'],
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (e) {
      return JsonRecipeImportResult(
        recipes: const [],
        errors: ['Could not parse: ${e.message}'],
      );
    }

    final entries = <Map<String, dynamic>>[];
    if (decoded is Map) {
      entries.add(Map<String, dynamic>.from(decoded));
    } else if (decoded is List) {
      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is Map) {
          entries.add(Map<String, dynamic>.from(item));
        } else {
          return JsonRecipeImportResult(
            recipes: const [],
            errors: [
              'Could not parse: entry #${i + 1} is not an object',
            ],
          );
        }
      }
    } else {
      return const JsonRecipeImportResult(
        recipes: [],
        errors: [
          'Could not parse: top-level JSON must be an object or an array of objects',
        ],
      );
    }

    final compute = ComputeRecipeNutritionUseCase();
    final recipes = <RecipeEntity>[];
    final errors = <String>[];
    final now = DateTime.now();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final entryNum = i + 1;

      final name = _asString(entry[_kName])?.trim();
      if (name == null || name.isEmpty) {
        errors.add('Recipe $entryNum: missing or empty "name"');
        continue;
      }

      final rawIngredients = entry[_kIngredients];
      if (rawIngredients is! List || rawIngredients.isEmpty) {
        errors.add(
          'Recipe $entryNum ($name): "ingredients" must be a non-empty array',
        );
        continue;
      }

      final ingredients = <RecipeIngredientEntity>[];
      var ingredientHadError = false;
      for (var j = 0; j < rawIngredients.length; j++) {
        final raw = rawIngredients[j];
        final ingNum = j + 1;
        if (raw is! Map) {
          errors.add(
            'Recipe $entryNum ($name) ingredient $ingNum: not an object',
          );
          ingredientHadError = true;
          break;
        }
        final ing = Map<String, dynamic>.from(raw);

        final ingName = _asString(ing[_kIngName])?.trim();
        if (ingName == null || ingName.isEmpty) {
          errors.add(
            'Recipe $entryNum ($name) ingredient $ingNum: missing or empty "name"',
          );
          ingredientHadError = true;
          break;
        }

        final amount = _asDouble(ing[_kIngAmount]);
        if (amount == null || amount <= 0) {
          errors.add(
            'Recipe $entryNum ($name) ingredient $ingNum ($ingName): "amount" must be a positive number',
          );
          ingredientHadError = true;
          break;
        }

        final unit = _asString(ing[_kIngUnit])?.trim();
        if (unit == null || unit.isEmpty) {
          errors.add(
            'Recipe $entryNum ($name) ingredient $ingNum ($ingName): "unit" must be a non-empty string',
          );
          ingredientHadError = true;
          break;
        }

        final kcal100 = _asDouble(ing[_kIngKcal]);
        if (kcal100 == null) {
          errors.add(
            'Recipe $entryNum ($name) ingredient $ingNum ($ingName): "kcalPer100" must be a number',
          );
          ingredientHadError = true;
          break;
        }

        // Optional macro fields default to null so they degrade gracefully —
        // the UI handles null macros (shown as 0 in aggregates) without
        // pretending values were supplied.
        final ingredientMeal = MealEntity(
          code: IdGenerator.getUniqueID(),
          name: ingName,
          url: null,
          mealQuantity: '100',
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          nutriments: MealNutrimentsEntity(
            energyKcal100: kcal100,
            carbohydrates100: _asDouble(ing[_kIngCarbs]),
            fat100: _asDouble(ing[_kIngFat]),
            proteins100: _asDouble(ing[_kIngProtein]),
            sugars100: null,
            saturatedFat100: null,
            fiber100: null,
          ),
          source: MealSourceEntity.custom,
        );

        final convertedG = compute.convertAmountToGrams(
              amount: amount,
              unit: unit,
              servingQuantityG: null,
            ) ??
            0;

        ingredients.add(RecipeIngredientEntity(
          snapshotMeal: ingredientMeal,
          amount: amount,
          unit: unit,
          convertedAmountG: convertedG,
        ));
      }

      if (ingredientHadError || ingredients.isEmpty) {
        continue;
      }

      final description = _asString(entry[_kDescription])?.trim();
      final servingsCount = _asInt(entry[_kServings]);
      final totalWeightOverride = _asDouble(entry[_kTotalWeight]);

      final tags = <String>[];
      final rawTags = entry[_kTags];
      if (rawTags is List) {
        for (final t in rawTags) {
          final s = _asString(t)?.trim();
          if (s != null && s.isNotEmpty) tags.add(s);
        }
      }

      final result = compute.compute(
        ingredients,
        totalWeightOverride: totalWeightOverride,
      );

      recipes.add(RecipeEntity(
        id: IdGenerator.getUniqueID(),
        name: name,
        description:
            (description != null && description.isNotEmpty) ? description : null,
        ingredients: ingredients,
        totalWeightG: result.totalWeightG,
        aggregatedNutrimentsPer100: result.perHundredG,
        createdAt: now,
        updatedAt: now,
        servingsCount: servingsCount,
        tags: List.unmodifiable(tags),
      ));
    }

    return JsonRecipeImportResult(recipes: recipes, errors: errors);
  }

  /// Bundled sample shipped via the "Sample recipes JSON" button. Two
  /// recipes that between them exercise every supported field, including
  /// the optional ones (description, servings, totalWeight, tags).
  static String sampleJson() {
    return '''[
  {
    "name": "Vanilla Cake",
    "description": "Classic vanilla sponge",
    "servings": 8,
    "totalWeight": 1500,
    "tags": ["dessert", "baking"],
    "ingredients": [
      { "name": "Flour", "amount": 200, "unit": "g", "kcalPer100": 340, "carbsPer100": 70, "proteinPer100": 10, "fatPer100": 1 },
      { "name": "Sugar", "amount": 150, "unit": "g", "kcalPer100": 387, "carbsPer100": 100, "proteinPer100": 0, "fatPer100": 0 },
      { "name": "Eggs",  "amount": 200, "unit": "g", "kcalPer100": 155, "carbsPer100": 1.1, "proteinPer100": 13, "fatPer100": 11 }
    ]
  },
  {
    "name": "Greek salad bowl",
    "servings": 2,
    "ingredients": [
      { "name": "Tomato",       "amount": 200, "unit": "g", "kcalPer100": 18, "carbsPer100": 3.9, "proteinPer100": 0.9, "fatPer100": 0.2 },
      { "name": "Cucumber",     "amount": 150, "unit": "g", "kcalPer100": 15, "carbsPer100": 3.6, "proteinPer100": 0.7, "fatPer100": 0.1 },
      { "name": "Feta cheese",  "amount": 100, "unit": "g", "kcalPer100": 264, "carbsPer100": 4.1, "proteinPer100": 14, "fatPer100": 21 },
      { "name": "Olive oil",    "amount": 15,  "unit": "ml", "kcalPer100": 884, "carbsPer100": 0, "proteinPer100": 0, "fatPer100": 100 }
    ]
  }
]
''';
  }

  // --- defensive coercion helpers --------------------------------------------

  /// Returns a double for any of: null, num, numeric String. Never throws.
  /// Empty string and unparseable strings return null. Comma-as-decimal
  /// is accepted ("1,5" → 1.5) so European-formatted blobs work without
  /// the user having to massage them.
  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed.replaceAll(',', '.'));
    }
    return null;
  }

  /// Returns an int for null/num/numeric String. Doubles round down — a
  /// fractional "servings" value like 2.5 floors to 2 rather than throwing.
  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final asInt = int.tryParse(trimmed);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(trimmed.replaceAll(',', '.'));
      return asDouble?.toInt();
    }
    return null;
  }

  /// Returns a string for null/String/num/bool (anything coerceable). Returns
  /// null for nested maps/lists rather than emitting "{...}".
  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }
}
