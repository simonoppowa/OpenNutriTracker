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
  final bool caloriesTaperEnabled;
  final Map<String, int>? diarySortPreferences;
  // #160 follow-up: per-nutrient show/hide overrides for the daily panel.
  // Keys are nutrient identifiers (see `DailyNutrientPanel.nutrientKeys`),
  // values are explicit user overrides. A nutrient not present in this map
  // falls back to the default, which is currently "visible" for every
  // nutrient — see [isNutrientVisible].
  final Map<String, bool> nutrientPanelVisibility;

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
    this.caloriesTaperEnabled = false,
    this.diarySortPreferences,
    this.nutrientPanelVisibility = const <String, bool>{},
  });

  /// Whether a particular nutrient on the daily panel should be rendered.
  /// All nutrients default to visible; the user can hide individual ones
  /// from Settings → Nutrients.
  bool isNutrientVisible(String key) => nutrientPanelVisibility[key] ?? true;

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
        caloriesTaperEnabled: dbo.caloriesTaperEnabled,
        diarySortPreferences: dbo.diarySortPreferences,
        nutrientPanelVisibility:
            dbo.nutrientPanelVisibility ?? const <String, bool>{},
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
        caloriesTaperEnabled,
        diarySortPreferences,
        nutrientPanelVisibility,
      ];
}
