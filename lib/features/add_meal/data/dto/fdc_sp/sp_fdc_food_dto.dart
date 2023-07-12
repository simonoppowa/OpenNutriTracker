import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_food_nutriment_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_fdc_portion_dto.dart';

part 'sp_fdc_food_dto.g.dart';

@JsonSerializable()
class SpFdcFoodDTO {
  @JsonKey(name: SPConst.fdcFoodId)
  final int? fdcId;
  @JsonKey(name: SPConst.fdcFoodDescriptionEn)
  final String? descriptionEn;
  @JsonKey(name: SPConst.fdcFoodDescriptionDe)
  final String? descriptionDe;

  @JsonKey(name: SPConst.fdcNutrientsName)
  final List<FDCFoodNutrimentDTO> nutrients;

  @JsonKey(name: SPConst.fdcPortionsName)
  final List<SpFdcPortionDTO> portions;

  String? getLocaleDescription(SupportedLanguage supportedLanguage) {
    switch (supportedLanguage) {
      case SupportedLanguage.en:
        return descriptionEn;
      case SupportedLanguage.de:
        return descriptionDe;
      default:
        return descriptionEn;
    }
  }

  get servingSize => portions
      .firstWhereOrNull((portion) =>
          portion.measureUnitId == FDCConst.fdcPortionServingId ||
          portion.measureUnitId == FDCConst.fdcPortionUnknownId)
      ?.gramWeight;

  SpFdcFoodDTO(
      {required this.fdcId,
      required this.descriptionEn,
      required this.descriptionDe,
      required this.nutrients,
      required this.portions});

  factory SpFdcFoodDTO.fromJson(Map<String, dynamic> json) =>
      _$SpFdcFoodDTOFromJson(json);

  Map<String, dynamic> toJson() => _$SpFdcFoodDTOToJson(this);
}
