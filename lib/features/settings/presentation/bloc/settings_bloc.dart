import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/app_const.dart';

part 'settings_event.dart';

part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final log = Logger('SettingsBloc');

  final GetConfigUsecase _getConfigUsecase;
  final AddConfigUsecase _addConfigUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final RemoteSearchCacheDataSource _cachedOffMealDataSource;
  // #173: needed so the Calculations dialog can pre-fill its
  // fibre / sat-fat / sugar sliders with the user's existing per-day
  // overrides rather than always starting from defaults.
  final GetTrackedDayUsecase _getTrackedDayUsecase;

  SettingsBloc(
    this._getConfigUsecase,
    this._addConfigUsecase,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
    this._cachedOffMealDataSource,
    this._getTrackedDayUsecase,
  ) : super(SettingsInitial()) {
    on<LoadSettingsEvent>((event, emit) async {
      emit(SettingsLoadingState());

      final userConfig = await _getConfigUsecase.getConfig();
      final appVersion = await AppConst.getVersionNumber();
      final usesImperialUnits = userConfig.usesImperialUnits;
      final offCacheCount = _cachedOffMealDataSource.count;
      final offCacheSizeBytes =
          await _cachedOffMealDataSource.getStorageSizeBytes();

      emit(
        SettingsLoadedState(
          appVersion,
          userConfig.hasAcceptedSendAnonymousData,
          userConfig.appTheme,
          usesImperialUnits,
          showActivityTracking: userConfig.showActivityTracking,
          showMealMacros: userConfig.showMealMacros,
          notificationsEnabled: userConfig.notificationsEnabled,
          notificationHour: userConfig.notificationHour,
          notificationMinute: userConfig.notificationMinute,
          selectedLocale: userConfig.selectedLocale,
          offCacheCount: offCacheCount,
          offCacheSizeBytes: offCacheSizeBytes,
          showMicronutrients: userConfig.showMicronutrients,
          usesKilojoules: userConfig.usesKilojoules,
          caloriesTaperEnabled: userConfig.caloriesTaperEnabled,
          dayStartOffsetHours: userConfig.dayStartOffsetHours,
          dayStartOffsetMinutes: userConfig.dayStartOffsetMinutes,
        ),
      );
    });
  }

  Future<void> clearOffCache() async {
    await _cachedOffMealDataSource.clear();
    add(LoadSettingsEvent());
  }

  void setHasAcceptedAnonymousData(bool hasAcceptedAnonymousData) {
    _addConfigUsecase.setConfigHasAcceptedAnonymousData(
      hasAcceptedAnonymousData,
    );
  }

  void setAppTheme(AppThemeEntity appTheme) async {
    await _addConfigUsecase.setConfigAppTheme(appTheme);
  }

  void setUsesImperialUnits(bool usesImperialUnits) {
    _addConfigUsecase.setConfigUsesImperialUnits(usesImperialUnits);
  }

  void setShowActivityTracking(bool showActivityTracking) {
    _addConfigUsecase.setConfigShowActivityTracking(showActivityTracking);
  }

  void setShowMealMacros(bool showMealMacros) {
    _addConfigUsecase.setConfigShowMealMacros(showMealMacros);
  }

  void setNotificationsEnabled(bool enabled) {
    _addConfigUsecase.setNotificationsEnabled(enabled);
  }

  void setNotificationTime(int hour, int minute) {
    _addConfigUsecase.setNotificationTime(hour, minute);
  }

  void setSelectedLocale(String? locale) {
    _addConfigUsecase.setSelectedLocale(locale);
  }

  void setShowMicronutrients(bool show) {
    _addConfigUsecase.setConfigShowMicronutrients(show);
  }

  void setUsesKilojoules(bool usesKilojoules) {
    _addConfigUsecase.setConfigUsesKilojoules(usesKilojoules);
  }

  void setCaloriesTaperEnabled(bool enabled) {
    _addConfigUsecase.setConfigCaloriesTaperEnabled(enabled);
  }

  Future<Map<String, int>?> getDiarySortPreferences() async {
    final config = await _getConfigUsecase.getConfig();
    return config.diarySortPreferences;
  }

  Future<void> setDiarySortPreference(String mealKey, int sortIndex) async {
    await _addConfigUsecase.setDiarySortPreference(mealKey, sortIndex);
  }

  // #139: persist the configurable diary day boundary (0-23).
  Future<void> setDayStartOffsetHours(int hours) async {
    await _addConfigUsecase.setConfigDayStartOffsetHours(hours);
  }

  Future<int> getDayStartOffsetHours() async {
    final config = await _getConfigUsecase.getConfig();
    return config.dayStartOffsetHours;
  }

  // #139 follow-up: persist the minute component (0-59) of the diary
  // day boundary so shift workers on 04:30 (or 03:45) can be exact.
  Future<void> setDayStartOffsetMinutes(int minutes) async {
    await _addConfigUsecase.setConfigDayStartOffsetMinutes(minutes);
  }

  Future<int> getDayStartOffsetMinutes() async {
    final config = await _getConfigUsecase.getConfig();
    return config.dayStartOffsetMinutes;
  }

  Future<double> getKcalAdjustment() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userKcalAdjustment ?? 0;
  }

  Future<double?> getUserCarbGoalPct() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userCarbGoalPct;
  }

  Future<double?> getUserProteinGoalPct() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userProteinGoalPct;
  }

  Future<double?> getUserFatGoalPct() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userFatGoalPct;
  }

  Future<void> setKcalAdjustment(double kcalAdjustment) async {
    await _addConfigUsecase.setConfigKcalAdjustment(kcalAdjustment);
  }

  Future<void> setMacroGoals(
    double carbGoalPct,
    double proteinGoalPct,
    double fatGoalPct,
  ) async {
    await _addConfigUsecase.setConfigMacroGoalPct(
      carbGoalPct.toInt() / 100,
      proteinGoalPct.toInt() / 100,
      fatGoalPct.toInt() / 100,
    );
  }

  // #150: per-meal kcal share configuration
  Future<Map<String, int>> getMealKcalSharesPct() async {
    final config = await _getConfigUsecase.getConfig();
    return config.mealKcalSharesPct;
  }

  Future<void> setMealKcalSharesPct(Map<String, int> shares) async {
    await _addConfigUsecase.setConfigMealKcalSharesPct(shares);
  }

  /// #173: read today's per-nutrient goal overrides from the stored
  /// TrackedDayDBO row. The dialog uses these to pre-fill the sliders
  /// so users see their previously-saved targets rather than defaults.
  /// Returns nulls (and a null entity) when nothing has been logged
  /// for the day yet.
  Future<TrackedDayEntity?> getTodayTrackedDay(DateTime day) async {
    return await _getTrackedDayUsecase.getTrackedDay(day);
  }

  /// #173 (+follow-up): persist user-set per-nutrient goals to today's
  /// tracked-day row. Must be called after ensuring the row exists (the
  /// macro updateTrackedDay flow takes care of creating it). Accepts
  /// the original three nutrients plus the seven from the follow-up.
  Future<void> setTodayNutrientGoals(
    DateTime day, {
    double? fibreGoal,
    double? satFatGoal,
    double? sugarsGoal,
    double? sodiumGoal,
    double? calciumGoal,
    double? ironGoal,
    double? potassiumGoal,
    double? vitaminDGoal,
    double? vitaminB12Goal,
    double? magnesiumGoal,
  }) async {
    await _addTrackedDayUsecase.updateDayNutrientGoals(
      day,
      fibreGoal: fibreGoal,
      satFatGoal: satFatGoal,
      sugarsGoal: sugarsGoal,
      sodiumGoal: sodiumGoal,
      calciumGoal: calciumGoal,
      ironGoal: ironGoal,
      potassiumGoal: potassiumGoal,
      vitaminDGoal: vitaminDGoal,
      vitaminB12Goal: vitaminB12Goal,
      magnesiumGoal: magnesiumGoal,
    );
  }

  Future<void> updateTrackedDay(DateTime day) async {
    final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
    final totalCarbsGoal = await _getMacroGoalUsecase.getCarbsGoal(
      totalKcalGoal,
    );
    final totalFatGoal = await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
    final totalProteinGoal = await _getMacroGoalUsecase.getProteinsGoal(
      totalKcalGoal,
    );

    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);

    if (hasTrackedDay) {
      await _addTrackedDayUsecase.updateDayCalorieGoal(day, totalKcalGoal);
      await _addTrackedDayUsecase.updateDayMacroGoals(
        day,
        carbsGoal: totalCarbsGoal,
        fatGoal: totalFatGoal,
        proteinGoal: totalProteinGoal,
      );
    }
  }
}

enum SystemDropDownType { metric, imperial }
