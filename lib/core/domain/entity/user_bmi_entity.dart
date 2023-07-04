import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class UserBMIEntity extends Equatable {
  final double bmiValue;
  final UserNutritionalStatus nutritionalStatus;

  const UserBMIEntity(
      {required this.bmiValue, required this.nutritionalStatus});

  @override
  List<Object?> get props => [bmiValue, nutritionalStatus];
}

/// Nutritional Status by WHO
/// https://www.who.int/europe/news-room/fact-sheets/item/a-healthy-lifestyle---who-recommendations
enum UserNutritionalStatus {
  underWeight,
  normalWeight,
  preObesity,
  obesityClassI,
  obesityClassII,
  obesityClassIII;

  String getName(BuildContext context) {
    String name;
    switch (this) {
      case UserNutritionalStatus.underWeight:
        name = S.of(context).nutritionalStatusUnderweight;
        break;
      case UserNutritionalStatus.normalWeight:
        name = S.of(context).nutritionalStatusNormalWeight;
        break;
      case UserNutritionalStatus.preObesity:
        name = S.of(context).nutritionalStatusPreObesity;
        break;
      case UserNutritionalStatus.obesityClassI:
        name = S.of(context).nutritionalStatusObeseClassI;
        break;
      case UserNutritionalStatus.obesityClassII:
        name = S.of(context).nutritionalStatusObeseClassII;
        break;
      case UserNutritionalStatus.obesityClassIII:
        name = S.of(context).nutritionalStatusObeseClassIII;
        break;
    }
    return name;
  }

  String getRiskStatus(BuildContext context) {
    String riskStatus;
    switch (this) {
      case UserNutritionalStatus.underWeight:
        riskStatus = S.of(context).nutritionalStatusRiskLow;
        break;
      case UserNutritionalStatus.normalWeight:
        riskStatus = S.of(context).nutritionalStatusRiskAverage;
        break;
      case UserNutritionalStatus.preObesity:
        riskStatus = S.of(context).nutritionalStatusRiskIncreased;
        break;
      case UserNutritionalStatus.obesityClassI:
        riskStatus = S.of(context).nutritionalStatusRiskModerate;
        break;
      case UserNutritionalStatus.obesityClassII:
        riskStatus = S.of(context).nutritionalStatusRiskSevere;
        break;
      case UserNutritionalStatus.obesityClassIII:
        riskStatus = S.of(context).nutritionalStatusRiskVerySevere;
        break;
    }
    return riskStatus;
  }
}
