import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food_nutriment.dart';

part 'fdc_food.g.dart';

@JsonSerializable()
class FDCFood {
  final double? fdcId;
  final String? gtinUpc;
  final String? description;

  final String? brandOwner;
  final String? brandName;

  final String? packageWeight;
  final double? servingSize;
  final String? servingSizeUnit;

  final List<FDCFoodNutriment> foodNutrients;

  FDCFood(
      {required this.fdcId,
      required this.gtinUpc,
      required this.description,
      required this.brandOwner,
      required this.brandName,
      required this.packageWeight,
      required this.servingSize,
      required this.foodNutrients,
      required this.servingSizeUnit});

  factory FDCFood.fromJson(Map<String, dynamic> json) =>
      _$FDCFoodFromJson(json);

  Map<String, dynamic> toJson() => _$FDCFoodToJson(this);
}
