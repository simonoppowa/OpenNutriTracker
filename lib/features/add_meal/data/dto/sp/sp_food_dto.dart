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

  /// The view's concise English title ("Egg" for "Egg, yolk only, raw").
  /// Parsed because the view serves it, read by nothing: it was the
  /// display name until #1164 — 555 short titles cover 4,215 of the 5,432
  /// FDC survey records, so whole families of distinct foods ("Egg, whole,
  /// raw", "Egg, yolk only, raw", "Egg, creamed") reached the screen as
  /// one word and were indistinguishable, and, once the near-duplicate
  /// collapse saw the same name, were folded into one another and lost
  /// (see [displayName]) — and the scorers, which still match on the
  /// title and read past it only where the query names a qualifier,
  /// derive both from the description instead (`MealEntity.scoringName`,
  /// `scoringQualifiers`), the column being that derivation on every row
  /// measured.
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
  /// already, so it follows the same rule by construction — and the
  /// scorers, which match on the title and on the qualifiers the query
  /// names rather than on the whole description, derive both from
  /// whichever of the two this returns (`MealEntity.scoringName`,
  /// `scoringQualifiers`), so a translated row is scored in its own
  /// language, as it was.
  ///
  /// The short title is the last resort, and a defensive one only:
  /// `food.description` is NOT NULL in the backend, so a row with a short
  /// title and no name cannot come from it, and [name] is nullable here
  /// because every column of the DTO is. Should one arrive anyway, the
  /// short form names the food where nothing would have (#1170 review).
  String? get displayName => localizedName ?? name ?? shortTitle;

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
