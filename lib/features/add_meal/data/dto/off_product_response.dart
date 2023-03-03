// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off_product.dart';

part 'off_product_response.g.dart';

@JsonSerializable()
class OFFProductResponse {
  final int status;
  final String status_verbose;

  final OFFProduct product;

  OFFProductResponse(
      {required this.status,
      required this.status_verbose,
      required this.product});

  factory OFFProductResponse.fromJson(Map<String, dynamic> json) =>
      _$OFFProductResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OFFProductResponseToJson(this);
}
