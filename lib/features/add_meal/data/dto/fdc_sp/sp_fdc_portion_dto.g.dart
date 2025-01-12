// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sp_fdc_portion_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpFdcPortionDTO _$SpFdcPortionDTOFromJson(Map<String, dynamic> json) =>
    SpFdcPortionDTO(
      amount: (json['amount'] as num?)?.toDouble(),
      measureUnitId: (json['measure_unit_id'] as num?)?.toInt(),
      gramWeight: (json['gram_weight'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SpFdcPortionDTOToJson(SpFdcPortionDTO instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'measure_unit_id': instance.measureUnitId,
      'gram_weight': instance.gramWeight,
    };
