import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/scanner/util/barcode_check_digit.dart';

/// Decides when a barcode scan asks "is this your product?" (#83): for an
/// Open Food Facts product on a store-internal code
/// ([isStoreInternalBarcode]) the user has not confirmed yet. Confirmed
/// codes are kept in the config, which the backup carries.
class StoreBarcodeCheck {
  final ConfigDataSource _config;

  StoreBarcodeCheck(this._config);

  Future<bool> needsConfirmation(MealEntity product) async {
    final code = product.code;
    if (product.source != MealSourceEntity.off ||
        code == null ||
        !isStoreInternalBarcode(code)) {
      return false;
    }
    final confirmed = (await _config.getConfig()).confirmedStoreBarcodes;
    return !(confirmed ?? const []).contains(code);
  }

  /// Remembers that [code] is the product Open Food Facts returned.
  Future<void> confirm(String code) async {
    final config = await _config.getConfig();
    final confirmed = config.confirmedStoreBarcodes ?? const [];
    if (confirmed.contains(code)) return;
    config.confirmedStoreBarcodes = [...confirmed, code];
    await _config.addConfig(config);
  }
}
