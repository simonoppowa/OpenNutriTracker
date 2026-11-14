import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

class RecipeEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<RecipeIngredientEntity> ingredients;
  final double totalWeightG;
  final MealNutrimentsEntity aggregatedNutrimentsPer100;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? servingsCount;
  // Free-text categorization. Empty list = uncategorized. Stored on the
  // entity as non-nullable for ergonomics; the DBO carries a nullable list
  // for backwards compat with older saved records.
  final List<String> tags;
  // Relative slug (e.g. `recipe_images/<id>.webp`) under the app's private
  // documents directory. Null when no photo has been attached. Callers
  // resolve the absolute path via `path_provider` at read/write time so
  // we never persist a stale sandbox-specific prefix.
  final String? imagePath;

  const RecipeEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.totalWeightG,
    required this.aggregatedNutrimentsPer100,
    required this.createdAt,
    required this.updatedAt,
    required this.servingsCount,
    this.tags = const [],
    this.imagePath,
  });

  factory RecipeEntity.fromDBO(RecipeDBO dbo) {
    return RecipeEntity(
      id: dbo.id,
      name: dbo.name,
      description: dbo.description,
      ingredients:
          dbo.ingredients.map(RecipeIngredientEntity.fromDBO).toList(),
      totalWeightG: dbo.totalWeightG,
      aggregatedNutrimentsPer100: MealNutrimentsEntity.fromMealNutrimentsDBO(
        dbo.aggregatedNutrimentsPer100,
      ),
      createdAt: dbo.createdAt,
      updatedAt: dbo.updatedAt,
      servingsCount: dbo.servingsCount,
      tags: dbo.tags ?? const [],
      imagePath: dbo.imagePath,
    );
  }

  RecipeDBO toDBO() {
    return RecipeDBO(
      id: id,
      name: name,
      description: description,
      ingredients: ingredients.map((i) => i.toDBO()).toList(),
      totalWeightG: totalWeightG,
      aggregatedNutrimentsPer100:
          MealNutrimentsDBO.fromProductNutrimentsEntity(
        aggregatedNutrimentsPer100,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      servingsCount: servingsCount,
      tags: tags.isEmpty ? null : tags,
      imagePath: imagePath,
    );
  }

  // Adapts the recipe to a MealEntity so it slots into the existing search
  // results, MealDetailScreen, and IntakeDBO snapshot pipeline with no
  // special-case branches downstream. When `servingsCount` is set, the
  // returned MealEntity exposes serving values so the unit dropdown offers
  // "serving" alongside grams.
  //
  // A batch with no weight has no serving to scale: offering one logged 0 g
  // whatever the quantity, so such a recipe is logged in grams only.
  MealEntity toMealEntity() {
    final hasServings =
        servingsCount != null && servingsCount! > 0 && totalWeightG > 0;
    final servingG = hasServings ? totalWeightG / servingsCount! : null;
    return MealEntity(
      code: id,
      name: name,
      brands: null,
      thumbnailImageUrl: null,
      mainImageUrl: null,
      url: null,
      mealQuantity: totalWeightG.toString(),
      mealUnit: 'g',
      servingQuantity: servingG,
      servingUnit: hasServings ? 'g' : null,
      // One serving and what it weighs, which is what the unit dropdown
      // shows. "4 servings" — the batch's count — read as if a serving were
      // the whole batch, or the count a weight (#833). Kept in English like
      // every stored serving label; `localizeServingLabel` translates
      // "serving" and `imperialServingLabel` the grams at display time.
      servingSize: servingG != null
          ? '1 serving (${_formatGrams(servingG)} g)'
          : null,
      nutriments: aggregatedNutrimentsPer100,
      source: MealSourceEntity.recipe,
    );
  }

  /// One decimal at most, without a trailing zero: 300, 333.3, 1.
  static String _formatGrams(double grams) {
    final fixed = grams.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  RecipeEntity copyWith({
    String? id,
    String? name,
    String? description,
    List<RecipeIngredientEntity>? ingredients,
    double? totalWeightG,
    MealNutrimentsEntity? aggregatedNutrimentsPer100,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? servingsCount,
    List<String>? tags,
    String? imagePath,
    bool clearServingsCount = false,
    bool clearDescription = false,
    bool clearImagePath = false,
  }) {
    return RecipeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      ingredients: ingredients ?? this.ingredients,
      totalWeightG: totalWeightG ?? this.totalWeightG,
      aggregatedNutrimentsPer100:
          aggregatedNutrimentsPer100 ?? this.aggregatedNutrimentsPer100,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      servingsCount:
          clearServingsCount ? null : (servingsCount ?? this.servingsCount),
      tags: tags ?? this.tags,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        ingredients,
        totalWeightG,
        aggregatedNutrimentsPer100,
        createdAt,
        updatedAt,
        servingsCount,
        tags,
        imagePath,
      ];
}
