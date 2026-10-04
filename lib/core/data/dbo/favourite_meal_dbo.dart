import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';

part 'favourite_meal_dbo.g.dart';

/// One entry on the user's Favourites list (#1307): a snapshot of the meal,
/// so the list renders and the detail page opens offline the way the Recently
/// list does from its intake snapshots, and the moment it was starred, which
/// orders the list newest first.
///
/// Stored under [keyFor] of its meal, so starring the same food twice — from
/// a search result and again from its detail page — keeps one entry.
@HiveType(typeId: 23)
@JsonSerializable()
class FavouriteMealDBO extends HiveObject {
  @HiveField(0)
  final MealDBO meal;

  @HiveField(1)
  final DateTime addedAt;

  FavouriteMealDBO({required this.meal, required this.addedAt});

  /// The identity of a food across every source, the same one search uses to
  /// deduplicate its merged list: the source plus the barcode (Open Food
  /// Facts), the `food_summary` id (backend), the generated id (custom meals)
  /// or the recipe id — falling back to the name for a legacy custom meal
  /// saved without a code. The source prefix keeps a backend id from ever
  /// colliding with a barcode of the same digits.
  static String keyFor(MealSourceDBO source, String? code, String? name) =>
      '${source.name}:${code ?? name ?? ''}';

  String get mealKey => keyFor(meal.source, meal.code, meal.name);

  factory FavouriteMealDBO.fromJson(Map<String, dynamic> json) =>
      _$FavouriteMealDBOFromJson(json);

  Map<String, dynamic> toJson() => _$FavouriteMealDBOToJson(this);
}
