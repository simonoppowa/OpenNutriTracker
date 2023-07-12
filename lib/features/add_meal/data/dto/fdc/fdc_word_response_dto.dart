import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food_dto.dart';

part 'fdc_word_response_dto.g.dart';

@JsonSerializable()
class FDCWordResponseDTO {
  final int? totalHits;
  final int? currentPage;

  final List<FDCFoodDTO> foods;

  FDCWordResponseDTO(
      {required this.totalHits,
      required this.currentPage,
      required this.foods});

  factory FDCWordResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$FDCWordResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$FDCWordResponseDTOToJson(this);
}
