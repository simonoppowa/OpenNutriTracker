import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

class MealEntity extends Equatable {
  static const liquidUnits = {'ml', 'l', 'dl', 'cl', 'fl oz', 'fl.oz'};
  static const solidUnits = {'kg', 'g', 'mg', 'µg', 'oz'};

  final String? code;
  final String? name;

  final String? brands;

  final String? thumbnailImageUrl;
  final String? mainImageUrl;

  final String? url;

  final String? mealQuantity;
  final String? mealUnit;
  final double? servingQuantity;
  final String? servingUnit;
  final String? servingSize;

  // Issue #158: many OFF products carry serving data (servingQuantity or
  // servingSize) but no overall package `quantity`, which left `servingUnit`
  // null and made the meal-detail dropdown default to 100 g/ml on every
  // scan. Treat a product as having serving values when either side of the
  // OFF data is present — the dropdown text in `_getServingDropdownItem`
  // already falls back to `servingSize` when `servingUnit` is missing.
  bool get hasServingValues => servingQuantity != null || servingSize != null;

  final MealSourceEntity source;

  /// Backend food_source.code ('fdc_sr_legacy', 'bls', 'indb'...) for
  /// meals from the Supabase backend, null for OFF/custom/recipe meals
  /// and legacy cached entries. Persisted so the UI can name the actual
  /// database a food came from (see SPConst.foodSourceDisplayNames) even
  /// though [source] groups them all under [MealSourceEntity.fdc].
  final String? backendSource;

  /// True when [name] is an unreviewed machine translation from the
  /// backend's food_translation table. The meal detail page shows a small
  /// disclosure hint under the title for these.
  final bool machineTranslatedName;

  /// Relative path (`meal_images/<code>.webp`) to a user-attached photo
  /// for a custom meal, or null if none is set. Resolved to an absolute
  /// path at render time via `MealImageStorage.absolutePath`. Always
  /// null for OFF / FDC / recipe-derived meals — those carry remote URLs
  /// in `thumbnailImageUrl` / `mainImageUrl` instead.
  final String? localImagePath;

  final MealNutrimentsEntity nutriments;

  /// Whether this meal carries the full product record (serving fields and
  /// micronutrients). Open Food Facts text search now comes from the
  /// Search-a-licious index, which only returns a thin projection
  /// (`detailed == false`); opening such a result hydrates it to the full
  /// record via the v2 product endpoint (`detailed == true`). Barcode scans
  /// and FDC/custom meals are always full. See [hasServingValues] and the
  /// hydration step in MealDetailBloc.
  final bool detailed;

  bool get isLiquid => liquidUnits.contains(mealUnit);

  bool get isSolid => solidUnits.contains(mealUnit);

  const MealEntity({
    required this.code,
    required this.name,
    this.brands,
    this.thumbnailImageUrl,
    this.mainImageUrl,
    required this.url,
    required this.mealQuantity,
    required this.mealUnit,
    required this.servingQuantity,
    required this.servingUnit,
    required this.servingSize,
    required this.nutriments,
    required this.source,
    this.backendSource,
    this.machineTranslatedName = false,
    this.localImagePath,
    this.detailed = false,
  });

  factory MealEntity.empty() => MealEntity(
    code: IdGenerator.getUniqueID(),
    name: null,
    url: null,
    mealQuantity: null,
    mealUnit: 'gml',
    servingQuantity: null,
    servingUnit: 'gml',
    servingSize: '',
    nutriments: MealNutrimentsEntity.empty(),
    source: MealSourceEntity.custom,
  );

  factory MealEntity.fromMealDBO(MealDBO mealDBO) => MealEntity(
    code: mealDBO.code,
    name: mealDBO.name,
    brands: mealDBO.brands,
    thumbnailImageUrl: mealDBO.thumbnailImageUrl,
    mainImageUrl: mealDBO.mainImageUrl,
    url: mealDBO.url,
    mealQuantity: mealDBO.mealQuantity,
    mealUnit: mealDBO.mealUnit,
    servingQuantity: mealDBO.servingQuantity,
    servingUnit: mealDBO.servingUnit,
    servingSize: mealDBO.servingSize,
    nutriments: MealNutrimentsEntity.fromMealNutrimentsDBO(mealDBO.nutriments),
    source: MealSourceEntity.fromMealSourceDBO(mealDBO.source),
    backendSource: mealDBO.backendSource,
    machineTranslatedName: mealDBO.machineTranslatedName ?? false,
    localImagePath: mealDBO.localImagePath,
    detailed: mealDBO.detailed ?? false,
  );

