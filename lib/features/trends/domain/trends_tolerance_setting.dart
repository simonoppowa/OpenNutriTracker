import 'package:flutter/foundation.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';

/// How far a day's energy and macros may lie off their goals and still count
/// as met in the trends statistics (#56, #57), in percent. Stored app-wide in
/// the config (field 116); [changes] fires after every save.
class TrendsToleranceSetting {
  static const defaultPercent = 10;
  static const choices = [5, 10, 15, 20];

  final ConfigDataSource _config;
  final changes = ValueNotifier<int>(0);

  TrendsToleranceSetting(this._config);

  Future<int> percent() async =>
      (await _config.getConfig()).trendsTolerancePercent ?? defaultPercent;

  Future<void> save(int percent) async {
    final config = await _config.getConfig();
    config.trendsTolerancePercent = percent;
    await _config.addConfig(config);
    changes.value++;
  }
}
