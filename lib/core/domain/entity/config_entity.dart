import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';

class ConfigEntity extends Equatable {
  final bool hasAcceptedDisclaimer;
  final bool hasAcceptedPolicy;
  final bool showActivityTracker;
  final bool hasAcceptedSendAnonymousData;
  final AppThemeEntity appTheme;
  final bool usesImperialUnits;
  final double? userKcalAdjustment;
  final double? userCarbGoalPct;
  final double? userProteinGoalPct;
  final double? userFatGoalPct;
  // Automatic backup
  final bool? autoBackupEnabled;
  final String? autoBackupLocation;
  final int? autoBackupIntervalDays;
  final bool? autoBackupOverwrite;

  const ConfigEntity(this.hasAcceptedDisclaimer,
      this.hasAcceptedPolicy,
      this.showActivityTracker,
      this.hasAcceptedSendAnonymousData,
      this.appTheme,
      {this.usesImperialUnits = false,
      this.userKcalAdjustment,
      this.userCarbGoalPct,
      this.userProteinGoalPct,
      this.userFatGoalPct,
      this.autoBackupEnabled,
      this.autoBackupLocation,
      this.autoBackupIntervalDays,
      this.autoBackupOverwrite});

  factory ConfigEntity.fromConfigDBO(ConfigDBO dbo) => ConfigEntity(
        dbo.hasAcceptedDisclaimer,
        dbo.hasAcceptedPolicy,
        dbo.showActivityTracker ?? true,
        dbo.hasAcceptedSendAnonymousData,
        AppThemeEntity.fromAppThemeDBO(dbo.selectedAppTheme),
        usesImperialUnits: dbo.usesImperialUnits ?? false,
        userKcalAdjustment: dbo.userKcalAdjustment,
        userCarbGoalPct: dbo.userCarbGoalPct,
        userProteinGoalPct: dbo.userProteinGoalPct,
        userFatGoalPct: dbo.userFatGoalPct,
        autoBackupEnabled: dbo.autoBackupEnabled,
        autoBackupLocation: dbo.autoBackupLocation,
        autoBackupIntervalDays: dbo.autoBackupIntervalDays,
        autoBackupOverwrite: dbo.autoBackupOverwrite,
      );

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
        autoBackupEnabled,
        autoBackupLocation,
        autoBackupIntervalDays,
        autoBackupOverwrite,
      ];
}
