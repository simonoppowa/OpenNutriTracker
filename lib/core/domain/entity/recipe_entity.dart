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
    );
  }

  // Adapts the recipe to a MealEntity so it slots into the existing search
  // results, MealDetailScreen, and IntakeDBO snapshot pipeline with no
  // special-case branches downstream. When `servingsCount` is set, the
  // returned MealEntity exposes serving values so the unit dropdown offers
  // "serving" alongside grams.
  MealEntity toMealEntity() {
    final hasServings = servingsCount != null && servingsCount! > 0;
    return MealEntity(
      code: id,
      name: name,
      brands: null,
      thumbnailImageUrl: null,
      mainImageUrl: null,
      url: null,
      mealQuantity: totalWeightG.toString(),
      mealUnit: 'g',
      servingQuantity: hasServings ? totalWeightG / servingsCount! : null,
      servingUnit: hasServings ? 'g' : null,
      servingSize: hasServings ? '$servingsCount servings' : null,
      nutriments: aggregatedNutrimentsPer100,
      source: MealSourceEntity.recipe,
    );
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
    bool clearServingsCount = false,
    bool clearDescription = false,
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
      ];
}
