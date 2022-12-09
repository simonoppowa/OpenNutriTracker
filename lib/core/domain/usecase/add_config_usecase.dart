import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:provider/provider.dart';

class AddConfigUsecase {
  Future<void> addConfig(
      BuildContext context, ConfigEntity configEntity) async {
    final configRepository =
        Provider.of<ConfigRepository>(context, listen: false);
    configRepository.updateConfig(configEntity);
  }

  Future<void> setConfigDisclaimer(
      BuildContext context, bool hasAcceptedDisclaimer) async {
    final configRepository =
        Provider.of<ConfigRepository>(context, listen: false);
    configRepository.setConfigDisclaimer(hasAcceptedDisclaimer);
  }
}
