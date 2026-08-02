import 'dart:math';

import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';

class BMICalc {
  /// Lower edge of the WHO healthy band.
  static const double healthyBmiMin = 18.5;

  /// Upper edge of the WHO healthy band. The classification below treats
  /// anything under 25.0 as healthy; 24.9 is that same boundary expressed
  /// inclusively, which is how the band is usually quoted and what the
  /// onboarding suggestion shows.
  static const double healthyBmiMaxInclusive = 24.9;

  /// Where pre-obesity starts, the exclusive form of the boundary above.
  static const double preObesityBmiFloor = 25.0;

  ///
  /// Returns BMI from given UserEntity
  /// BMI = m / l²
  /// m = mass in kg, l = height in m
  static double getBMI(UserEntity user) {
    return user.weightKG / pow(user.heightCM / 100, 2);
  }

  /// Returns Nutritional Status from given BMI value
  /// https://www.who.int/europe/news-room/fact-sheets/item/a-healthy-lifestyle---who-recommendations
  static UserNutritionalStatus getNutritionalStatus(double bmi) {
    UserNutritionalStatus nutritionalStatus;
    if (bmi < healthyBmiMin) {
      nutritionalStatus = UserNutritionalStatus.underWeight;
    } else if (bmi < preObesityBmiFloor) {
      nutritionalStatus = UserNutritionalStatus.normalWeight;
    } else if (bmi < 30.0) {
      nutritionalStatus = UserNutritionalStatus.preObesity;
    } else if (bmi < 35.0) {
      nutritionalStatus = UserNutritionalStatus.obesityClassI;
    } else if (bmi < 40.0) {
      nutritionalStatus = UserNutritionalStatus.obesityClassII;
    } else {
      nutritionalStatus = UserNutritionalStatus.obesityClassIII;
    }
    return nutritionalStatus;
  }
}
