import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:uuid/uuid.dart';

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
  ///
  /// It is also the Hive key, and Hive writes a string key's length in one
  /// byte, so a key must fit in [maxKeyBytes] of UTF-8. Every key that fits
  /// is used as is; a longer one (a long name, a long code from an imported
  /// file) becomes the source, `#` and a name-based UUID (v5, SHA-1) of the
  /// whole identity. The same identity always hashes to the same key, two
  /// different ones practically never meet, and no hashed key can equal an
  /// unhashed one, which always has `:` right after the source.
  static String keyFor(MealSourceDBO source, String? code, String? name) {
    final identity = '${source.name}:${code ?? name ?? ''}';
    if (utf8.encode(identity).length <= maxKeyBytes) return identity;
    final hash = IdGenerator.uuid.v5(
      Namespace.url.value,
      'opennutritracker-favourite:$identity',
    );
    return '${source.name}#$hash';
  }

  /// The longest string key, in UTF-8 bytes, Hive stores intact.
  static const maxKeyBytes = 255;

  String get mealKey => keyFor(meal.source, meal.code, meal.name);

  factory FavouriteMealDBO.fromJson(Map<String, dynamic> json) =>
      _$FavouriteMealDBOFromJson(json);

  Map<String, dynamic> toJson() => _$FavouriteMealDBOToJson(this);
}
