import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The unit a person's body weight is shown and entered in. Independent of the
/// food and height unit preferences so a user can weigh themselves in stones
/// while still measuring food in grams.
///
/// Stored weight is always kilograms (see `WeightLogDBO.weightKg` and
/// `UserEntity.weightKG`); this only affects display and input. Persisted as
/// the enum index, so the declaration order must stay stable.
enum BodyWeightUnit {
  kg,
  lb,
  st;

  /// Maps a persisted index back to a unit, defaulting to [kg] for any value
  /// that falls outside the known set (a corrupt or hand-edited Hive value).
  static BodyWeightUnit fromIndex(int index) {
    if (index < 0 || index >= BodyWeightUnit.values.length) {
      return BodyWeightUnit.kg;
    }
    return BodyWeightUnit.values[index];
  }

  /// The short unit label shown next to a weight (e.g. "kg", "lbs", "st").
  String getLabel(BuildContext context) {
    switch (this) {
      case BodyWeightUnit.kg:
        return S.of(context).kgLabel;
      case BodyWeightUnit.lb:
        return S.of(context).lbsLabel;
      case BodyWeightUnit.st:
        return S.of(context).stLabel;
    }
  }
}
