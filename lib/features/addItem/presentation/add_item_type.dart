import 'package:flutter/cupertino.dart';
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
}
