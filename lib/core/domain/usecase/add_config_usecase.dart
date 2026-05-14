import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

class AddConfigUsecase {
  final ConfigRepository _configRepository;

  AddConfigUsecase(this._configRepository);

  Future<void> addConfig(ConfigEntity configEntity) async {
    _configRepository.updateConfig(configEntity);
  }

  Future<void> setConfigDisclaimer(bool hasAcceptedDisclaimer) async {
    _configRepository.setConfigDisclaimer(hasAcceptedDisclaimer);
  }

  Future<void> setConfigHasAcceptedAnonymousData(
    bool hasAcceptedAnonymousData,
  ) async {
    await _configRepository.setConfigHasAcceptedAnonymousData(
      hasAcceptedAnonymousData,
    );
  }

  Future<void> setConfigAppTheme(AppThemeEntity appTheme) async {
    await _configRepository.setConfigAppTheme(appTheme);
  }

  Future<void> setConfigUsesImperialUnits(bool usesImperialUnits) async {
    await _configRepository.setConfigUsesImperialUnits(usesImperialUnits);
  }

  Future<void> setConfigKcalAdjustment(double kcalAdjustment) async {
    await _configRepository.setConfigKcalAdjustment(kcalAdjustment);
  }

  Future<void> setConfigMacroGoalPct(
    double carbGoalPct,
    double proteinGoalPct,
    double fatPctGoal,
  ) async {
    await _configRepository.setUserMacroPct(
      carbGoalPct,
      proteinGoalPct,
      fatPctGoal,
    );
  }


  Future<void> setConfigShowActivityTracking(bool show) async {
    _configRepository.setConfigShowActivityTracking(show);
  }

  Future<void> setConfigShowMealMacros(bool show) async {
    _configRepository.setConfigShowMealMacros(show);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _configRepository.setNotificationsEnabled(enabled);
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    _configRepository.setNotificationTime(hour, minute);
  }

  Future<void> setSelectedLocale(String? locale) async {
    _configRepository.setSelectedLocale(locale);
  }

  Future<void> setConfigShowMicronutrients(bool show) async {
    _configRepository.setConfigShowMicronutrients(show);
  }

  Future<void> setConfigUsesKilojoules(bool usesKilojoules) async {
    await _configRepository.setConfigUsesKilojoules(usesKilojoules);
  }

  Future<void> setConfigCaloriesTaperEnabled(bool enabled) async {
    await _configRepository.setConfigCaloriesTaperEnabled(enabled);
  }

  Future<void> setDiarySortPreference(String mealKey, int sortIndex) async {
    await _configRepository.setDiarySortPreference(mealKey, sortIndex);
  }

  Future<void> setConfigNutrientPanelVisibility(
    Map<String, bool> visibility,
  ) async {
    await _configRepository.setConfigNutrientPanelVisibility(visibility);
  }
}
