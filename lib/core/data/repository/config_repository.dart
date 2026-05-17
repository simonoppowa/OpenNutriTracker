import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

class ConfigRepository {
  final ConfigDataSource _configDataSource;

  ConfigRepository(this._configDataSource);

  Future<void> updateConfig(ConfigEntity configEntity) async {
    final configDBO = ConfigDBO.fromConfigEntity(configEntity);
    await _configDataSource.addConfig(configDBO);
  }

  Future<void> setConfigDisclaimer(bool hasAcceptedDisclaimer) async {
    await _configDataSource.setConfigDisclaimer(hasAcceptedDisclaimer);
  }

  Future<void> setConfigHasAcceptedAnonymousData(
    bool hasAcceptedAnonymousData,
  ) async {
    await _configDataSource.setConfigAcceptedAnonymousData(
      hasAcceptedAnonymousData,
    );
  }

  Future<bool> getConfigHasAcceptedAnonymousData() async {
    return await _configDataSource.getHasAcceptedAnonymousData();
  }

  Future<AppThemeEntity> getConfigAppTheme() async {
    final appThemeDBO = await _configDataSource.getAppTheme();
    return AppThemeEntity.fromAppThemeDBO(appThemeDBO);
  }

  Future<void> setConfigAppTheme(AppThemeEntity appTheme) async {
    await _configDataSource.setConfigAppTheme(
      AppThemeDBO.fromAppThemeEntity(appTheme),
    );
  }

  Future<ConfigEntity> getConfig() async {
    final configDBO = await _configDataSource.getConfig();
    return ConfigEntity.fromConfigDBO(configDBO);
  }

  Future<ConfigDBO> getConfigDBO() async {
    final configDBO = await _configDataSource.getConfig();
    return configDBO;
  }

  Future<void> setConfigUsesImperialUnits(bool usesImperialUnits) async {
    await _configDataSource.setConfigUsesImperialUnits(usesImperialUnits);
  }

  Future<double> getConfigKcalAdjustment() async {
    return await _configDataSource.getKcalAdjustment();
  }

  Future<void> setConfigKcalAdjustment(double kcalAdjustment) async {
    await _configDataSource.setConfigKcalAdjustment(kcalAdjustment);
  }

  Future<void> setConfigShowActivityTracking(bool show) async {
    await _configDataSource.setConfigShowActivityTracking(show);
  }

  Future<void> setConfigShowMealMacros(bool show) async {
    await _configDataSource.setConfigShowMealMacros(show);
  }

  Future<void> setUserMacroPct(double carbs, double protein, double fat) async {
    await _configDataSource.setConfigCarbGoalPct(carbs);
    await _configDataSource.setConfigProteinGoalPct(protein);
    await _configDataSource.setConfigFatGoalPct(fat);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _configDataSource.setNotificationsEnabled(enabled);
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    await _configDataSource.setNotificationTime(hour, minute);
  }

  Future<String?> getSelectedLocale() async {
    return await _configDataSource.getSelectedLocale();
  }

  Future<void> setSelectedLocale(String? locale) async {
    await _configDataSource.setSelectedLocale(locale);
  }

  Future<void> setConfigShowMicronutrients(bool show) async {
    await _configDataSource.setConfigShowMicronutrients(show);
  }

  Future<void> setConfigUsesKilojoules(bool usesKilojoules) async {
    await _configDataSource.setConfigUsesKilojoules(usesKilojoules);
  }

  Future<void> setConfigMealKcalSharesPct(Map<String, int> shares) async {
    await _configDataSource.setConfigMealKcalSharesPct(shares);
  }

  Future<String?> getCustomMealFormMode() async {
    return await _configDataSource.getCustomMealFormMode();
  }

  Future<void> setCustomMealFormMode(String mode) async {
    await _configDataSource.setCustomMealFormMode(mode);
  }

  Future<Map<String, int>?> getDiarySortPreferences() async {
    return await _configDataSource.getDiarySortPreferences();
  }

  Future<void> setDiarySortPreference(String mealKey, int sortIndex) async {
    await _configDataSource.setDiarySortPreference(mealKey, sortIndex);
  }

  Future<void> setConfigNutrientPanelVisibility(
    Map<String, bool> visibility,
  ) async {
    await _configDataSource.setConfigNutrientPanelVisibility(visibility);
  }

  Future<void> setConfigDayStartOffsetHours(int hours) async {
    await _configDataSource.setConfigDayStartOffsetHours(hours);
  }

  Future<void> setConfigDayStartOffsetMinutes(int minutes) async {
    await _configDataSource.setConfigDayStartOffsetMinutes(minutes);
  }

  Future<void> setConfigDailyWaterGoalMl(int goalMl) async {
    await _configDataSource.setConfigDailyWaterGoalMl(goalMl);
  }

  Future<void> setFastingWarningAcknowledged(bool acknowledged) async {
    await _configDataSource.setFastingWarningAcknowledged(acknowledged);
  }

  Future<void> setConfigUseMaterialYou(bool useMaterialYou) async {
    await _configDataSource.setConfigUseMaterialYou(useMaterialYou);
  }

  Future<void> setConfigAccentColor(int? value) async {
    await _configDataSource.setConfigAccentColor(value);
  }
}
