import 'package:json_annotation/json_annotation.dart';

part 'fdc_food_nutriment.g.dart';

@JsonSerializable()
class FDCFoodNutriment {
  final int? nutrientId;
  final double? value;

  FDCFoodNutriment({required this.nutrientId, required this.value});

  factory FDCFoodNutriment.fromJson(Map<String, dynamic> json) =>
      _$FDCFoodNutrimentFromJson(json);

  Map<String, dynamic> toJson() => _$FDCFoodNutrimentToJson(this);
}
