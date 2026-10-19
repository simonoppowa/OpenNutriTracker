import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

enum FavoriteKind { food, recipe }

/// One favourite of the profile (#37): a food (from a database or the
/// user's own, kept as a snapshot so it logs offline) or a recipe (by id).
class FavoriteEntry extends Equatable {
  final String id;
  final FavoriteKind kind;
  final String name;
  final MealEntity? meal;
  final String? recipeId;
  final DateTime createdAt;

  /// Position in the favourites list, lowest first.
  final int sortIndex;

  const FavoriteEntry({
    required this.id,
    required this.kind,
    required this.name,
    this.meal,
    this.recipeId,
    required this.createdAt,
    required this.sortIndex,
  });

  /// The id a meal is a favourite under: its source and code, or for a
  /// recipe listed as a meal the recipe's id.
  static String idForMeal(MealEntity meal) =>
      meal.source == MealSourceEntity.recipe
      ? idForRecipe(meal.code ?? '')
      : 'meal:${meal.source.name}:${meal.code}';

  static String idForRecipe(String recipeId) => 'recipe:$recipeId';

  bool get isOwnFood => meal?.source == MealSourceEntity.custom;

  FavoriteEntry withSortIndex(int index) => FavoriteEntry(
    id: id,
    kind: kind,
    name: name,
    meal: meal,
    recipeId: recipeId,
    createdAt: createdAt,
    sortIndex: index,
  );

  /// Plain JSON: the meal snapshot's nested values are encoded too.
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'meal': meal == null
        ? null
        : jsonDecode(jsonEncode(MealDBO.fromMealEntity(meal!).toJson())),
    'recipeId': recipeId,
    'createdAt': createdAt.toIso8601String(),
    'sortIndex': sortIndex,
  };

  /// Throws a [FormatException] for an entry that is not one.
  factory FavoriteEntry.fromJson(Map<String, dynamic> json) {
    final kind = FavoriteKind.values
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    final id = json['id'];
    final name = json['name'];
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final sortIndex = json['sortIndex'];
    final meal = json['meal'];
    final recipeId = json['recipeId'];
    if (kind == null ||
        id is! String ||
        name is! String ||
        createdAt == null ||
        sortIndex is! int ||
        (kind == FavoriteKind.food && meal is! Map<String, dynamic>) ||
        (kind == FavoriteKind.recipe && recipeId is! String)) {
      throw FormatException('invalid favourite: $json');
    }
    return FavoriteEntry(
      id: id,
      kind: kind,
      name: name,
      meal: kind == FavoriteKind.food
          ? MealEntity.fromMealDBO(
              MealDBO.fromJson(meal as Map<String, dynamic>),
            )
          : null,
      recipeId: kind == FavoriteKind.recipe ? recipeId as String : null,
      createdAt: createdAt,
      sortIndex: sortIndex,
    );
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    name,
    meal?.code,
    recipeId,
    createdAt,
    sortIndex,
  ];
}
