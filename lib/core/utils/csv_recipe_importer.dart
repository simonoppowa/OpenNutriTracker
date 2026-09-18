import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/utils/csv_row_parser.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// One recipe pulled out of the CSV. [totalWeightOverridden] is true when
/// the user supplied an explicit `recipe_total_weight_g` for this recipe;
/// [ImportRecipesCsvUsecase] threads it into [SaveRecipeUseCase.save] so
/// the override survives the save-time recompute instead of collapsing
/// back to the ingredient sum (#1139 / #1194).
class ImportedCsvRecipe {
  final RecipeEntity recipe;
  final bool totalWeightOverridden;

  const ImportedCsvRecipe({
    required this.recipe,
    required this.totalWeightOverridden,
  });
}

/// Parsed result. [recipes] hold successfully grouped + assembled recipes,
/// each wrapped in [ImportedCsvRecipe] so the save-side knows whether an
/// explicit total weight was supplied; [errors] hold one entry per skipped
/// row (with the 1-based row number from the user's perspective and a
/// short reason).
class CsvRecipeImportResult {
  final List<ImportedCsvRecipe> recipes;
  final List<String> errors;

  const CsvRecipeImportResult({required this.recipes, required this.errors});

  bool get isEmpty => recipes.isEmpty && errors.isEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

/// Denormalized one-row-per-ingredient CSV format. Multiple rows with the
/// same `recipe_name` are grouped into a single RecipeEntity. Recipe-level
/// fields (description, servings, total_weight_g, tags) only need to be
/// filled on the first row of each group; subsequent rows can leave them
/// blank — the first non-empty value wins.
class CsvRecipeImporter {
  // Recipe-level columns
  static const _kRecipeName = 'recipe_name';
  static const _kRecipeDescription = 'recipe_description';
  static const _kRecipeServings = 'recipe_servings';
  static const _kRecipeTotalWeightG = 'recipe_total_weight_g';
  static const _kRecipeTags = 'recipe_tags';

  // Ingredient-level columns
  static const _kIngredientName = 'ingredient_name';
  static const _kIngredientBrands = 'ingredient_brands';
  static const _kIngredientAmount = 'ingredient_amount';
  static const _kIngredientUnit = 'ingredient_unit';
  static const _kIngredientKcal = 'ingredient_kcal_100';
  static const _kIngredientCarbs = 'ingredient_carbs_100';
  static const _kIngredientFat = 'ingredient_fat_100';
  static const _kIngredientProtein = 'ingredient_protein_100';
  static const _kIngredientSugars = 'ingredient_sugars_100';
  static const _kIngredientSatFat = 'ingredient_sat_fat_100';
  static const _kIngredientFiber = 'ingredient_fiber_100';

  static const orderedColumns = <String>[
    _kRecipeName,
    _kRecipeDescription,
    _kRecipeServings,
    _kRecipeTotalWeightG,
    _kRecipeTags,
    _kIngredientName,
    _kIngredientBrands,
    _kIngredientAmount,
    _kIngredientUnit,
    _kIngredientKcal,
    _kIngredientCarbs,
    _kIngredientFat,
    _kIngredientProtein,
    _kIngredientSugars,
    _kIngredientSatFat,
    _kIngredientFiber,
  ];

  static const requiredColumns = <String>{
    _kRecipeName,
    _kIngredientName,
    _kIngredientAmount,
    _kIngredientUnit,
    _kIngredientKcal,
  };

  static CsvRecipeImportResult parse(String csvContent) {
    final lines = csvContent
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const CsvRecipeImportResult(
        recipes: [],
        errors: ['CSV file is empty'],
      );
    }

    // Headers never carry decimal-comma payloads; parse strict.
    final headerCells = CsvRowParser.splitRow(lines.first)
        .map((c) => c.trim().toLowerCase())
        .toList();
    final missingRequired = requiredColumns
        .where((req) => !headerCells.contains(req))
        .toList();
    if (missingRequired.isNotEmpty) {
      return CsvRecipeImportResult(
        recipes: const [],
        errors: [
          'Header is missing required column(s): ${missingRequired.join(', ')}'
        ],
      );
    }

