import 'dart:convert';
import 'dart:io' show gzip;

import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/domain/entity/shared_recipe_payload.dart';

class SharedMealParseException implements Exception {
  final String message;
  SharedMealParseException(this.message);
}

// Emit int for whole numbers, round to 1dp otherwise — shrinks JSON before compression
num? _compact(double? v) {
  if (v == null) return null;
  if (v == v.truncateToDouble()) return v.toInt();
  return double.parse(v.toStringAsFixed(1));
}

// OFF ref field order: [barcode, amount, unit]
class SharedMealOffRef {
  final String barcode;
  final double amount;
  final String unit;

  const SharedMealOffRef({
    required this.barcode,
    required this.amount,
    required this.unit,
  });

  factory SharedMealOffRef.fromIntakeEntity(IntakeEntity intake) {
    return SharedMealOffRef(
      barcode: intake.meal.code!,
      amount: intake.amount,
      unit: intake.unit,
    );
  }

  factory SharedMealOffRef.fromArray(List<dynamic> a) {
    return SharedMealOffRef(
      barcode: a[0] as String,
      amount: (a[1] as num).toDouble(),
      unit: (a[2] as String?) ?? 'g',
    );
  }

  List<dynamic> toArray() => [barcode, _compact(amount), unit];
}

// Array field order: [name, brands, unit, amount, ec, cb, ft, pr, sg, sf, fb,
//                     thumbUrl, imgUrl, source, code]
//
// `source` is 'custom' or 'fdc' — added in v2. Null/absent means 'custom' so
// v1 payloads still parse correctly. `code` (added in v2) lets cached FDC
// items round-trip with their fdcId so the receiver can dedupe future
// searches against the same id.
class SharedMealItem {
  final String? name;
  final String? brands;
  final String unit;
  final double amount;
  final double? energyKcal100;
  final double? carbohydrates100;
  final double? fat100;
  final double? proteins100;
  final double? sugars100;
  final double? saturatedFat100;
  final double? fiber100;
  final String? thumbnailImageUrl;
  final String? mainImageUrl;
  final MealSourceEntity source;
  final String? code;

  const SharedMealItem({
    required this.name,
    required this.brands,
    required this.unit,
    required this.amount,
    required this.energyKcal100,
    required this.carbohydrates100,
    required this.fat100,
    required this.proteins100,
    required this.sugars100,
    required this.saturatedFat100,
    required this.fiber100,
    required this.thumbnailImageUrl,
    required this.mainImageUrl,
    required this.source,
    required this.code,
  });

  factory SharedMealItem.fromIntakeEntity(IntakeEntity intake) {
    return SharedMealItem(
      name: intake.meal.name,
      brands: intake.meal.brands,
      unit: intake.unit,
      amount: intake.amount,
      energyKcal100: intake.meal.nutriments.energyKcal100,
      carbohydrates100: intake.meal.nutriments.carbohydrates100,
      fat100: intake.meal.nutriments.fat100,
      proteins100: intake.meal.nutriments.proteins100,
      sugars100: intake.meal.nutriments.sugars100,
      saturatedFat100: intake.meal.nutriments.saturatedFat100,
      fiber100: intake.meal.nutriments.fiber100,
      thumbnailImageUrl: intake.meal.thumbnailImageUrl,
      mainImageUrl: intake.meal.mainImageUrl,
      source: intake.meal.source,
      code: intake.meal.code,
    );
  }

