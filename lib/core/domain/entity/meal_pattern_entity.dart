import 'package:opennutritracker/core/domain/entity/config_entity.dart';

/// #150 follow-up: a named preset for the per-meal kcal share. Users can pick
/// one of these in Settings → Calculations as a one-tap starting point, then
/// fine-tune via the sliders if they want.
///
/// The patterns are deliberately opinionated but not prescriptive. Standard is
/// the existing four-meal default (30/40/20/10). Mediterranean nudges lunch
/// upward, which is closer to how people actually eat across southern Europe.
/// Two-meal and OMAD fit intermittent-fasting routines that have become common
/// enough that the slider-only interface felt like it was quietly excluding
/// them. Five-small is the grazing pattern, with a heavier snack share for
/// people who eat little and often.
///
/// OMAD specifically maps the whole day to a single meal slot. Traditionally
/// the meal sits in the evening (dinner), but anyone for whom that doesn't fit
/// can shift the 100% to lunch via the sliders after picking the preset.
enum MealPatternEntity {
  standard(
    id: 'standard',
    breakfastPct: 30,
    lunchPct: 40,
    dinnerPct: 20,
    snackPct: 10,
  ),
  mediterranean(
    id: 'mediterranean',
    breakfastPct: 25,
    lunchPct: 45,
    dinnerPct: 20,
    snackPct: 10,
  ),
  twoMeal(
    id: 'two_meal',
    breakfastPct: 40,
    lunchPct: 0,
    dinnerPct: 50,
    snackPct: 10,
  ),
  omad(
    id: 'omad',
    breakfastPct: 0,
    lunchPct: 0,
    dinnerPct: 100,
    snackPct: 0,
  ),
  fiveSmall(
    id: 'five_small',
    breakfastPct: 20,
    lunchPct: 25,
    dinnerPct: 25,
    snackPct: 30,
  );

  final String id;
  final int breakfastPct;
  final int lunchPct;
  final int dinnerPct;
  final int snackPct;

  const MealPatternEntity({
    required this.id,
    required this.breakfastPct,
    required this.lunchPct,
    required this.dinnerPct,
    required this.snackPct,
  });

  /// Returns the four meal-share percentages keyed by [ConfigEntity]'s meal
  /// keys, ready to drop into `setMealKcalSharesPct(...)`.
  Map<String, int> toSharesMap() => {
        ConfigEntity.mealKeyBreakfast: breakfastPct,
        ConfigEntity.mealKeyLunch: lunchPct,
        ConfigEntity.mealKeyDinner: dinnerPct,
        ConfigEntity.mealKeySnack: snackPct,
      };
}
