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

  static IntakeTypeEntity suggestFromTime(DateTime now) {
    final hour = now.hour;
    if (hour >= 4 && hour < 11) return IntakeTypeEntity.breakfast;
    if (hour >= 11 && hour < 15) return IntakeTypeEntity.lunch;
    if (hour >= 17 && hour < 22) return IntakeTypeEntity.dinner;
    return IntakeTypeEntity.snack;
  }
}
