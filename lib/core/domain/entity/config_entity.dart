import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

class ConfigEntity {
  final bool hasAcceptedDisclaimer;
  final bool hasAcceptedPolicy;

  ConfigEntity(this.hasAcceptedDisclaimer, this.hasAcceptedPolicy);

  factory ConfigEntity.fromConfigDBO(ConfigDBO dbo) =>
      ConfigEntity(dbo.hasAcceptedDisclaimer, dbo.hasAcceptedPolicy);
}
