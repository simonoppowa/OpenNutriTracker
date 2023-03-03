import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

enum AddItemType {
  activityType,
  breakfastType,
  lunchType,
  dinnerType,
  snackType;
}

extension AddItemExtension on AddItemType {
  String getTypeName(BuildContext context) {
    switch (this) {
      case AddItemType.activityType:
        return S.of(context).activityLabel;
      case AddItemType.breakfastType:
        return S.of(context).breakfastLabel;
      case AddItemType.lunchType:
        return S.of(context).lunchLabel;
      case AddItemType.dinnerType:
        return S.of(context).dinnerLabel;
      case AddItemType.snackType:
        return S.of(context).snackLabel;
    }
  }

  IntakeTypeEntity getIntakeType() {
    switch (this) {
      case AddItemType.activityType:
        return IntakeTypeEntity.breakfast; // TODO
      case AddItemType.breakfastType:
        return IntakeTypeEntity.breakfast;
      case AddItemType.lunchType:
        return IntakeTypeEntity.lunch;
      case AddItemType.dinnerType:
        return IntakeTypeEntity.dinner;
      case AddItemType.snackType:
        return IntakeTypeEntity.snack;
    }
  }
}
