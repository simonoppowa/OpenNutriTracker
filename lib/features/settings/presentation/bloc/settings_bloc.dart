import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/app_const.dart';

part 'settings_event.dart';

part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final log = Logger('SettingsBloc');

  final GetUserUsecase _getUserUsecase;
  final GetConfigUsecase _getConfigUsecase;
  final AddConfigUsecase _addConfigUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;

  SettingsBloc(
      this._getUserUsecase,
      this._getConfigUsecase,
      this._addConfigUsecase,
      this._addTrackedDayUsecase,
      this._getKcalGoalUsecase,
      this._getMacroGoalUsecase)
      : super(SettingsInitial()) {
    on<LoadSettingsEvent>((event, emit) async {
      emit(SettingsLoadingState());

      final user = await _getUserUsecase.getUserData();
      final userConfig = await _getConfigUsecase.getConfig();
      final appVersion = await AppConst.getVersionNumber();
      final usesImperialUnits = userConfig.usesImperialUnits;

      emit(SettingsLoadedState(
          appVersion,
          user,
          userConfig.showActivityTracker,
          userConfig.hasAcceptedSendAnonymousData,
          userConfig.appTheme,
          usesImperialUnits));
    });
  }

  void setShowActivityTracker(bool showActivityTracker) {
    _addConfigUsecase
        .setConfigShowActivityTracker(showActivityTracker);
  }

  void setHasAcceptedAnonymousData(bool hasAcceptedAnonymousData) {
    _addConfigUsecase
        .setConfigHasAcceptedAnonymousData(hasAcceptedAnonymousData);
  }

  void setAppTheme(AppThemeEntity appTheme) async {
    await _addConfigUsecase.setConfigAppTheme(appTheme);
  }

  void setUsesImperialUnits(bool usesImperialUnits) {
    _addConfigUsecase.setConfigUsesImperialUnits(usesImperialUnits);
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

  void setKcalAdjustment(double kcalAdjustment) {
    _addConfigUsecase.setConfigKcalAdjustment(kcalAdjustment);
  }
  void setMacroGoals(
      double carbGoalPct, double proteinGoalPct, double fatGoalPct) {
    _addConfigUsecase.setConfigMacroGoalPct(carbGoalPct.toInt() / 100,
        proteinGoalPct.toInt() / 100, fatGoalPct.toInt() / 100);
  }

  Future<bool> getAutoBackupEnabled() async {
    final config = await _getConfigUsecase.getConfig();
    return config.autoBackupEnabled ?? false;
  }

  Future<String?> getAutoBackupLocation() async {
    final config = await _getConfigUsecase.getConfig();
    return config.autoBackupLocation;
  }

  Future<int?> getAutoBackupIntervalDays() async {
    final config = await _getConfigUsecase.getConfig();
    return config.autoBackupIntervalDays;
  }

  Future<bool> getAutoBackupOverwrite() async {
    final config = await _getConfigUsecase.getConfig();
    return config.autoBackupOverwrite ?? true;
  }

  void setAutoBackupConfig(bool autoBackupEnabled, String? autoBackupLocation, int? autoBackupIntervalDays, bool? autoBackupOverwrite) {
    _addConfigUsecase.setAutoBackupConfig(autoBackupEnabled, autoBackupLocation, autoBackupIntervalDays, autoBackupOverwrite);
  }

  void updateTrackedDay(DateTime day) async {
    final day = DateTime.now();
    final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
    final totalCarbsGoal =
        await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
    final totalFatGoal = await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
    final totalProteinGoal =
        await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);

    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);

    if (hasTrackedDay) {
      await _addTrackedDayUsecase.updateDayCalorieGoal(day, totalKcalGoal);
      await _addTrackedDayUsecase.updateDayMacroGoals(day,
          carbsGoal: totalCarbsGoal,
          fatGoal: totalFatGoal,
          proteinGoal: totalProteinGoal);
    }
  }
}

enum SystemDropDownType { metric, imperial }

enum BackupIntervalDropDownType { daily, weekly, monthly }

enum BackupBehaviorDropDownType { overwrite, createNew }

BackupIntervalDropDownType? getBackupIntervalEnumFromValue(int intervalDays) {
  switch(intervalDays) {
    case 1:
      return BackupIntervalDropDownType.daily;
    case 7:
      return BackupIntervalDropDownType.weekly;
    case 30:
      return BackupIntervalDropDownType.monthly;
    default:
      return null;
  }
}

int? getBackupIntervalValueFromEnum(BackupIntervalDropDownType intervalEnum) {
  switch(intervalEnum) {
    case BackupIntervalDropDownType.daily:
      return 1;
    case BackupIntervalDropDownType.weekly:
      return 7;
    case BackupIntervalDropDownType.monthly:
      return 30;
  }
}
