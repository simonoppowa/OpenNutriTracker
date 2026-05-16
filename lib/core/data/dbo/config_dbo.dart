import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

part 'config_dbo.g.dart';

@HiveType(typeId: 13)
@JsonSerializable() // Used for exporting to JSON
class ConfigDBO extends HiveObject {
  @HiveField(0)
  bool hasAcceptedDisclaimer;
  @HiveField(1)
  bool hasAcceptedPolicy;
  @HiveField(2)
  bool hasAcceptedSendAnonymousData;
  @HiveField(3)
  AppThemeDBO selectedAppTheme;
  @HiveField(4)
  bool? usesImperialUnits;
  @HiveField(5)
  double? userKcalAdjustment;
  @HiveField(6)
  double? userCarbGoalPct;
  @HiveField(7)
  double? userProteinGoalPct;
  @HiveField(8)
  double? userFatGoalPct;
  @HiveField(9)
  bool? showActivityTracking;
  @HiveField(10)
  bool? notificationsEnabled;
  @HiveField(11)
  int? notificationHour;
  @HiveField(12)
  int? notificationMinute;
  @HiveField(13)
  String? selectedLocale;
  @HiveField(14)
  bool? showMealMacros;
  @HiveField(15)
  bool? showMicronutrients; // #237: null means default (false)
  @HiveField(16)
  bool? usesKilojoules; // #177: null means default (false → kcal)
  // #150: per-meal kcal share, percent values keyed by meal type
  // ("breakfast" / "lunch" / "dinner" / "snack"). Null means use defaults.
  @HiveField(17)
  Map<String, int>? mealKcalSharesPct;
  @HiveField(18)
  String? customMealFormMode; // #232: 'simple' or 'advanced'; null means default (simple)
  @HiveField(19)
  int? dayStartOffsetHours; // #139: 0-23, null means default (0 = wall-clock midnight)
  // #160 follow-up: per-nutrient show/hide map for the daily nutrient panel.
  // Keys are nutrient identifiers from [DailyNutrientPanel]; values are
  // explicit user overrides. A nutrient not present in the map (or a null
  // map altogether) means "use the default visibility", which is currently
  // visible for every nutrient — see [ConfigEntity.isNutrientVisible].
  @HiveField(22)
  Map<String, bool>? nutrientPanelVisibility;

  /// Per-meal sort preference for the diary day view. Keys are meal type
  /// strings (`breakfast` / `lunch` / `dinner` / `snack`) and values are the
  /// `DiarySortType` enum index. Nullable so existing configs without a
  /// persisted preference keep falling back to the widget-state default
  /// (`DiarySortType.timeAdded`) until the user picks a sort.
  @HiveField(21)
  Map<String, int>? diarySortPreferences;
  // #139 follow-up: 0-59 minute companion. Composes additively with
  // dayStartOffsetHours so existing users with hours=4 and a null minutes
  // value see a 4:00 boundary, unchanged.
  @HiveField(23)
  int? dayStartOffsetMinutes;
  // #32: configurable daily water goal in millilitres. Null means use the
  // default (2000 ml), so existing configs without a stored value keep
  // working without a migration.
  @HiveField(24)
  int? dailyWaterGoalMl;
  // #415: opt-in Material You dynamic colour scheme. Null means the user
  // has not made a deliberate choice yet, which the UI treats as "on" — the
  // wallpaper-derived palette only actually appears on Android 12+, and on
  // every other platform the static palette is what shows up regardless.
  @HiveField(20)
  bool? useMaterialYou;
  // #415 follow-up: custom accent colour packed as a 32-bit ARGB value
  // (e.g. 0xFFFF5733). Stores the full colour rather than just a hue so
  // hex entry can round-trip without losing saturation or lightness.
  // Null means "use the platform default" — Material You on Android 12+,
  // the static palette elsewhere.
  @HiveField(26)
  int? accentColor;

  ConfigDBO(
    this.hasAcceptedDisclaimer,
    this.hasAcceptedPolicy,
    this.hasAcceptedSendAnonymousData,
    this.selectedAppTheme, {
    this.usesImperialUnits = false,
    this.userKcalAdjustment,
    this.showActivityTracking,
    this.showMealMacros,
    this.notificationsEnabled,
    this.notificationHour,
    this.notificationMinute,
    this.selectedLocale,
    this.showMicronutrients,
    this.usesKilojoules,
    this.mealKcalSharesPct,
    this.customMealFormMode,
    this.dayStartOffsetHours,
    this.diarySortPreferences,
    this.nutrientPanelVisibility,
    this.dayStartOffsetMinutes,
    this.dailyWaterGoalMl,
    this.useMaterialYou,
    this.accentColor,
  });

  factory ConfigDBO.empty() =>
      ConfigDBO(false, false, false, AppThemeDBO.system);

  factory ConfigDBO.fromConfigEntity(ConfigEntity entity) => ConfigDBO(
    entity.hasAcceptedDisclaimer,
    entity.hasAcceptedPolicy,
    entity.hasAcceptedSendAnonymousData,
    AppThemeDBO.fromAppThemeEntity(entity.appTheme),
    usesImperialUnits: entity.usesImperialUnits,
  );

  factory ConfigDBO.fromJson(Map<String, dynamic> json) =>
      _$ConfigDBOFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigDBOToJson(this);
}
