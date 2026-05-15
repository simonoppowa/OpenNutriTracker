import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';

class ConfigEntity extends Equatable {
  // #150: keys for the per-meal kcal share map. Kept as plain strings rather
  // than tied to IntakeTypeEntity so the persisted value stays stable across
  // any future enum renames.
  static const mealKeyBreakfast = 'breakfast';
  static const mealKeyLunch = 'lunch';
  static const mealKeyDinner = 'dinner';
  static const mealKeySnack = 'snack';

  /// Default share across breakfast / lunch / dinner / snack used when the
  /// user has never tuned the values themselves. Sums to 100; sensible
  /// without claiming to be medically prescriptive.
  static const Map<String, int> defaultMealKcalSharesPct = {
    mealKeyBreakfast: 30,
    mealKeyLunch: 40,
    mealKeyDinner: 20,
    mealKeySnack: 10,
  };

  final bool hasAcceptedDisclaimer;
  final bool hasAcceptedPolicy;
  final bool hasAcceptedSendAnonymousData;
  final AppThemeEntity appTheme;
  final bool usesImperialUnits;
  final double? userKcalAdjustment;
  final double? userCarbGoalPct;
  final double? userProteinGoalPct;
  final double? userFatGoalPct;
  final bool showActivityTracking;
  final bool showMealMacros;
  final bool notificationsEnabled;
  final int notificationHour;
  final int notificationMinute;
  final String? selectedLocale;
  final bool showMicronutrients; // #237
  final bool usesKilojoules; // #177
  final Map<String, int> mealKcalSharesPct; // #150
  final Map<String, int>? diarySortPreferences;
  // #160 follow-up: per-nutrient show/hide overrides for the daily panel.
  // Keys are nutrient identifiers (see `DailyNutrientPanel.nutrientKeys`),
  // values are explicit user overrides. A nutrient not present in this map
  // falls back to the default, which is currently "visible" for every
  // nutrient — see [isNutrientVisible].
  final Map<String, bool> nutrientPanelVisibility;
  final int dayStartOffsetHours; // #139: 0-23, default 0 (wall-clock midnight)
  final int dayStartOffsetMinutes; // #139 follow-up: 0-59, composes additively with hours

  const ConfigEntity(
    this.hasAcceptedDisclaimer,
    this.hasAcceptedPolicy,
    this.hasAcceptedSendAnonymousData,
    this.appTheme, {
    this.usesImperialUnits = false,
    this.userKcalAdjustment,
    this.userCarbGoalPct,
    this.userProteinGoalPct,
    this.userFatGoalPct,
    this.showActivityTracking = true,
    this.showMealMacros = true,
    this.notificationsEnabled = false,
    this.notificationHour = 8,
    this.notificationMinute = 0,
    this.selectedLocale,
    this.showMicronutrients = false,
    this.usesKilojoules = false,
    this.mealKcalSharesPct = defaultMealKcalSharesPct,
    this.diarySortPreferences,
    this.nutrientPanelVisibility = const <String, bool>{},
    this.dayStartOffsetHours = 0,
    this.dayStartOffsetMinutes = 0,
  });

  /// Whether a particular nutrient on the daily panel should be rendered.
  /// All nutrients default to visible; the user can hide individual ones
  /// from Settings → Nutrients.
  bool isNutrientVisible(String key) => nutrientPanelVisibility[key] ?? true;

  /// The combined day-start offset in minutes — what callers actually need
  /// when comparing two `DateTime`s under the configured boundary. Hours and
  /// minutes compose additively, so 4 h + 30 m and 0 h + 270 m both resolve
  /// to the same 270-minute shift.
  int get dayStartOffsetTotalMinutes =>
      dayStartOffsetHours * 60 + dayStartOffsetMinutes;

  factory ConfigEntity.fromConfigDBO(ConfigDBO dbo) => ConfigEntity(
        dbo.hasAcceptedDisclaimer,
        dbo.hasAcceptedPolicy,
        dbo.hasAcceptedSendAnonymousData,
        AppThemeEntity.fromAppThemeDBO(dbo.selectedAppTheme),
        usesImperialUnits: dbo.usesImperialUnits ?? false,
        userKcalAdjustment: dbo.userKcalAdjustment,
        userCarbGoalPct: dbo.userCarbGoalPct,
        userProteinGoalPct: dbo.userProteinGoalPct,
        userFatGoalPct: dbo.userFatGoalPct,
        showActivityTracking: dbo.showActivityTracking ?? true,
        showMealMacros: dbo.showMealMacros ?? true,
        notificationsEnabled: dbo.notificationsEnabled ?? false,
        notificationHour: dbo.notificationHour ?? 8,
        notificationMinute: dbo.notificationMinute ?? 0,
        selectedLocale: dbo.selectedLocale,
        showMicronutrients: dbo.showMicronutrients ?? false,
        usesKilojoules: dbo.usesKilojoules ?? false,
        mealKcalSharesPct:
            _sanitiseShares(dbo.mealKcalSharesPct) ?? defaultMealKcalSharesPct,
        diarySortPreferences: dbo.diarySortPreferences,
        nutrientPanelVisibility:
            dbo.nutrientPanelVisibility ?? const <String, bool>{},
        dayStartOffsetHours: _normaliseOffsetHours(dbo.dayStartOffsetHours),
        dayStartOffsetMinutes:
            _normaliseOffsetMinutes(dbo.dayStartOffsetMinutes),
      );

  /// Returns the recommended kcal target for [mealKey] given a daily goal.
  double targetKcalForMeal(String mealKey, double dailyKcalGoal) {
    final pct = mealKcalSharesPct[mealKey] ?? 0;
    return (dailyKcalGoal * pct) / 100;
  }

  /// Drops any keys outside the known set and only returns a map if all four
  /// expected meals are present. Defensive in case the stored map was written
  /// by an older or partially-broken build.
  static Map<String, int>? _sanitiseShares(Map<String, int>? raw) {
    if (raw == null) return null;
    final keys = [mealKeyBreakfast, mealKeyLunch, mealKeyDinner, mealKeySnack];
    if (!keys.every(raw.containsKey)) return null;
    return {for (final k in keys) k: raw[k] ?? 0};
  }

  static int _normaliseOffsetHours(int? raw) {
    if (raw == null) return 0;
    if (raw < 0 || raw > 23) return 0;
    return raw;
  }

  // Defensive clamp so a corrupt or hand-edited Hive value can't push the
  // total offset past the next wall-clock day. 0-59 is the supported range.
  static int _normaliseOffsetMinutes(int? raw) {
    if (raw == null) return 0;
    if (raw < 0) return 0;
    if (raw > 59) return 59;
    return raw;
  }

  @override
  List<Object?> get props => [
        hasAcceptedDisclaimer,
        hasAcceptedPolicy,
        hasAcceptedSendAnonymousData,
        usesImperialUnits,
        userKcalAdjustment,
        userCarbGoalPct,
        userProteinGoalPct,
        userFatGoalPct,
        showActivityTracking,
        showMealMacros,
        notificationsEnabled,
        notificationHour,
        notificationMinute,
        selectedLocale,
        showMicronutrients,
        usesKilojoules,
        mealKcalSharesPct,
        diarySortPreferences,
        nutrientPanelVisibility,
        dayStartOffsetHours,
        dayStartOffsetMinutes,
      ];
}
