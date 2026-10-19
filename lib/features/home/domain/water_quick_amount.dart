import 'package:flutter/foundation.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';

/// The user's own amount for the third water quick-add button (#29), next
/// to the fixed +250 ml and +500 ml.
class WaterQuickAmount {
  static const defaultMl = 330;
  static const minMl = 50;
  static const maxMl = 2000;

  final ConfigDataSource _config;

  /// The current amount, for the buttons and the settings tile; follows
  /// [load] and [save].
  final ValueNotifier<int> amount = ValueNotifier(defaultMl);

  WaterQuickAmount(this._config);

  Future<int> load() async {
    final stored = (await _config.getConfig()).waterQuickAmountMl;
    return amount.value = stored ?? defaultMl;
  }

  Future<void> save(int amountMl) async {
    final clamped = amountMl.clamp(minMl, maxMl);
    final config = await _config.getConfig();
    config.waterQuickAmountMl = clamped;
    await _config.addConfig(config);
    amount.value = clamped;
  }
}
