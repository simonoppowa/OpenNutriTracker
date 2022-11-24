import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

part 'config_dbo.g.dart';

@HiveType(typeId: 13)
class ConfigDBO {
  @HiveField(0)
  bool hasAcceptedDisclaimer;
  @HiveField(1)
  bool hasAcceptedPolicy;

  ConfigDBO(this.hasAcceptedDisclaimer, this.hasAcceptedPolicy);

  factory ConfigDBO.empty() => ConfigDBO(false, false);

  factory ConfigDBO.fromConfigEntity(ConfigEntity entity) =>
      ConfigDBO(entity.hasAcceptedDisclaimer, entity.hasAcceptedPolicy);
}
