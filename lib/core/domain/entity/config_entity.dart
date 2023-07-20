import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';

class ConfigEntity extends Equatable {
  final bool hasAcceptedDisclaimer;
  final bool hasAcceptedPolicy;
  final bool hasAcceptedSendAnonymousData;
  final AppThemeEntity appTheme;

  const ConfigEntity(this.hasAcceptedDisclaimer, this.hasAcceptedPolicy,
      this.hasAcceptedSendAnonymousData, this.appTheme);

  factory ConfigEntity.fromConfigDBO(ConfigDBO dbo) => ConfigEntity(
      dbo.hasAcceptedDisclaimer,
      dbo.hasAcceptedPolicy,
      dbo.hasAcceptedSendAnonymousData,
      AppThemeEntity.fromAppThemeDBO(dbo.selectedAppTheme));

  @override
  List<Object?> get props =>
      [hasAcceptedDisclaimer, hasAcceptedPolicy, hasAcceptedSendAnonymousData];
}
