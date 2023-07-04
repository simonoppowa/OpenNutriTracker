import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

enum AddMealType {
  breakfastType,
  lunchType,
  dinnerType,
  snackType;
}

extension AddMealExtension on AddMealType {
  String getTypeName(BuildContext context) {
    switch (this) {
      case AddMealType.breakfastType:
        return S.of(context).breakfastLabel;
      case AddMealType.lunchType:
        return S.of(context).lunchLabel;
      case AddMealType.dinnerType:
        return S.of(context).dinnerLabel;
      case AddMealType.snackType:
        return S.of(context).snackLabel;
    }
  }

  IntakeTypeEntity getIntakeType() {
    switch (this) {
      case AddMealType.breakfastType:
        return IntakeTypeEntity.breakfast;
      case AddMealType.lunchType:
        return IntakeTypeEntity.lunch;
      case AddMealType.dinnerType:
        return IntakeTypeEntity.dinner;
      case AddMealType.snackType:
        return IntakeTypeEntity.snack;
    }
  }
}
