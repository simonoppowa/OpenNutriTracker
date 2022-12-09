import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

class ConfigEntity {
  bool hasAcceptedDisclaimer;
  bool hasAcceptedPolicy;

  ConfigEntity(this.hasAcceptedDisclaimer, this.hasAcceptedPolicy);

  factory ConfigEntity.fromConfigDBO(ConfigDBO dbo) =>
      ConfigEntity(dbo.hasAcceptedDisclaimer, dbo.hasAcceptedPolicy);
}
