import 'package:json_annotation/json_annotation.dart';

part 'fdc_food_nutriment_dto.g.dart';

@JsonSerializable()
class FDCFoodNutrimentDTO {
  @JsonKey(name: 'nutrient_id')
  final int? nutrientId;
  final double? amount;

  FDCFoodNutrimentDTO({required this.nutrientId, required this.amount});

  factory FDCFoodNutrimentDTO.fromJson(Map<String, dynamic> json) =>
      _$FDCFoodNutrimentDTOFromJson(json);

  Map<String, dynamic> toJson() => _$FDCFoodNutrimentDTOToJson(this);
}