  factory SharedMealItem.fromArray(List<dynamic> a) {
    num? atNum(int i) => a.length > i ? a[i] as num? : null;
    String? atStr(int i) => a.length > i ? a[i] as String? : null;
    final sourceStr = atStr(13);
    final source = sourceStr == 'fdc'
        ? MealSourceEntity.fdc
        : MealSourceEntity.custom;
    return SharedMealItem(
      name: a[0] as String?,
      brands: a[1] as String?,
      unit: (a[2] as String?) ?? 'g',
      amount: (a[3] as num?)?.toDouble() ?? 100.0,
      energyKcal100: atNum(4)?.toDouble(),
      carbohydrates100: atNum(5)?.toDouble(),
      fat100: atNum(6)?.toDouble(),
      proteins100: atNum(7)?.toDouble(),
      sugars100: atNum(8)?.toDouble(),
      saturatedFat100: atNum(9)?.toDouble(),
      fiber100: atNum(10)?.toDouble(),
      thumbnailImageUrl: atStr(11),
      mainImageUrl: atStr(12),
      source: source,
      code: atStr(14),
    );
  }

  List<dynamic> toArray() {
    return [
      name,
      brands,
      unit,
      _compact(amount),
      _compact(energyKcal100),
      _compact(carbohydrates100),
      _compact(fat100),
      _compact(proteins100),
      _compact(sugars100),
      _compact(saturatedFat100),
      _compact(fiber100),
      thumbnailImageUrl,
      mainImageUrl,
      source == MealSourceEntity.fdc ? 'fdc' : 'custom',
      code,
    ];
  }

  MealEntity toMealEntity() {
    return MealEntity(
      // FDC items keep their original code so the receiver's cache can dedupe
      // future searches; custom items get a fresh UUID since they're a new
      // entry in the receiver's library.
      code: source == MealSourceEntity.fdc && code != null
          ? code
          : IdGenerator.getUniqueID(),
      name: name,
      brands: brands,
      thumbnailImageUrl: thumbnailImageUrl,
      mainImageUrl: mainImageUrl,
      url: null,
      mealQuantity: null,
      mealUnit: null,
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: MealNutrimentsEntity(
        energyKcal100: energyKcal100,
        carbohydrates100: carbohydrates100,
        fat100: fat100,
        proteins100: proteins100,
        sugars100: sugars100,
        saturatedFat100: saturatedFat100,
        fiber100: fiber100,
      ),
      source: source,
    );
  }
}

// One recipe embedded inside a meal share. Carries the full SharedRecipePayload
// (so the receiver gets the ingredient breakdown) plus the amount and unit
// from the original intake.
class SharedMealRecipeItem {
  final SharedRecipePayload recipe;
  final double amount;
  final String unit;

  const SharedMealRecipeItem({
    required this.recipe,
    required this.amount,
    required this.unit,
  });

  factory SharedMealRecipeItem.fromArray(List<dynamic> a) {
    return SharedMealRecipeItem(
      amount: (a[0] as num).toDouble(),
      unit: (a[1] as String?) ?? 'g',
      recipe: SharedRecipePayload.fromJsonArray(a[2] as List<dynamic>),
    );
  }

  List<dynamic> toArray() => [_compact(amount), unit, recipe.toJsonArray()];
}

class SharedMealPayload {
  // v1: [version, offRefs, items]                — no source on items, no recipes
  // v2: [version, offRefs, items, recipes]       — items carry source ('custom'|'fdc'),
  //                                                 recipes are full embedded recipe payloads
  static const int _currentVersion = 2;
  static const int _minSupportedVersion = 1;

  // Cap the post-decompression payload size to make zip-bomb-style QR
  // codes a clean parse failure rather than an OOM. 64 KiB comfortably
  // covers the largest legitimate share (a meal-share with several
  // embedded recipes) while staying well below memory pressure on any
  // device the app targets.
  static const int _kMaxDecompressedBytes = 64 * 1024;

  final int version;
  final List<SharedMealOffRef> offRefs;
  final List<SharedMealItem> items;
  final List<SharedMealRecipeItem> recipes;

  int get totalCount => offRefs.length + items.length + recipes.length;

  const SharedMealPayload({
    required this.version,
    required this.offRefs,
    required this.items,
    required this.recipes,
  });

