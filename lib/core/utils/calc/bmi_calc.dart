import 'dart:math';

import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';

class BMICalc {
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
    if (bmi < 18.5) {
      nutritionalStatus = UserNutritionalStatus.underWeight;
    } else if (bmi < 25.0) {
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