    // Group ingredient rows by recipe_name. We preserve insertion order so
    // ingredients appear in the same sequence the user authored.
    final groups = <String, _RecipeGroup>{};
    final errors = <String>[];

    for (var i = 1; i < lines.length; i++) {
      final rowNum = i + 1; // 1-based, including the header
      final cells = CsvRowParser.splitRow(lines[i]);
      if (cells.length < headerCells.length) {
        errors.add('Row $rowNum: too few columns');
        continue;
      }
      if (cells.length > headerCells.length) {
        errors.add(
            'Row $rowNum: too many columns. If a value contains a comma '
            '(for example a decimal like 1,5), wrap that cell in double '
            'quotes: "1,5".');
        continue;
      }
      final row = <String, String>{};
      for (var j = 0; j < headerCells.length; j++) {
        row[headerCells[j]] = cells[j].trim();
      }

      final recipeName = row[_kRecipeName] ?? '';
      if (recipeName.isEmpty) {
        errors.add('Row $rowNum: recipe_name is empty');
        continue;
      }
      final ingredientName = row[_kIngredientName] ?? '';
      if (ingredientName.isEmpty) {
        errors.add('Row $rowNum: ingredient_name is empty');
        continue;
      }
      final amount = CsvRowParser.parseDoubleOrNull(row[_kIngredientAmount]);
      if (amount == null || amount <= 0) {
        errors.add('Row $rowNum: ingredient_amount is missing or not positive');
        continue;
      }
      final unit = row[_kIngredientUnit] ?? '';
      if (unit.isEmpty) {
        errors.add('Row $rowNum: ingredient_unit is empty');
        continue;
      }
      final kcal = CsvRowParser.parseDoubleOrNull(row[_kIngredientKcal]);
      if (kcal == null) {
        errors.add('Row $rowNum: ingredient_kcal_100 is not a number');
        continue;
      }

      final group = groups.putIfAbsent(
        recipeName,
        () => _RecipeGroup(name: recipeName),
      );

      // Recipe-level fields: take the first non-empty value seen per group.
      group.description ??=
          row[_kRecipeDescription]?.isNotEmpty == true
              ? row[_kRecipeDescription]
              : null;
      group.servingsCount ??= _parseIntOrNull(row[_kRecipeServings]);
      // Only the first non-empty `recipe_total_weight_g` per recipe wins,
      // matching the "first non-empty value wins" rule for every other
      // recipe-level field. A value that parses to 0, negative, NaN or
      // infinity is rejected with a per-row error, and the group is
      // marked so the save-time build step drops the whole recipe — same
      // shape as JsonRecipeImporter's `totalWeight` guard (#1139 / #1194).
      if (group.totalWeightOverride == null && !group.totalWeightRejected) {
        final rawTotalWeight = row[_kRecipeTotalWeightG];
        if (rawTotalWeight != null && rawTotalWeight.isNotEmpty) {
          final parsed = CsvRowParser.parseDoubleOrNull(rawTotalWeight);
          if (parsed == null || !(parsed > 0 && parsed.isFinite)) {
            errors.add(
              'Row $rowNum: recipe_total_weight_g must be a positive '
              'finite number',
            );
            group.totalWeightRejected = true;
          } else {
            group.totalWeightOverride = parsed;
          }
        }
      }
      if (group.tags.isEmpty) {
        final tagsRaw = row[_kRecipeTags] ?? '';
        if (tagsRaw.isNotEmpty) {
          group.tags.addAll(tagsRaw
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty));
        }
      }

