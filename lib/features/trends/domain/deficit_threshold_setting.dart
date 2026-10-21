import 'package:opennutritracker/core/data/data_source/config_data_source.dart';

/// Below which share of its reference a day counts as a micronutrient
/// deficit in the trends (#59), in percent. Stored app-wide in the config
/// (field 117).
class DeficitThresholdSetting {
  static const defaultPercent = 70;
  static const choices = [50, 70, 90];

  final ConfigDataSource _config;

  DeficitThresholdSetting(this._config);

  Future<int> percent() async =>
      (await _config.getConfig()).trendsDeficitThresholdPercent ??
      defaultPercent;

  Future<void> save(int percent) async {
    final config = await _config.getConfig();
    config.trendsDeficitThresholdPercent = percent;
    await _config.addConfig(config);
  }
}
