import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_ingredient_dbo.dart';

part 'recipe_dbo.g.dart';

@HiveType(typeId: 16)
@JsonSerializable()
class RecipeDBO extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final List<RecipeIngredientDBO> ingredients;

  @HiveField(4)
  final double totalWeightG;

  @HiveField(5)
  final MealNutrimentsDBO aggregatedNutrimentsPer100;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  // Optional. When set, the recipe can be logged "by serving" via the existing
  // MealDetailScreen unit dropdown — see RecipeEntity.toMealEntity().
  @HiveField(8)
  final int? servingsCount;

  // Optional free-text tags ("breakfast", "dessert", "vegan", ...). Nullable
  // for backward-compat with recipes saved before tags existed: an older
  // record decodes with tags == null which entities normalize to an empty
  // list.
  @HiveField(9)
  final List<String>? tags;

  // HiveField(10) is reserved for an unrelated in-flight change (#167).
  // Do not reuse it here.

  // Relative path to a user-attached photo, under the app's private
  // documents directory (e.g. `recipe_images/<id>.webp`). Storing the
  // relative slug — not the absolute path — keeps the value stable across
  // iOS sandbox refreshes and Android app reinstalls, where the documents
  // directory's parent path can change.
  @HiveField(11)
  final String? imagePath;

  RecipeDBO({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.totalWeightG,
    required this.aggregatedNutrimentsPer100,
    required this.createdAt,
    required this.updatedAt,
    required this.servingsCount,
    required this.tags,
    required this.imagePath,
  });

  factory RecipeDBO.fromJson(Map<String, dynamic> json) =>
      _$RecipeDBOFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDBOToJson(this);
}
