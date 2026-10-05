// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'off_product_nutriments_dto.g.dart';

@JsonSerializable()
class OFFProductNutrimentsDTO {
  // Energy Values
  @JsonKey(name: 'energy-kcal_100g')
  final dynamic energy_kcal_100g; // can be String, int, double or null
  // @JsonKey(name: 'energy-kcal')
  // final double? energy_kcal;
  // @JsonKey(name: 'energy-kcal_serving')
  // final double? energy_kcal_serving;
  // @JsonKey(name: 'energy-kcal_value')
  // final double? energy_kcal_value;
  // @JsonKey(name: 'energy-kcal_unit')
  // final String? energy_kcal_unit;

  // Macronutrients Values
  final dynamic carbohydrates_100g; // can be String, int, double or null
  // final dynamic carbohydrates;
  // final double? carbohydrates_serving;
  // final double? carbohydrates_value;
  // final String? carbohydrates_unit;

  final dynamic fat_100g; // can be String, int, double or null
  // final double? fat;
  // final double? fat_serving;
  // final double? fat_value;
  // final String? fat_unit;

  final dynamic proteins_100g; // can be String, int, double or null
  // final double? proteins;
  // final double? proteins_serving;
  // final double? proteins_value;
  // final String? proteins_unit;

  final dynamic sugars_100g; // can be String, int, double or null
  // final double? sugars;
  // final double? sugars_serving;
  // final double? sugars_value;
  // final String? sugars_unit;

  // @JsonKey(name: 'saturated-fat')
  // final double? saturated_fat;
  @JsonKey(name: 'saturated-fat_100g')
  final dynamic saturated_fat_100g; // can be String, int, double or null
  // @JsonKey(name: 'saturated-fat_serving')
  // final double? saturated_fat_serving;
  // @JsonKey(name: 'saturated-fat_value')
  // final double? saturated_fat_value;
  // @JsonKey(name: 'saturated-fat_unit')
  // final String? saturated_fat_unit;

  final dynamic fiber_100g; // can be String, int, double or null
  // final double? fiber;
  // final double? fiber_serving;
  // final double? fiber_value;
  // final String? fiber_unit;

  // #237: Extended lipid profile
  @JsonKey(name: 'monounsaturated-fat_100g')
  final dynamic monounsaturated_fat_100g;
  @JsonKey(name: 'polyunsaturated-fat_100g')
  final dynamic polyunsaturated_fat_100g;
  @JsonKey(name: 'trans-fat_100g')
  final dynamic trans_fat_100g;
  final dynamic cholesterol_100g;

  // #237: Minerals
  final dynamic sodium_100g;
  final dynamic potassium_100g;
  final dynamic magnesium_100g;
  final dynamic calcium_100g;
  final dynamic iron_100g;
  final dynamic zinc_100g;
  final dynamic phosphorus_100g;

  // #237: Vitamins
  @JsonKey(name: 'vitamin-a_100g')
  final dynamic vitamin_a_100g;
  @JsonKey(name: 'vitamin-c_100g')
  final dynamic vitamin_c_100g;
  @JsonKey(name: 'vitamin-d_100g')
  final dynamic vitamin_d_100g;
  @JsonKey(name: 'vitamin-b6_100g')
  final dynamic vitamin_b6_100g;
  @JsonKey(name: 'vitamin-b12_100g')
  final dynamic vitamin_b12_100g;
  @JsonKey(name: 'vitamin-pp_100g')
  final dynamic niacin_100g;

  OFFProductNutrimentsDTO({
    //required this.energy_kcal,
    required this.energy_kcal_100g,
    // required this.energy_kcal_serving,
    // required this.energy_kcal_unit,
    // required this.energy_kcal_value,
    //required this.carbohydrates,
    required this.carbohydrates_100g,
    // required this.carbohydrates_serving,
    // required this.carbohydrates_value,
    // required this.carbohydrates_unit,
    // required this.fat,
    required this.fat_100g,
    // required this.fat_serving,
    // required this.fat_value,
    // required this.fat_unit,
    // required this.proteins,
    required this.proteins_100g,
    // required this.proteins_serving,
    // required this.proteins_value,
    // required this.proteins_unit,
    // required this.sugars,
    required this.sugars_100g,
    // required this.sugars_serving,
    // required this.sugars_value,
    // required this.sugars_unit,
    // required this.saturated_fat,
    required this.saturated_fat_100g,
    // required this.saturated_fat_serving,
    // required this.saturated_fat_value,
    // required this.saturated_fat_unit,
    // required this.fiber,
    required this.fiber_100g,
    // required this.fiber_serving,
    // required this.fiber_value,
    // required this.fiber_unit,
    this.monounsaturated_fat_100g,
    this.polyunsaturated_fat_100g,
    this.trans_fat_100g,
    this.cholesterol_100g,
    this.sodium_100g,
    this.potassium_100g,
    this.magnesium_100g,
    this.calcium_100g,
    this.iron_100g,
    this.zinc_100g,
    this.phosphorus_100g,
    this.vitamin_a_100g,
    this.vitamin_c_100g,
    this.vitamin_d_100g,
    this.vitamin_b6_100g,
    this.vitamin_b12_100g,
    this.niacin_100g,
  });

  factory OFFProductNutrimentsDTO.fromJson(Map<String, dynamic> json) =>
      _$OFFProductNutrimentsDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OFFProductNutrimentsDTOToJson(this);
}
