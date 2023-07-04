import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

class AddConfigUsecase {
  final ConfigRepository _configRepository;

  AddConfigUsecase(this._configRepository);

  Future<void> addConfig(ConfigEntity configEntity) async {
    _configRepository.updateConfig(configEntity);
  }

  Future<void> setConfigDisclaimer(bool hasAcceptedDisclaimer) async {
    _configRepository.setConfigDisclaimer(hasAcceptedDisclaimer);
  }
}
