import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class UserBMIEntity {
  final double bmiValue;
  final UserNutritionalStatus nutritionalStatus;

  UserBMIEntity({required this.bmiValue, required this.nutritionalStatus});
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
}