  /// [detailed] is true for full-product responses (the v2 barcode endpoint),
  /// false for the thin Search-a-licious text-search projection.
  factory MealEntity.fromOFFProduct(
    OFFProductDTO offProduct, {
    bool detailed = false,
  }) {
    // Unit precedence: OFF's normalised serving unit, then the unit parsed
    // from the serving_size text ("30 g"), then the package quantity string.
    // Serving data beats the package because it describes how the product
    // is actually consumed — and package quantity is missing often enough
    // that deriving from it alone left the unit null ("N/A" in the meal
    // detail's unit dropdown).
    final unit =
        _normalizeOffUnit(offProduct.serving_quantity_unit) ??
        _tryGetUnit(offProduct.serving_size) ??
        _tryGetUnit(offProduct.quantity);
    return MealEntity(
      code: offProduct.code,
      name: offProduct.getLocaleName(
        SupportedLanguage.fromCode(Platform.localeName),
      ),
      brands: offProduct.brands,
      thumbnailImageUrl: offProduct.image_front_thumb_url,
      mainImageUrl: offProduct.image_front_url,
      url: offProduct.url,
      mealQuantity: offProduct.product_quantity?.toString(),
      mealUnit: unit,
      servingQuantity: _tryQuantityCast(offProduct.serving_quantity),
      servingUnit: unit,
      servingSize: offProduct.serving_size,
      nutriments: MealNutrimentsEntity.fromOffNutriments(offProduct.nutriments),
      source: MealSourceEntity.off,
      detailed: detailed,
    );
  }

  /// Maps OFF's serving_quantity_unit to the app's g/ml entry units.
  /// Usually already 'g' or 'ml'; the volume variants collapse to ml and
  /// anything unrecognised returns null so the next fallback can try.
  static String? _normalizeOffUnit(String? rawUnit) {
    switch (rawUnit?.trim().toLowerCase()) {
      case 'g':
        return 'g';
      case 'ml':
      case 'cl':
      case 'dl':
      case 'l':
        return 'ml';
      default:
        return null;
    }
  }

  factory MealEntity.fromFDCFood(FDCFoodDTO fdcFood) {
    final fdcId = fdcFood.fdcId?.toInt().toString();

    return MealEntity(
      code: fdcId,
      name: fdcFood.description,
      brands: fdcFood.brandName,
      url: FDCConst.getFoodDetailUrlString(fdcId),
      mealQuantity: fdcFood.packageWeight,
      mealUnit: fdcFood.servingSizeUnit,
      servingQuantity: fdcFood.servingSize,
      servingUnit: fdcFood.servingSizeUnit,
      servingSize: fdcFood.servingSizeUnit,
      nutriments: MealNutrimentsEntity.fromFDCNutriments(fdcFood.foodNutrients),
      source: MealSourceEntity.fdc,
    );
  }

  factory MealEntity.fromSpFood(SpFoodDTO foodItem) {
    final defaultUnit = _spDefaultUnit(foodItem);
    return MealEntity(
      code: foodItem.foodId?.toString(),
      name: foodItem.displayName,
      brands: foodItem.brands,
      // Only USDA FDC foods have a public detail page to link to; foods
      // from the other backend sources (BLS, INDB, TBCA...) link nowhere.
      url: foodItem.isFdc
          ? FDCConst.getFoodDetailUrlString(foodItem.sourceCode)
          : null,
      mealQuantity: null,
      mealUnit: defaultUnit,
      servingQuantity: foodItem.servingGramWeight,
      servingUnit: defaultUnit,
      servingSize: _spServingLabel(foodItem),
      nutriments: MealNutrimentsEntity.fromSpFoodSummary(foodItem),
      // All Supabase backend foods keep the fdc source tag: MealSourceDBO
      // is persisted in Hive, so a per-source enum value would need a data
      // migration. `fdc` here means "reference food database" as opposed
      // to OFF/custom; the true origin is carried in [backendSource].
      source: MealSourceEntity.fdc,
      backendSource: foodItem.source,
      machineTranslatedName: foodItem.displayNameIsMachineTranslated,
    );
  }

  /// Default entry unit for a backend food. The nutrient basis is per
  /// 100 g everywhere, but beverages are naturally measured in
  /// millilitres: BLS encodes its food group in the first letter of the
  /// source code, and groups N (alkoholfreie Getränke) and P (alkoholische
  /// Getränke) are drinks. Everything else — and every non-BLS source,
  /// which carries no such classification — defaults to grams rather than
  /// the old 'g/ml' placeholder, which the meal detail rendered as "N/A".
  static String _spDefaultUnit(SpFoodDTO foodItem) {
    final sourceCode = foodItem.sourceCode;
    if (foodItem.source == SPConst.blsSourceCode &&
        sourceCode != null &&
        sourceCode.isNotEmpty &&
        SPConst.blsBeverageGroups.contains(sourceCode[0].toUpperCase())) {
      return 'ml';
    }
    return 'g';
  }

