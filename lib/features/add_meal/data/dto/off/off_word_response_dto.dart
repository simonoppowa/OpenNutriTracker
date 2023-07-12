// ignore_for_file: non_constant_identifier_names
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';

part 'off_word_response_dto.g.dart';

@JsonSerializable()
class OFFWordResponseDTO {
  final dynamic count;
  final dynamic page;
  final int? page_count;
  final int? page_size;

  final List<OFFProductDTO> products;

  OFFWordResponseDTO(
      {required this.count,
      required this.page,
      required this.page_count,
      required this.page_size,
      required this.products});

  factory OFFWordResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$OFFWordResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OFFWordResponseDTOToJson(this);
}
