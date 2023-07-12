import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_const.dart';

part 'fdc_food_nutriment_dto.g.dart';

@JsonSerializable()
class FDCFoodNutrimentDTO {
  @JsonKey(name: SPConst.fdcNutrientId)
  final int? nutrientId;
  final double? amount;

  FDCFoodNutrimentDTO({required this.nutrientId, required this.amount});

  factory FDCFoodNutrimentDTO.fromJson(Map<String, dynamic> json) =>
      _$FDCFoodNutrimentDTOFromJson(json);

  Map<String, dynamic> toJson() => _$FDCFoodNutrimentDTOToJson(this);
}
