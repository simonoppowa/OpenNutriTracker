import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

class ConfigDataSource {
  static const _configKey = "ConfigKey";

  final _log = Logger('ConfigDataSource');
  final Box<ConfigDBO> _configBox;

  ConfigDataSource(this._configBox);

  Future<bool> configInitialized() async => _configBox.containsKey(_configKey);

  Future<void> initializeConfig() async =>
      _configBox.put(_configKey, ConfigDBO.empty());

  Future<void> addConfig(ConfigDBO configDBO) async {
    _log.fine('Adding new config item to db');
    _configBox.put(_configKey, configDBO);
  }

  Future<void> setConfigDisclaimer(bool hasAcceptedDisclaimer) async {
    _log.fine(
        'Updating config hasAcceptedDisclaimer to $hasAcceptedDisclaimer');
    final config = _configBox.get(_configKey);
    config?.hasAcceptedDisclaimer = hasAcceptedDisclaimer;
    config?.save();
  }

  Future<void> setConfigAcceptedAnonymousData(
      bool hasAcceptedAnonymousData) async {
    _log.fine(
        'Updating config hasAcceptedAnonymousData to $hasAcceptedAnonymousData');
    final config = _configBox.get(_configKey);
    config?.hasAcceptedSendAnonymousData = hasAcceptedAnonymousData;
    config?.save();
  }

  Future<AppThemeDBO> getAppTheme() async {
    final config = _configBox.get(_configKey);
    return config?.selectedAppTheme ?? AppThemeDBO.defaultTheme;
  }

  Future<void> setConfigAppTheme(AppThemeDBO appTheme) async {
    _log.fine('Updating config appTheme to $appTheme');
    final config = _configBox.get(_configKey);
    config?.selectedAppTheme = appTheme;
    config?.save();
  }

  Future<ConfigDBO> getConfig() async {
    return _configBox.get(_configKey) ?? ConfigDBO.empty();
  }

  Future<bool> getHasAcceptedAnonymousData() async {
    final config = _configBox.get(_configKey);
    return config?.hasAcceptedSendAnonymousData ?? false;
  }
}
