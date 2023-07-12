import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_const.dart';

part 'fdc_food_nutriment.g.dart';

@JsonSerializable()
class FDCFoodNutriment {
  @JsonKey(name: SPConst.fdcNutrientId)
  final int? nutrientId;
  final double? amount;

  FDCFoodNutriment({required this.nutrientId, required this.amount});

  factory FDCFoodNutriment.fromJson(Map<String, dynamic> json) =>
      _$FDCFoodNutrimentFromJson(json);

  Map<String, dynamic> toJson() => _$FDCFoodNutrimentToJson(this);
}
