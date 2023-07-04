// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fdc_word_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FDCWordResponse _$FDCWordResponseFromJson(Map<String, dynamic> json) =>
    FDCWordResponse(
      totalHits: json['totalHits'] as int?,
      currentPage: json['currentPage'] as int?,
      foods: (json['foods'] as List<dynamic>)
          .map((e) => FDCFood.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FDCWordResponseToJson(FDCWordResponse instance) =>
    <String, dynamic>{
      'totalHits': instance.totalHits,
      'currentPage': instance.currentPage,
      'foods': instance.foods,
    };
