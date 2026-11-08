import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

import '../helpers/hive_test_setup.dart';

/// A provider caught mid profile switch: the shared app box is open, and
/// the per-profile box throws, as `HiveDBProvider._requireBox` does then.
class _SwitchingProvider extends Fake implements HiveDBProvider {
  @override
  final Box<ConfigDBO> appConfigBox;

  _SwitchingProvider(this.appConfigBox);

  @override
  Box<ConfigDBO> get configBox =>
      throw StateError('Tried to read "ConfigBox" during a profile switch.');
}

void main() {
  late Box<ConfigDBO> appBox;
  late ConfigDataSource configs;

  setUp(() async {
    Hive.init('.');
    registerHiveAdaptersOnce();
    final tag = DateTime.now().microsecondsSinceEpoch;
    appBox = await Hive.openBox<ConfigDBO>('tip_flag_app_config_$tag');
    configs = ConfigDataSource(_SwitchingProvider(appBox));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('a tip is recorded even while a profile switch has the profile box '
      'closed (#1536)', () async {
    await appBox.put('ConfigKey', ConfigDBO.empty()..selectedLocale = 'de');

    await configs.setHasLeftTip();

    expect(await configs.getHasLeftTip(), isTrue);
    // The rest of the shared config is kept.
    expect(appBox.get('ConfigKey')!.selectedLocale, 'de');
  });

  test('a first write on an empty app box creates the config', () async {
    await configs.setHasLeftTip();

    expect(appBox.get('ConfigKey')!.hasLeftTip, isTrue);
  });

  test('clearing works without the profile box too', () async {
    await configs.setHasLeftTip();

    await configs.clearHasLeftTip();

    expect(await configs.getHasLeftTip(), isFalse);
  });
}
