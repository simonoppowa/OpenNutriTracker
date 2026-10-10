import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

/// Suggests a meal type based on the local time of day.
///
/// The ranges below are inclusive of the start hour and exclusive of the
/// end hour, so e.g. 11:00 is Lunch and 15:00 is Snack.
///
/// * Breakfast: 04:00 – 10:59
/// * Lunch:     11:00 – 14:59
/// * Snack:     15:00 – 16:59
/// * Dinner:    17:00 – 21:59
/// * Snack:     22:00 – 03:59  (late night and pre-dawn)
///
/// A single call site owns the mapping so the ranges can be tweaked in one
/// place without hunting through UI code.
class MealTypeSuggester {
  const MealTypeSuggester._();

  static const _minutesPerDay = 24 * 60;

  /// When [mealSharesPct] (keyed by the [ConfigEntity] meal keys) is given, a
  /// meal whose share is 0 % — or missing, as Home and the Diary read it — is
  /// never suggested: those screens hide its section while it is empty, so
  /// food logged there would vanish (#1305). The suggestion moves to the
  /// enabled meal whose time window is nearest to [now], the later one on a
  /// tie. If every share is 0 the plain time-of-day mapping is returned.
  static IntakeTypeEntity suggestFromTime(
    DateTime now, {
    Map<String, int>? mealSharesPct,
  }) {
    final byTime = _mealAtHour(now.hour);
    if (mealSharesPct == null) return byTime;
    bool enabled(IntakeTypeEntity type) =>
        (mealSharesPct[_shareKey(type)] ?? 0) > 0;
    if (enabled(byTime)) return byTime;

    final minuteOfDay = now.hour * 60 + now.minute;
    for (var offset = 1; offset <= _minutesPerDay ~/ 2; offset++) {
      for (final minute in [minuteOfDay + offset, minuteOfDay - offset]) {
        final type = _mealAtHour((minute % _minutesPerDay) ~/ 60);
        if (enabled(type)) return type;
      }
    }
    return byTime;
  }

  static IntakeTypeEntity _mealAtHour(int hour) {
    if (hour >= 4 && hour < 11) return IntakeTypeEntity.breakfast;
    if (hour >= 11 && hour < 15) return IntakeTypeEntity.lunch;
    if (hour >= 17 && hour < 22) return IntakeTypeEntity.dinner;
    return IntakeTypeEntity.snack;
  }

  static String _shareKey(IntakeTypeEntity type) {
    switch (type) {
      case IntakeTypeEntity.breakfast:
        return ConfigEntity.mealKeyBreakfast;
      case IntakeTypeEntity.lunch:
        return ConfigEntity.mealKeyLunch;
      case IntakeTypeEntity.dinner:
        return ConfigEntity.mealKeyDinner;
      case IntakeTypeEntity.snack:
        return ConfigEntity.mealKeySnack;
    }
  }
}
