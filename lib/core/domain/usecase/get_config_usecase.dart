import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

class GetConfigUsecase {
  final ConfigRepository _configRepository;

  GetConfigUsecase(this._configRepository);

  Future<ConfigEntity> getConfig() async {
    return await _configRepository.getConfig();
  }

  /// Whether the user has ever chosen which food databases to search.
  /// Null in the DBO means untouched; [ConfigEntity] flattens that to an
  /// empty map, which reads the same as "all enabled".
  Future<bool> hasExplicitFoodSourceToggles() async {
    final config = await _configRepository.getConfigDBO();
    final toggles = config.foodSourceToggles;
    return toggles != null && toggles.isNotEmpty;
  }

  /// Whether a unit preference has ever been stored, as opposed to merely
  /// defaulted. [ConfigEntity] coerces unset units to metric, so this reads
  /// the DBO where the split unit fields remain nullable. The legacy flag is
  /// conclusive only when true because fresh installs default it to false.
  Future<bool> hasExplicitUnitPreferences() async {
    final config = await _configRepository.getConfigDBO();
    return config.usesImperialFoodUnits != null ||
        config.usesImperialHeightUnits != null ||
        config.bodyWeightUnitIndex != null ||
        config.usesImperialUnits == true;
  }
}
