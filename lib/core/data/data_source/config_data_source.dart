import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

class ConfigDataSource {
  static const _configKey = "ConfigKey";

  final _log = Logger('ConfigDataSource');
  final Box<ConfigDBO> _configBox;

  ConfigDataSource(this._configBox);

  Future<bool> configInitialized() async => _configBox.containsKey(_configKey);

  Future<void> initializeConfig() async =>
      _configBox.put(_configKey, ConfigDBO.empty());

  Future<void> addConfig(ConfigDBO configDBO) async {
    _log.fine('Adding new config item to db');
    await _configBox.put(_configKey, configDBO);
  }

  Future<void> setConfigDisclaimer(bool hasAcceptedDisclaimer) async {
    _log.fine(
      'Updating config hasAcceptedDisclaimer to $hasAcceptedDisclaimer',
    );
    final config = _configBox.get(_configKey);
    config?.hasAcceptedDisclaimer = hasAcceptedDisclaimer;
    await config?.save();
  }

  Future<void> setConfigAcceptedAnonymousData(
    bool hasAcceptedAnonymousData,
  ) async {
    _log.fine(
      'Updating config hasAcceptedAnonymousData to $hasAcceptedAnonymousData',
    );
    final config = _configBox.get(_configKey);
    config?.hasAcceptedSendAnonymousData = hasAcceptedAnonymousData;
    await config?.save();
  }

  Future<AppThemeDBO> getAppTheme() async {
    final config = _configBox.get(_configKey);
    return config?.selectedAppTheme ?? AppThemeDBO.defaultTheme;
  }

  Future<void> setConfigAppTheme(AppThemeDBO appTheme) async {
    _log.fine('Updating config appTheme to $appTheme');
    final config = _configBox.get(_configKey);
    config?.selectedAppTheme = appTheme;
    await config?.save();
  }

  Future<void> setConfigUsesImperialUnits(bool usesImperialUnits) async {
    _log.fine('Updating config usesImperialUnits to $usesImperialUnits');
    final config = _configBox.get(_configKey);
    config?.usesImperialUnits = usesImperialUnits;
    await config?.save();
  }

  Future<double> getKcalAdjustment() async {
    final config = _configBox.get(_configKey);
    return config?.userKcalAdjustment ?? 0;
  }

  Future<void> setConfigKcalAdjustment(double kcalAdjustment) async {
    _log.fine('Updating config kcalAdjustment to $kcalAdjustment');
    final config = _configBox.get(_configKey);
    config?.userKcalAdjustment = kcalAdjustment;
    await config?.save();
  }

  Future<void> setConfigCarbGoalPct(double carbGoalPct) async {
    _log.fine('Updating config carbGoalPct to $carbGoalPct');
    final config = _configBox.get(_configKey);
    config?.userCarbGoalPct = carbGoalPct;
    await config?.save();
  }

  Future<void> setConfigProteinGoalPct(double proteinGoalPct) async {
    _log.fine('Updating config proteinGoalPct to $proteinGoalPct');
    final config = _configBox.get(_configKey);
    config?.userProteinGoalPct = proteinGoalPct;
    await config?.save();
  }

  Future<void> setConfigFatGoalPct(double fatGoalPct) async {
    _log.fine('Updating config fatGoalPct to $fatGoalPct');
    final config = _configBox.get(_configKey);
    config?.userFatGoalPct = fatGoalPct;
    await config?.save();
  }

  Future<void> setConfigShowActivityTracking(bool show) async {
    _log.fine('Updating config showActivityTracking to $show');
    final config = _configBox.get(_configKey);
    config?.showActivityTracking = show;
    await config?.save();
  }

