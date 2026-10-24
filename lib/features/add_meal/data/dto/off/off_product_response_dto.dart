// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_json_helpers.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';

part 'off_product_response_dto.g.dart';

@JsonSerializable()
class OFFProductResponseDTO {
  @JsonKey(fromJson: offIntFromJson)
  final int? status;
  final String? status_verbose;

  // Absent when OFF does not know the barcode (or the product was removed).
  @JsonKey(fromJson: _productFromJson)
  final OFFProductDTO? product;

  OFFProductResponseDTO({
    required this.status,
    required this.status_verbose,
    required this.product,
  });

  static OFFProductDTO? _productFromJson(dynamic value) {
    final map = offMapFromJson(value);
    return map == null ? null : OFFProductDTO.fromJson(map);
  }

  factory OFFProductResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$OFFProductResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OFFProductResponseDTOToJson(this);
}
