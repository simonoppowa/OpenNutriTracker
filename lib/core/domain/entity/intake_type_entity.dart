import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';

enum IntakeTypeEntity {
  breakfast,
  lunch,
  dinner,
  snack;

  factory IntakeTypeEntity.fromIntakeTypeDBO(IntakeTypeDBO intakeTypeDBO) {
    IntakeTypeEntity intakeTypeEntity;
    switch (intakeTypeDBO) {
      case IntakeTypeDBO.breakfast:
        intakeTypeEntity = IntakeTypeEntity.breakfast;
        break;
      case IntakeTypeDBO.lunch:
        intakeTypeEntity = IntakeTypeEntity.lunch;
        break;
      case IntakeTypeDBO.dinner:
        intakeTypeEntity = IntakeTypeEntity.dinner;
        break;
      case IntakeTypeDBO.snack:
        intakeTypeEntity = IntakeTypeEntity.snack;
        break;
    }
    return intakeTypeEntity;
  }

  IconData getIconData() {
    IconData icon;
    switch (this) {
      case IntakeTypeEntity.breakfast:
        icon = Icons.bakery_dining_outlined;
        break;
      case IntakeTypeEntity.lunch:
        icon = Icons.lunch_dining_outlined;
        break;
      case IntakeTypeEntity.dinner:
        icon = Icons.dinner_dining_outlined;
        break;
      case IntakeTypeEntity.snack:
        icon = CustomIcons.food_apple_outline;
    }
    return icon;
  }
}
