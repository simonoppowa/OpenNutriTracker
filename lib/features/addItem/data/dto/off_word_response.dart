// ignore_for_file: non_constant_identifier_names
import 'package:json_annotation/json_annotation.dart';

part 'off_word_response.g.dart';

@JsonSerializable()
class OFFWordResponse {
  final double? count;
  final int? page;
  final int? page_count;
  final int? page_size;

  OFFWordResponse(
      {required this.count,
      required this.page,
      required this.page_count,
      required this.page_size});

  factory OFFWordResponse.fromJson(Map<String, dynamic> json) =>
      _$OFFWordResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OFFWordResponseToJson(this);
}
