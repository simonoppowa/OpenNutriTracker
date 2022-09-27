// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'off_product_nutriments.g.dart';

@JsonSerializable()
class OFFProductNutriments {
  // Energy Values
  @JsonKey(name: 'energy-kcal')
  final double? energy_kcal;
  @JsonKey(name: 'energy-kcal_100g')
  final double? energy_kcal_100g;
  @JsonKey(name: 'energy-kcal_serving')
  final double? energy_kcal_serving;
  @JsonKey(name: 'energy-kcal_value')
  final double? energy_kcal_value;
  @JsonKey(name: 'energy-kcal_unit')
  final String? energy_kcal_unit;

  // Macronutrients Values
  final double? carbohydrates;
  final double? carbohydrates_100g;
  final double? carbohydrates_serving;
  final double? carbohydrates_value;
  final String? carbohydrates_unit;

  final double? fat;
  final double? fat_100g;
  final double? fat_serving;
  final double? fat_value;
  final String? fat_unit;

  final double? proteins;
  final double? proteins_100g;
  final double? proteins_serving;
  final double? proteins_value;
  final String? proteins_unit;

  OFFProductNutriments({
    required this.energy_kcal,
    required this.energy_kcal_100g,
    required this.energy_kcal_serving,
    required this.energy_kcal_unit,
    required this.energy_kcal_value,
    required this.carbohydrates,
    required this.carbohydrates_100g,
    required this.carbohydrates_serving,
    required this.carbohydrates_value,
    required this.carbohydrates_unit,
    required this.fat,
    required this.fat_100g,
    required this.fat_serving,
    required this.fat_value,
    required this.fat_unit,
    required this.proteins,
    required this.proteins_100g,
    required this.proteins_serving,
    required this.proteins_value,
    required this.proteins_unit});

  factory OFFProductNutriments.fromJson(Map<String, dynamic> json) =>
      _$OFFProductNutrimentsFromJson(json);

  Map<String, dynamic> toJson() => _$OFFProductNutrimentsToJson(this);
}
