import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food.dart';

part 'fdc_word_response.g.dart';

@JsonSerializable()
class FDCWordResponse {
  final int? totalHits;
  final int? currentPage;

  final List<FDCFood> foods;

  FDCWordResponse(
      {required this.totalHits,
      required this.currentPage,
      required this.foods});

  factory FDCWordResponse.fromJson(Map<String, dynamic> json) =>
      _$FDCWordResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FDCWordResponseToJson(this);
}
