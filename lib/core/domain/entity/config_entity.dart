import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

class ConfigEntity extends Equatable {
  final bool hasAcceptedDisclaimer;
  final bool hasAcceptedPolicy;

  const ConfigEntity(this.hasAcceptedDisclaimer, this.hasAcceptedPolicy);

  factory ConfigEntity.fromConfigDBO(ConfigDBO dbo) =>
      ConfigEntity(dbo.hasAcceptedDisclaimer, dbo.hasAcceptedPolicy);

  @override
  List<Object?> get props => [hasAcceptedDisclaimer, hasAcceptedPolicy];
}