  /// Matches an explicit weight/volume figure ("38 g", "240ml") so labels
  /// that already state one don't get a second appended.
  static final _containsWeightFigure = RegExp(
    r'\d\s*(g|kg|ml|l|oz)\b',
    caseSensitive: false,
  );

  /// Human-readable default-serving label in the style of the FDC website
  /// ("1 slice (38 g)", "1 cup, sliced (240 g)"), falling back to the
  /// serving weight in grams when the portion has no description at all.
  static String? _spServingLabel(SpFoodDTO foodItem) {
    final gramWeight = foodItem.servingGramWeight;

    final description = foodItem.servingSize;
    if (description != null) {
      // Backend-provided household measure ("1 slice", "1 cup, sliced").
      // Append the portion's weight unless the text already states one.
      if (gramWeight != null && !_containsWeightFigure.hasMatch(description)) {
        return '$description (${_formatAmount(gramWeight)} g)';
      }
      return description;
    }

    final quantity = foodItem.servingQuantity;
    // FDC's measure_unit 9999 is literally named 'undetermined'. The
    // food_summary view maps it to 'portion' since schema v2.1; keep the
    // same mapping here for backends that haven't refreshed the view yet.
    final unit = foodItem.servingUnit == 'undetermined'
        ? 'portion'
        : foodItem.servingUnit;
    if (quantity != null && unit != null) {
      final label = '${_formatAmount(quantity)} $unit';
      // A count-based unit ("1 portion", "2 slices") says nothing about
      // how much food that actually is — append the portion's weight so
      // the user can judge it. Weight/volume units already do.
      final isWeightOrVolume =
          solidUnits.contains(unit) || liquidUnits.contains(unit);
      if (!isWeightOrVolume && gramWeight != null) {
        return '$label (${_formatAmount(gramWeight)} g)';
      }
      return label;
    }
    if (gramWeight != null) return '${_formatAmount(gramWeight)} g';
    return null;
  }

  static String _formatAmount(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  /// Value returned from OFF can either be String, int or double.
  /// Try casting it to a double value for calculation
  static double? _tryQuantityCast(dynamic value) {
    double? parsedValue;

    if (value == null) {
      parsedValue = null;
    } else if (value is double) {
      parsedValue = value;
    } else if (value is int) {
      parsedValue = value.toDouble();
    } else if (value is String) {
      value.replaceAll(RegExp("mg|g|kg|ml|cl|l| "), ""); // TODO extract
      final doubleParsed =
          double.tryParse(value) ?? int.tryParse(value)?.toDouble();
      parsedValue = doubleParsed;
    }
    return parsedValue;
  }

  /// Unit can either be 100g or 100ml. Looks for a number immediately
  /// followed by a recognised weight/volume unit token (e.g. "38 g" in
  /// "1 slice (38 g)") rather than scanning the whole string for the letter
  /// "l" — free-text serving descriptions like "1 slice", "1 roll", "1 bowl"
  /// or "1 fillet" all contain an "l" and would otherwise be misclassified
  /// as liquid. When several tokens are present (e.g. a household measure
  /// followed by its gram equivalent in parentheses) the last one wins, as
  /// it's usually the precise weight/volume. Falls back to "g" when no unit
  /// token is found, matching the previous default.
  static String? _tryGetUnit(String? quantityString) {
    if (quantityString == null) return null;

    final matches = RegExp(
      r'\b(?:mg|kg|ml|cl|dl|l|g)\b',
      caseSensitive: false,
    ).allMatches(quantityString.replaceAll(RegExp(r'\d'), '')).toList();

    final unitToken = matches.isEmpty
        ? null
        : matches.last.group(0)?.toLowerCase();

    switch (unitToken) {
      case 'ml':
      case 'cl':
      case 'dl':
      case 'l':
        return 'ml';
      default:
        return 'g';
    }
  }

  @override
  List<Object?> get props => [code, name];
}

enum MealSourceEntity {
  unknown,
  custom,
  off,
  fdc,
  recipe;

  factory MealSourceEntity.fromMealSourceDBO(MealSourceDBO mealSourceDBO) {
    MealSourceEntity mealSourceEntity;
    switch (mealSourceDBO) {
      case MealSourceDBO.unknown:
        mealSourceEntity = MealSourceEntity.unknown;
        break;
      case MealSourceDBO.custom:
        mealSourceEntity = MealSourceEntity.custom;
        break;
      case MealSourceDBO.off:
        mealSourceEntity = MealSourceEntity.off;
        break;
      case MealSourceDBO.fdc:
        mealSourceEntity = MealSourceEntity.fdc;
        break;
      case MealSourceDBO.recipe:
        mealSourceEntity = MealSourceEntity.recipe;
        break;
    }
    return mealSourceEntity;
  }
}
