import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';

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
  final int
  dayStartOffsetMinutes; // #139 follow-up: 0-59, composes additively with hours
  // #32: nullable so "I haven't picked yet" can fall back to a
  // gendered default at read time. Once the user has touched the
  // setting, their override is persisted and survives a profile edit.
  final int? dailyWaterGoalMl;
  // #415: whether to harmonise the app palette with the user's system
  // wallpaper colours. Effective only on Android 12+ — every other
  // platform falls back to the static palette regardless of this value.
  final bool useMaterialYou;
  // #415 follow-up: custom accent colour packed as 32-bit ARGB. Overrides
  // Material You when set. Null means "use the platform default" — Material
  // You on Android 12+, the static palette elsewhere.
  final int? accentColor;

  /// Default daily water goal in millilitres for the home chip when the
  /// user has not picked one yet.
  ///
  /// The popular "8 × 8 oz = 2 L of plain water" target has no
  /// scientific basis — Valtin (2002, AJP-Reg) traced it to a misreading
  /// of a 1945 US Food and Nutrition Board note that explicitly said
  /// "most of this quantity is contained in prepared foods". No major
  /// guideline body recommends a single "2 L of plain water" figure
  /// today.
  ///
  /// Picking 1500 ml lands inside the NHS Eatwell Guide's "6 to 8 cups
  /// or glasses of fluid a day" (≈ 1.2–1.5 L of drinks of any kind)
  /// and is consistent with the EFSA 2010 Adequate Intake of 2.0 L/day
  /// total water for women / 2.5 L/day for men once the ~20% EFSA
  /// attributes to food moisture is subtracted. The user can adjust it
  /// from 100 to 10000 ml in Settings → Calculations whenever a
  /// different target fits their own activity level, climate, or
  /// clinical advice.
  ///
  /// Sources:
  ///   * NHS, "Water, drinks and your health" —
  ///     https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/water-drinks-nutrition/
  ///   * EFSA NDA Panel, "Scientific Opinion on Dietary Reference
  ///     Values for water", EFSA Journal 2010;8(3):1459.
  ///   * Valtin H., "Drink at least eight glasses of water a day.
  ///     Really?", AJP-Reg 2002;283(5):R993–R1004.
  static const int defaultDailyWaterGoalMl = 1500;

  /// Gendered seed defaults applied when [dailyWaterGoalMl] is null —
  /// derived from EFSA 2010 total-water AI (2.0 L women / 2.5 L men)
  /// minus the ~20% food-moisture share. Non-binary users fall back to
  /// the female / male / averaged figure based on their
  /// [CaloriesProfileEntity], which is the same decoupling the TDEE
  /// calculator uses so a user only states their reference body
  /// chemistry once.
  static const int waterGoalFemaleMl = 1500;
  static const int waterGoalMaleMl = 1900;
  static const int waterGoalAveragedMl = 1700;

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
    this.dailyWaterGoalMl,
    this.useMaterialYou = true,
    this.accentColor,
  });

  /// Resolves the daily water goal for the home chip. Returns the user's
  /// stored override if one exists, otherwise the gendered seed default
  /// derived from EFSA 2010 (see [defaultDailyWaterGoalMl] for the full
  /// reasoning and citations). Non-binary users fall back to the same
  /// `CaloriesProfileEntity` they pick for TDEE — averaged sits at the
  /// midpoint of the female / male figures.
  int effectiveDailyWaterGoalMl(
    UserGenderEntity gender, {
    CaloriesProfileEntity? caloriesProfile,
  }) {
    final stored = dailyWaterGoalMl;
    if (stored != null) return stored;
    return seedWaterGoalForGender(gender, caloriesProfile: caloriesProfile);
  }

  /// Gendered seed used when no override is stored. Public so the goal
  /// dialog can show "reset to the gender-appropriate default" without
  /// having to recompute the rules itself.
  static int seedWaterGoalForGender(
    UserGenderEntity gender, {
    CaloriesProfileEntity? caloriesProfile,
  }) {
    switch (gender) {
      case UserGenderEntity.male:
        return waterGoalMaleMl;
      case UserGenderEntity.female:
        return waterGoalFemaleMl;
      case UserGenderEntity.nonBinary:
        switch (caloriesProfile ?? CaloriesProfileEntity.averaged) {
          case CaloriesProfileEntity.testosteroneTypical:
            return waterGoalMaleMl;
          case CaloriesProfileEntity.estrogenTypical:
            return waterGoalFemaleMl;
          case CaloriesProfileEntity.averaged:
            return waterGoalAveragedMl;
        }
    }
  }

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
    dayStartOffsetMinutes: _normaliseOffsetMinutes(dbo.dayStartOffsetMinutes),
    dailyWaterGoalMl: _normaliseWaterGoal(dbo.dailyWaterGoalMl),
    useMaterialYou: dbo.useMaterialYou ?? true,
    accentColor: _normaliseAccentColor(dbo.accentColor),
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

  // Defensive clamp on the persisted water goal. null means "no
  // override stored" — caller falls back to the gendered seed in
  // [seedWaterGoalForGender]. A non-null value outside 100–10000 ml is
  // treated as corrupt and dropped to null so the seed kicks in.
  static int? _normaliseWaterGoal(int? raw) {
    if (raw == null) return null;
    if (raw < 100 || raw > 10000) return null;
    return raw;
  }

  // Defensive clamp on the persisted accent colour. Null means "no custom
  // colour stored" — the platform default kicks in. Anything else is
  // accepted as a 32-bit ARGB int (negative values come from packing the
  // top byte's alpha=0xFF, so don't try to reject them on range).
  static int? _normaliseAccentColor(int? raw) {
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
    dailyWaterGoalMl,
    useMaterialYou,
    accentColor,
  ];
}
