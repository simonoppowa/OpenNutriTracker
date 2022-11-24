import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

class ConfigDataSource {
  static const _configKey = "ConfigKey";

  final _log = Logger('ConfigDataSource');
  final Box<ConfigDBO> _configBox;

  ConfigDataSource(this._configBox);

  Future<void> addConfig(ConfigDBO configDBO) async {
    _log.fine('Adding new intake item to db');
    _configBox.put(_configKey, configDBO);
  }

  Future<ConfigDBO> getConfig() async {
    return _configBox.get(_configBox) ?? ConfigDBO.empty();
  }
}
