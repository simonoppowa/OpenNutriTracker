import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

class ConfigEntity extends Equatable {
  final bool hasAcceptedDisclaimer;
  final bool hasAcceptedPolicy;
  final bool hasAcceptedSendAnonymousData;

  const ConfigEntity(this.hasAcceptedDisclaimer, this.hasAcceptedPolicy,
      this.hasAcceptedSendAnonymousData);

  factory ConfigEntity.fromConfigDBO(ConfigDBO dbo) => ConfigEntity(
      dbo.hasAcceptedDisclaimer,
      dbo.hasAcceptedPolicy,
      dbo.hasAcceptedSendAnonymousData);

  @override
  List<Object?> get props => [hasAcceptedDisclaimer, hasAcceptedPolicy];
}
