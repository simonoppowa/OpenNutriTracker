import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

class GetConfigUsecase {
  final ConfigRepository _configRepository;

  GetConfigUsecase(this._configRepository);

  Future<ConfigEntity> getConfig() async {
    return await _configRepository.getConfig();
  }

  /// Whether a unit preference has ever been stored, as opposed to merely
  /// defaulted. [ConfigEntity] coerces the units to metric when unset, so
  /// this reads the DBO where those three fields are still nullable.
  ///
  /// Units live in the shared app config box, not the per-profile one, so
  /// this answers "has anyone using this install already chosen?". That is
  /// what onboarding needs before applying a locale guess to a profile added
  /// years after the first one.
  ///
  /// The legacy `usesImperialUnits` flag is only conclusive when true. It
  /// defaults to false on a fresh install, so false can't tell an explicit
  /// metric choice from an untouched one. That affects one case: a pre-split
  /// install whose owner chose metric and has not touched a unit setting
  /// since. They get one locale-derived default on the next profile they
  /// add, changeable on the same screen.
  /// Whether the user has ever chosen which food databases to search.
  /// Null in the DBO means untouched; [ConfigEntity] flattens that to an
  /// empty map, which reads the same as "all enabled".
  Future<bool> hasExplicitFoodSourceToggles() async {
    final config = await _configRepository.getConfigDBO();
    final toggles = config.foodSourceToggles;
    return toggles != null && toggles.isNotEmpty;
  }

  Future<bool> hasExplicitUnitPreferences() async {
    final config = await _configRepository.getConfigDBO();
    return config.usesImperialFoodUnits != null ||
        config.usesImperialHeightUnits != null ||
        config.bodyWeightUnitIndex != null ||
        config.usesImperialUnits == true;
  }
}