      final ingredientMeal = MealEntity(
        code: IdGenerator.getUniqueID(),
        name: ingredientName,
        brands: row[_kIngredientBrands]?.isNotEmpty == true
            ? row[_kIngredientBrands]
            : null,
        url: null,
        mealQuantity: '100',
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: 'g',
        servingSize: null,
        nutriments: MealNutrimentsEntity(
          energyKcal100: kcal,
          carbohydrates100: CsvRowParser.parseDoubleOrNull(row[_kIngredientCarbs]),
          fat100: CsvRowParser.parseDoubleOrNull(row[_kIngredientFat]),
          proteins100: CsvRowParser.parseDoubleOrNull(row[_kIngredientProtein]),
          sugars100: CsvRowParser.parseDoubleOrNull(row[_kIngredientSugars]),
          saturatedFat100: CsvRowParser.parseDoubleOrNull(row[_kIngredientSatFat]),
          fiber100: CsvRowParser.parseDoubleOrNull(row[_kIngredientFiber]),
        ),
        source: MealSourceEntity.custom,
      );

      group.ingredients.add(_PendingIngredient(
        meal: ingredientMeal,
        amount: amount,
        unit: unit,
      ));
    }

    // Build RecipeEntity for each group. Nutrition is computed inline so
    // recipes are saveable without any further wiring (the SaveRecipeUseCase
    // will recompute again on save, but having values populated here lets
    // tests and downstream callers see correct totals immediately).
    final compute = ComputeRecipeNutritionUseCase();
    final recipes = <ImportedCsvRecipe>[];
    for (final group in groups.values) {
      if (group.ingredients.isEmpty) continue;
      if (group.totalWeightRejected) continue;
      final ingredients = group.ingredients.map((p) {
        final convertedG = compute.convertAmountToGrams(
              amount: p.amount,
              unit: p.unit,
              servingQuantityG: p.meal.servingQuantity,
            ) ??
            0;
        return RecipeIngredientEntity(
          snapshotMeal: p.meal,
          amount: p.amount,
          unit: p.unit,
          convertedAmountG: convertedG,
        );
      }).toList();

      final result = compute.compute(
        ingredients,
        totalWeightOverride: group.totalWeightOverride,
      );

      final now = DateTime.now();
      recipes.add(ImportedCsvRecipe(
        recipe: RecipeEntity(
          id: IdGenerator.getUniqueID(),
          name: group.name,
          description: group.description,
          ingredients: ingredients,
          totalWeightG: result.totalWeightG,
          aggregatedNutrimentsPer100: result.perHundredG,
          createdAt: now,
          updatedAt: now,
          servingsCount: group.servingsCount,
          tags: List.unmodifiable(group.tags),
        ),
        totalWeightOverridden: group.totalWeightOverride != null,
      ));
    }

    return CsvRecipeImportResult(recipes: recipes, errors: errors);
  }

  /// Sample CSV text shipped with the app — header + two rows of one recipe
  /// so the user can see the expected shape (ingredients of the same recipe
  /// share the recipe-level columns, but only the first row needs them).
  static String sampleCsv() {
    final header = orderedColumns.join(',');
    return '$header\n'
        'Vanilla Cake,Classic vanilla,8,1500,"dessert,baking",Flour,King Arthur,200,g,340,70,1,10,0,0,3\n'
        'Vanilla Cake,,,,,Sugar,,150,g,387,100,0,0,100,0,0\n'
        'Vanilla Cake,,,,,Eggs,,200,g,155,1.1,11,13,1.1,3.3,0\n';
  }

  // _parseIntOrNull stays local because the recipe importer needs an
  // int (for servings count) and CsvRowParser only exposes the
  // double-with-comma-fallback variant the importers share.
  static int? _parseIntOrNull(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}

class _RecipeGroup {
  _RecipeGroup({required this.name});

  final String name;
  String? description;
  int? servingsCount;
  double? totalWeightOverride;
  /// Sticky flag set the first time a row supplies a malformed
  /// `recipe_total_weight_g` for this recipe. Once set, later rows in the
  /// same group cannot supply a good value, and the group is dropped at
  /// build time — the input is malformed enough that we do not save a
  /// partial recipe from it.
  bool totalWeightRejected = false;
  final Set<String> tags = <String>{};
  final List<_PendingIngredient> ingredients = [];
}

class _PendingIngredient {
  final MealEntity meal;
  final double amount;
  final String unit;

  _PendingIngredient({
    required this.meal,
    required this.amount,
    required this.unit,
  });
}
