part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  @override
  List<Object> get props => [];
}

class SettingsLoadingState extends SettingsState {
  @override
  List<Object?> get props => [];
}

class SettingsLoadedState extends SettingsState {
  final String versionNumber;
  final bool sendAnonymousData;
  final AppThemeEntity appTheme;
  final bool usesImperialUnits;
  final bool showActivityTracking;
  final bool showMealMacros;
  final bool notificationsEnabled;
  final int notificationHour;
  final int notificationMinute;
  final String? selectedLocale;
  final int offCacheCount;
  final int offCacheSizeBytes;
  final bool showMicronutrients; // #237
  final bool usesKilojoules; // #177
  final bool caloriesTaperEnabled; // #119 follow-up

  const SettingsLoadedState(
    this.versionNumber,
    this.sendAnonymousData,
    this.appTheme,
    this.usesImperialUnits, {
    this.showActivityTracking = true,
    this.showMealMacros = true,
    this.notificationsEnabled = false,
    this.notificationHour = 8,
    this.notificationMinute = 0,
    this.selectedLocale,
    this.offCacheCount = 0,
    this.offCacheSizeBytes = 0,
    this.showMicronutrients = false,
    this.usesKilojoules = false,
    this.caloriesTaperEnabled = false,
  });

  @override
  List<Object?> get props => [
        versionNumber,
        sendAnonymousData,
        appTheme,
        usesImperialUnits,
        showActivityTracking,
        showMealMacros,
        notificationsEnabled,
        notificationHour,
        notificationMinute,
        selectedLocale,
        offCacheCount,
        offCacheSizeBytes,
        showMicronutrients,
        usesKilojoules,
        caloriesTaperEnabled,
      ];
}