  /// Build a payload from a list of diary intakes. Each intake routes by
  /// `meal.source`:
  ///   - off + code      → offRef (barcode-only; receiver fetches + caches)
  ///   - fdc             → SharedMealItem with source='fdc' (snapshot;
  ///                       receiver caches in RemoteSearchCacheDataSource)
  ///   - recipe + code   → recipes bucket (full embedded recipe via
  ///                       [recipeRepository] lookup; receiver saves to
  ///                       RecipeRepository). Falls back to a custom
  ///                       SharedMealItem when the repository or recipe
  ///                       isn't found.
  ///   - custom / other  → SharedMealItem with source='custom' (saved to
  ///                       CustomMealDataSource on receive)
  factory SharedMealPayload.fromIntakeList(
    List<IntakeEntity> intakes, {
    RecipeRepository? recipeRepository,
  }) {
    final offRefs = <SharedMealOffRef>[];
    final items = <SharedMealItem>[];
    final recipes = <SharedMealRecipeItem>[];

    for (final intake in intakes) {
      final meal = intake.meal;
      if (meal.source == MealSourceEntity.off && meal.code != null) {
        offRefs.add(SharedMealOffRef.fromIntakeEntity(intake));
      } else if (meal.source == MealSourceEntity.recipe &&
          meal.code != null &&
          recipeRepository != null) {
        final recipe = recipeRepository.getRecipeById(meal.code!);
        if (recipe != null) {
          recipes.add(
            SharedMealRecipeItem(
              recipe: SharedRecipePayload.fromRecipe(recipe),
              amount: intake.amount,
              unit: intake.unit,
            ),
          );
          continue;
        }
        // Recipe template gone: degrade to a custom snapshot from the intake.
        items.add(SharedMealItem.fromIntakeEntity(intake));
      } else {
        items.add(SharedMealItem.fromIntakeEntity(intake));
      }
    }

    return SharedMealPayload(
      version: _currentVersion,
      offRefs: offRefs,
      items: items,
      recipes: recipes,
    );
  }

  factory SharedMealPayload.fromJsonString(String input) {
    try {
      String jsonString;
      try {
        final decompressed = gzip.decode(
          base64Url.decode(base64Url.normalize(input)),
        );
        if (decompressed.length > _kMaxDecompressedBytes) {
          throw SharedMealParseException(
            'Payload too large to decode (>$_kMaxDecompressedBytes bytes)',
          );
        }
        jsonString = utf8.decode(decompressed);
      } on SharedMealParseException {
        // Size violations are real errors, not malformed input — don't
        // fall back to treating the raw input as JSON.
        rethrow;
      } catch (_) {
        jsonString = input;
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        throw SharedMealParseException('Invalid payload format');
      }

      final version = decoded[0] as int;
      if (version < _minSupportedVersion || version > _currentVersion) {
        throw SharedMealParseException('Unsupported payload version: $version');
      }

      final rawOffRefs = decoded[1] as List<dynamic>;
      final rawItems = decoded[2] as List<dynamic>;
      // recipes bucket is v2+; older payloads simply don't have it.
      final rawRecipes = decoded.length > 3
          ? decoded[3] as List<dynamic>
          : const [];

      return SharedMealPayload(
        version: version,
        offRefs: rawOffRefs
            .map((e) => SharedMealOffRef.fromArray(e as List<dynamic>))
            .toList(),
        items: rawItems
            .map((e) => SharedMealItem.fromArray(e as List<dynamic>))
            .toList(),
        recipes: rawRecipes
            .map((e) => SharedMealRecipeItem.fromArray(e as List<dynamic>))
            .toList(),
      );
    } on SharedMealParseException {
      rethrow;
    } catch (e) {
      throw SharedMealParseException('Failed to parse payload: $e');
    }
  }

  String toJsonString() {
    final json = jsonEncode([
      version,
      offRefs.map((r) => r.toArray()).toList(),
      items.map((i) => i.toArray()).toList(),
      recipes.map((r) => r.toArray()).toList(),
    ]);
    return base64Url.encode(gzip.encode(utf8.encode(json)));
  }

  List<MealEntity> toMealEntities() =>
      items.map((i) => i.toMealEntity()).toList();
}
