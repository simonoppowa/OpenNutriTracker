import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food_nutriment_dto.dart';

part 'fdc_food_dto.g.dart';

@JsonSerializable()
class FDCFoodDTO {
  final double? fdcId;
  final String? gtinUpc;
  final String? description;

  final String? brandOwner;
  final String? brandName;

  final String? packageWeight;
  final double? servingSize;
  final String? servingSizeUnit;

  final List<FDCFoodNutrimentDTO> foodNutrients;

  FDCFoodDTO(
      {required this.fdcId,
      required this.gtinUpc,
      required this.description,
      required this.brandOwner,
      required this.brandName,
      required this.packageWeight,
      required this.servingSize,
      required this.foodNutrients,
      required this.servingSizeUnit});

  factory FDCFoodDTO.fromJson(Map<String, dynamic> json) =>
      _$FDCFoodDTOFromJson(json);

  Map<String, dynamic> toJson() => _$FDCFoodDTOToJson(this);
}