  Future<void> setConfigShowMealMacros(bool show) async {
    _log.fine('Updating config showMealMacros to $show');
    final config = _configBox.get(_configKey);
    config?.showMealMacros = show;
    await config?.save();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _log.fine('Updating config notificationsEnabled to $enabled');
    final config = _configBox.get(_configKey);
    config?.notificationsEnabled = enabled;
    await config?.save();
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    _log.fine('Updating config notification time to $hour:$minute');
    final config = _configBox.get(_configKey);
    config?.notificationHour = hour;
    config?.notificationMinute = minute;
    await config?.save();
  }

  Future<String?> getSelectedLocale() async {
    final config = _configBox.get(_configKey);
    final raw = config?.selectedLocale;
    // Backward-compat: the project used to ship Czech as 'cz' (non-standard).
    // It was renamed to the BCP-47 code 'cs' so iOS surfaces it correctly in
    // its system language picker. Migrate any stored 'cz' value silently so
    // existing users keep their language preference across the rename.
    if (raw == 'cz') return 'cs';
    return raw;
  }

  Future<void> setSelectedLocale(String? locale) async {
    _log.fine('Updating config selectedLocale to $locale');
    final config = _configBox.get(_configKey);
    config?.selectedLocale = locale;
    await config?.save();
  }

  Future<void> setConfigShowMicronutrients(bool show) async {
    _log.fine('Updating config showMicronutrients to $show');
    final config = _configBox.get(_configKey);
    config?.showMicronutrients = show;
    await config?.save();
  }

  Future<void> setConfigUsesKilojoules(bool usesKilojoules) async {
    _log.fine('Updating config usesKilojoules to $usesKilojoules');
    final config = _configBox.get(_configKey);
    config?.usesKilojoules = usesKilojoules;
    await config?.save();
  }

  Future<bool> getCaloriesTaperEnabled() async {
    final config = _configBox.get(_configKey);
    return config?.caloriesTaperEnabled ?? false;
  }

  Future<void> setConfigCaloriesTaperEnabled(bool enabled) async {
    _log.fine('Updating config caloriesTaperEnabled to $enabled');
    final config = _configBox.get(_configKey);
    config?.caloriesTaperEnabled = enabled;
    await config?.save();
  }

  Future<Map<String, int>?> getDiarySortPreferences() async {
    final config = _configBox.get(_configKey);
    final stored = config?.diarySortPreferences;
    if (stored == null) return null;
    // The Hive-generated adapter hands us a Map<dynamic, dynamic>.cast<String,
    // int>() view; eagerly copy into a concrete map so callers see a real
    // Map<String, int> rather than a lazy cast view that throws on access if
    // anything unexpected ever lands in the box.
    return Map<String, int>.from(stored);
  }

  Future<void> setDiarySortPreference(String mealKey, int sortIndex) async {
    _log.fine('Updating config diarySortPreferences[$mealKey] = $sortIndex');
    final config = _configBox.get(_configKey);
    if (config == null) return;
    final current = config.diarySortPreferences;
    // Build a fresh Map<String, int> so the write doesn't share storage with
    // whatever map type Hive handed back, and so the cast lands eagerly
    // rather than lazily at read time.
    final next = <String, int>{
      if (current != null) ...Map<String, int>.from(current),
      mealKey: sortIndex,
    };
    config.diarySortPreferences = next;
    await config.save();
  }

  Future<void> setConfigNutrientPanelVisibility(
    Map<String, bool> visibility,
  ) async {
    _log.fine('Updating nutrientPanelVisibility to $visibility');
    final config = _configBox.get(_configKey);
    // Persist a defensive copy — Hive serialises whatever we hand it, and a
    // caller-owned map mutating later would silently change the saved value.
    config?.nutrientPanelVisibility = Map<String, bool>.from(visibility);
    await config?.save();
  }

  Future<ConfigDBO> getConfig() async {
    return _configBox.get(_configKey) ?? ConfigDBO.empty();
  }

  Future<bool> getHasAcceptedAnonymousData() async {
    final config = _configBox.get(_configKey);
    return config?.hasAcceptedSendAnonymousData ?? false;
  }
}
