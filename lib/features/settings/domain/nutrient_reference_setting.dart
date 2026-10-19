import 'package:flutter/foundation.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';

/// Which reference values the daily nutrient panel measures against (#49).
enum NutrientReferenceStandard { iom, dge }

/// The reference standard of the nutrient panel: IOM unless the user picks
/// DGE. Stored app-wide in the config (field 115). [changes] fires after
/// every save so an open panel picks the new values up right away.
class NutrientReferenceSetting {
  static const defaultStandard = NutrientReferenceStandard.iom;

  final ConfigDataSource _config;
  final changes = ValueNotifier<int>(0);

  NutrientReferenceSetting(this._config);

  Future<NutrientReferenceStandard> standard() async {
    final stored = (await _config.getConfig()).nutrientReferenceStandard;
    return NutrientReferenceStandard.values.asNameMap()[stored] ??
        defaultStandard;
  }

  Future<void> save(NutrientReferenceStandard standard) async {
    final config = await _config.getConfig();
    config.nutrientReferenceStandard = standard.name;
    await _config.addConfig(config);
    changes.value++;
  }
}
