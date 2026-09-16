import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'meal_dbo.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class MealDBO extends HiveObject {
  @HiveField(0)
  final String? code;
  @HiveField(1)
  final String? name;

  @HiveField(2)
  final String? brands;

  @HiveField(3)
  final String? thumbnailImageUrl;
  @HiveField(4)
  final String? mainImageUrl;

  @HiveField(5)
  final String? url;

  @HiveField(6)
  final String? mealQuantity;
  @HiveField(7)
  final String? mealUnit;
  @HiveField(8)
  final double? servingQuantity;
  @HiveField(9)
  final String? servingUnit;

  @HiveField(12)
  final String? servingSize;

  @HiveField(10)
  final MealSourceDBO source;

  @HiveField(11)
  final MealNutrimentsDBO nutriments;

  /// Relative slug (e.g. `meal_images/<code>.webp`) of a user-attached
  /// photo for this meal. Only ever populated for custom meals — OFF and
  /// FDC entries carry their thumbnails as remote URLs via
  /// [thumbnailImageUrl] / [mainImageUrl] instead. Stored relative so the
  /// data survives reinstalls and iOS sandbox refreshes.
  @HiveField(13)
  final String? localImagePath;

  /// True when this cached entry holds the full product record. Search
  /// results from Search-a-licious are cached thin (`false` / null on legacy
  /// rows); barcode and hydrated lookups are cached full (`true`). Used so a
  /// thin cache entry doesn't satisfy a hydration/barcode lookup and so
  /// [RemoteSearchCacheDataSource.cacheFromSearch] never downgrades a full
  /// entry. Nullable for backward compatibility with pre-existing rows.
  @HiveField(14)
  final bool? detailed;

  /// Backend food_source.code ('fdc_sr_legacy', 'bls'...) for foods from
  /// the Supabase backend. Null for OFF/custom/recipe meals and for rows
  /// cached before this field existed — the UI then falls back to the
  /// generic FoodData Central label.
  @HiveField(15)
  final String? backendSource;

  /// True when [name] is an unreviewed machine translation (see
  /// MealEntity.machineTranslatedName). Nullable for rows cached before
  /// this field existed — treated as false.
  @HiveField(16)
  final bool? machineTranslatedName;

  /// Which convention this row's nutriments were written under; see
  /// [currentDataVersion]. Null on rows written before the field existed —
  /// every intake, cached product and recipe ingredient from a released
  /// build — and for an Open Food Facts row that is the signal
  /// `OffMicronutrientRepair` acts on (#1152). Copied through JSON and CSV
  /// exports so a bundle re-imported into a repaired install is not scaled
  /// a second time.
  @HiveField(17)
  final int? dataVersion;

  /// Rows at this version or above carry every micronutrient in the app's
  /// units: milligrams for the minerals, cholesterol and vitamins C, B6 and
  /// niacin, micrograms for vitamins A, D and B12. Below it (null included)
  /// an Open Food Facts row still holds the raw grams the API sends, which
  /// #775 (`MealNutrimentsEntity.fromOffNutriments`) had copied through
  /// unconverted.
  static const dataVersionOffMicronutrientsInAppUnits = 1;

  /// Stamped on every row [fromMealEntity] produces. Bump it, and add a
  /// repair step for the versions below, whenever the stored meaning of a
  /// field changes again.
  static const currentDataVersion = dataVersionOffMicronutrientsInAppUnits;

  MealDBO({
    required this.code,
    required this.name,
    required this.brands,
    required this.thumbnailImageUrl,
    required this.mainImageUrl,
    required this.url,
    required this.mealQuantity,
    required this.mealUnit,
    required this.servingQuantity,
    required this.servingUnit,
    required this.servingSize,
    required this.nutriments,
    required this.source,
    this.localImagePath,
    this.detailed,
    this.backendSource,
    this.machineTranslatedName,
    this.dataVersion,
  });

  /// Entities always carry app units — every remote mapping converts on
  /// the way in — so a row built from one is stamped current.
  factory MealDBO.fromMealEntity(MealEntity mealEntity) => MealDBO(
        code: mealEntity.code,
        name: mealEntity.name,
        brands: mealEntity.brands,
        thumbnailImageUrl: mealEntity.thumbnailImageUrl,
        mainImageUrl: mealEntity.mainImageUrl,
        url: mealEntity.url,
        mealQuantity: mealEntity.mealQuantity,
        mealUnit: mealEntity.mealUnit,
        servingQuantity: mealEntity.servingQuantity,
        servingUnit: mealEntity.servingUnit,
        servingSize: mealEntity.servingSize,
        nutriments: MealNutrimentsDBO.fromProductNutrimentsEntity(
          mealEntity.nutriments,
        ),
        source: MealSourceDBO.fromMealSourceEntity(mealEntity.source),
        localImagePath: mealEntity.localImagePath,
        detailed: mealEntity.detailed,
        backendSource: mealEntity.backendSource,
        machineTranslatedName: mealEntity.machineTranslatedName,
        dataVersion: currentDataVersion,
      );

  factory MealDBO.fromJson(Map<String, dynamic> json) =>
      _$MealDBOFromJson(json);

  Map<String, dynamic> toJson() => _$MealDBOToJson(this);
}

@HiveType(typeId: 14)
enum MealSourceDBO {
  @HiveField(0)
  unknown,
  @HiveField(1)
  custom,
  @HiveField(2)
  off,
  @HiveField(3)
  fdc,
  @HiveField(4)
  recipe;

  factory MealSourceDBO.fromMealSourceEntity(MealSourceEntity entity) {
    MealSourceDBO mealSourceDBO;
    switch (entity) {
      case MealSourceEntity.unknown:
        mealSourceDBO = MealSourceDBO.unknown;
        break;
      case MealSourceEntity.custom:
        mealSourceDBO = MealSourceDBO.custom;
        break;
      case MealSourceEntity.off:
        mealSourceDBO = MealSourceDBO.off;
        break;
      case MealSourceEntity.fdc:
        mealSourceDBO = MealSourceDBO.fdc;
        break;
      case MealSourceEntity.recipe:
        mealSourceDBO = MealSourceDBO.recipe;
        break;
    }
    return mealSourceDBO;
  }
}
