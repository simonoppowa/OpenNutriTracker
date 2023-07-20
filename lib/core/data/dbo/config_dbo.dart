import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

part 'config_dbo.g.dart';

@HiveType(typeId: 13)
class ConfigDBO extends HiveObject {
  @HiveField(0)
  bool hasAcceptedDisclaimer;
  @HiveField(1)
  bool hasAcceptedPolicy;
  @HiveField(2)
  bool hasAcceptedSendAnonymousData;
  @HiveField(3)
  AppThemeDBO selectedAppTheme;

  ConfigDBO(this.hasAcceptedDisclaimer, this.hasAcceptedPolicy,
      this.hasAcceptedSendAnonymousData, this.selectedAppTheme);

  factory ConfigDBO.empty() =>
      ConfigDBO(false, false, false, AppThemeDBO.system);

  factory ConfigDBO.fromConfigEntity(ConfigEntity entity) => ConfigDBO(
      entity.hasAcceptedDisclaimer,
      entity.hasAcceptedPolicy,
      entity.hasAcceptedSendAnonymousData,
      AppThemeDBO.fromAppThemeEntity(entity.appTheme));
}
