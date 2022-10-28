import 'dart:math';

import 'package:opennutritracker/core/domain/entity/user_entity.dart';

class BMICalc {

  ///
  /// Returns BMI from given UserEntity
  /// BMI = m / l²
  /// m = mass in kg, l = height in m
  static double getBMI(UserEntity user) {
    return user.weightKG / pow(user.heightCM / 100, 2);
  }
}
