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
      // The Supabase view backing FDC only has `description_en` and
      // `description_de` columns today. cs / it / pl / sk / tr / uk / zh
      // users get the English description until the view picks up
      // matching columns; OFF data still resolves in those locales
      // through OFFProductDTO.getLocaleName.
      // TODO(@simonoppowa): add description_cs/_it/_pl/_sk/_tr/_uk/_zh
      // to the Supabase fdc_food view, then split these cases out.
      case SupportedLanguage.pl:
      case SupportedLanguage.zh:
      case SupportedLanguage.cs:
      case SupportedLanguage.it:
      case SupportedLanguage.sk:
      case SupportedLanguage.tr:
      case SupportedLanguage.uk:
        return descriptionEn;
    }
  }

  double? get servingSize => portions
      .firstWhereOrNull(
        (portion) =>
            portion.measureUnitId == FDCConst.fdcPortionServingId ||
            portion.measureUnitId == FDCConst.fdcPortionUnknownId,
      )
      ?.gramWeight;

  String? get servingSizeUnit {
    final id = portions
            .firstWhereOrNull(
              (portion) =>
                  portion.measureUnitId == FDCConst.fdcPortionServingId ||
                  portion.measureUnitId == FDCConst.fdcPortionUnknownId,
            )
            ?.measureUnitId ??
        FDCConst.fdcPortionUnknownId;
    return FDCConst.measureUnits[id];
  }

  double? get servingAmount => portions
      .firstWhereOrNull(
        (portion) =>
            portion.measureUnitId == FDCConst.fdcPortionServingId ||
            portion.measureUnitId == FDCConst.fdcPortionUnknownId,
      )
      ?.amount;

  SpFdcFoodDTO({
    required this.fdcId,
    required this.descriptionEn,
    required this.descriptionDe,
    required this.nutrients,
    required this.portions,
  });

  factory SpFdcFoodDTO.fromJson(Map<String, dynamic> json) =>
      _$SpFdcFoodDTOFromJson(json);

  Map<String, dynamic> toJson() => _$SpFdcFoodDTOToJson(this);
}
