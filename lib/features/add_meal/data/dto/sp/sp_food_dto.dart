import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';

part 'sp_food_dto.g.dart';

/// One row of the Supabase `food_summary` materialized view — the flat,
/// app-facing projection of a food from any backend source (FDC, BLS,
/// INDB, TBCA...). Nutrient values are per 100 g in the canonical units
/// used throughout the app (kcal / g / mg / µg, see MealNutrimentsEntity).
@JsonSerializable()
class SpFoodDTO {
  @JsonKey(name: SPConst.foodId)
  final int? foodId;
  @JsonKey(name: SPConst.foodSource)
  final String? source;
  @JsonKey(name: SPConst.foodSourceCode)
  final String? sourceCode;
  @JsonKey(name: SPConst.foodName)
  final String? name;

  /// The view's concise English title ("Egg" for "Egg, yolk only, raw"),
  /// no longer shown anywhere but still what the search scorers match on.
  /// It was the display name until #1164: 555 short titles cover 4,215 of
  /// the 5,432 FDC survey records, so whole families of distinct foods
  /// ("Egg, whole, raw", "Egg, yolk only, raw", "Egg, creamed") reached
  /// the screen as one word and were indistinguishable — and, once the
  /// near-duplicate collapse saw the same name, were folded into one
  /// another and lost. See [displayName] and [searchTitle].
  @JsonKey(name: SPConst.foodShortTitle)
  final String? shortTitle;
  @JsonKey(name: SPConst.foodBrands)
  final String? brands;
  @JsonKey(name: SPConst.foodBarcode)
  final String? barcode;
  @JsonKey(name: SPConst.foodCategory)
  final String? category;
  @JsonKey(name: SPConst.servingQuantity)
  final double? servingQuantity;
  @JsonKey(name: SPConst.servingUnit)
  final String? servingUnit;
  @JsonKey(name: SPConst.servingSize)
  final String? servingSize;
  @JsonKey(name: SPConst.servingGramWeight)
  final double? servingGramWeight;
  @JsonKey(name: SPConst.thumbnailUrl)
  final String? thumbnailUrl;
  @JsonKey(name: SPConst.mainImageUrl)
  final String? mainImageUrl;
  @JsonKey(name: SPConst.tags)
  final List<String>? tags;

  @JsonKey(name: 'energy_kcal_100')
  final double? energyKcal100;
  @JsonKey(name: 'carbohydrates_100')
  final double? carbohydrates100;
  @JsonKey(name: 'fat_100')
  final double? fat100;
  @JsonKey(name: 'proteins_100')
  final double? proteins100;
  @JsonKey(name: 'sugars_100')
  final double? sugars100;
  @JsonKey(name: 'saturated_fat_100')
  final double? saturatedFat100;
  @JsonKey(name: 'fiber_100')
  final double? fiber100;
  @JsonKey(name: 'monounsaturated_fat_100')
  final double? monounsaturatedFat100;
  @JsonKey(name: 'polyunsaturated_fat_100')
  final double? polyunsaturatedFat100;
  @JsonKey(name: 'trans_fat_100')
  final double? transFat100;
  @JsonKey(name: 'cholesterol_100')
  final double? cholesterol100;
  @JsonKey(name: 'sodium_100')
  final double? sodium100;
  @JsonKey(name: 'potassium_100')
  final double? potassium100;
  @JsonKey(name: 'magnesium_100')
  final double? magnesium100;
  @JsonKey(name: 'calcium_100')
  final double? calcium100;
  @JsonKey(name: 'iron_100')
  final double? iron100;
  @JsonKey(name: 'zinc_100')
  final double? zinc100;
  @JsonKey(name: 'phosphorus_100')
  final double? phosphorus100;
  @JsonKey(name: 'vitamin_a_100')
  final double? vitaminA100;
  @JsonKey(name: 'vitamin_c_100')
  final double? vitaminC100;
  @JsonKey(name: 'vitamin_d_100')
  final double? vitaminD100;
  @JsonKey(name: 'vitamin_b6_100')
  final double? vitaminB6100;
  @JsonKey(name: 'vitamin_b12_100')
  final double? vitaminB12100;
  @JsonKey(name: 'niacin_100')
  final double? niacin100;

  /// Locale-specific name resolved from `food_translation`, set by
  /// SpFoodDataSource after the summary row is fetched. Null when the
  /// search ran against the English `food_summary.name` directly.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? localizedName;

  /// True when [localizedName] came from an unreviewed machine translation
  /// (food_translation.source == 'machine'). Set alongside [localizedName]
  /// by SpFoodDataSource; drives the disclosure hint in the meal detail.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool localizedNameIsMachineTranslated = false;

  /// Name to display: the translation when there is one, else the full
  /// English description.
  ///
  /// Not [shortTitle]. A survey record's siblings differ only past the
  /// comma — "Egg, whole, raw" against "Egg, yolk only, raw" — so the
  /// short form hid the one thing a reader picking between them needs to
  /// see, and made same-named records look like duplicates to the search
  /// ranker (#1164). A localized name is a full translated description
  /// already, so it follows the same rule by construction.
  String? get displayName => localizedName ?? name;

  /// What the search scorers match this row on, when that is not
  /// [displayName]: the short title for an English row, null for a
  /// translated one. Carried as `MealEntity.searchTitle`.
  ///
  /// Before #1164 the scorers read `localizedName ?? shortTitle ?? name`,
  /// because that was the name shown. Showing the description instead
  /// moved the scoring with it and the siblings stopped tying — "Egg,
  /// creamed" beat "Egg, whole, raw" on `egg` by having fewer tokens — so
  /// the scoring stays on the short title while the display does not. A
  /// translated row is found by a query in its own language, and the
  /// English title would score `Eier` against "Egg" at nothing; it is
  /// scored by its translation, as it was.
  String? get searchTitle => localizedName == null ? shortTitle : null;

  /// Whether the name shown by [displayName] is a machine translation —
  /// only ever true when the localized name is actually the one displayed.
  bool get displayNameIsMachineTranslated =>
      localizedName != null && localizedNameIsMachineTranslated;

  bool get isFdc => source?.startsWith(SPConst.fdcSourcePrefix) ?? false;

  SpFoodDTO({
    required this.foodId,
    required this.source,
    required this.sourceCode,
    required this.name,
    this.shortTitle,
    this.brands,
    this.barcode,
    this.category,
    this.servingQuantity,
    this.servingUnit,
    this.servingSize,
    this.servingGramWeight,
    this.thumbnailUrl,
    this.mainImageUrl,
    this.tags,
    this.energyKcal100,
    this.carbohydrates100,
    this.fat100,
    this.proteins100,
    this.sugars100,
    this.saturatedFat100,
    this.fiber100,
    this.monounsaturatedFat100,
    this.polyunsaturatedFat100,
    this.transFat100,
    this.cholesterol100,
    this.sodium100,
    this.potassium100,
    this.magnesium100,
    this.calcium100,
    this.iron100,
    this.zinc100,
    this.phosphorus100,
    this.vitaminA100,
    this.vitaminC100,
    this.vitaminD100,
    this.vitaminB6100,
    this.vitaminB12100,
    this.niacin100,
    this.localizedName,
  });

  factory SpFoodDTO.fromJson(Map<String, dynamic> json) =>
      _$SpFoodDTOFromJson(json);

  Map<String, dynamic> toJson() => _$SpFoodDTOToJson(this);
}
