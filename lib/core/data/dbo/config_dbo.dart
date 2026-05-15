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
  @HiveField(20)
  bool caloriesTaperEnabled;
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
    this.caloriesTaperEnabled = false,
    this.diarySortPreferences,
    this.nutrientPanelVisibility,
  });

  factory ConfigDBO.empty() =>
      ConfigDBO(false, false, false, AppThemeDBO.system);

  factory ConfigDBO.fromConfigEntity(ConfigEntity entity) => ConfigDBO(
        entity.hasAcceptedDisclaimer,
        entity.hasAcceptedPolicy,
        entity.hasAcceptedSendAnonymousData,
        AppThemeDBO.fromAppThemeEntity(entity.appTheme),
        usesImperialUnits: entity.usesImperialUnits,
        caloriesTaperEnabled: entity.caloriesTaperEnabled,
      );

  factory ConfigDBO.fromJson(Map<String, dynamic> json) =>
      _$ConfigDBOFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigDBOToJson(this);
}
