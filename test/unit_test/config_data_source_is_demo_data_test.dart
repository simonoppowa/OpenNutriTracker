import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// `isDemoData` must be profile-scoped. If it were read from appConfigBox only,
/// leaving demo mode (which clears the profile config box) or switching
/// profiles would leave the Home demo banner stuck on every profile.
void main() {
  group('ConfigDataSource.isDemoData profile overlay', () {
    late Box<ConfigDBO> appBox;
    late Box<ConfigDBO> profileBox;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      Hive.init('.');
      final stamp = DateTime.now().microsecondsSinceEpoch;
      appBox = await Hive.openBox<ConfigDBO>('config_is_demo_app_$stamp');
      profileBox = await Hive.openBox<ConfigDBO>(
        'config_is_demo_profile_$stamp',
      );
      await appBox.put('ConfigKey', ConfigDBO.empty());
      await profileBox.put('ConfigKey', ConfigDBO.empty());
    });

    tearDown(() async {
      await appBox.deleteFromDisk();
      await profileBox.deleteFromDisk();
    });

    ConfigDataSource source() => ConfigDataSource(
      FakeHiveDBProvider(configBox: profileBox, appConfigBox: appBox),
    );

    test(
      'setIsDemoData(true) is visible via getConfig/Entity mapping',
      () async {
        final ds = source();
        await ds.setIsDemoData(true);

        final dbo = await ds.getConfig();
        expect(dbo.isDemoData, isTrue);
        expect(ConfigEntity.fromConfigDBO(dbo).isDemoData, isTrue);
        expect(profileBox.get('ConfigKey')?.isDemoData, isTrue);
      },
    );

    test(
      'stale app-box isDemoData is ignored when profile box is false',
      () async {
        // Simulate the pre-fix dual-write leaving true only on appConfigBox,
        // while the profile config (cleared / reset) has no demo flag.
        await appBox.put(
          'ConfigKey',
          ConfigDBO(false, false, false, AppThemeDBO.system, isDemoData: true),
        );
        await profileBox.put(
          'ConfigKey',
          ConfigDBO(false, false, false, AppThemeDBO.system, isDemoData: false),
        );

        final dbo = await source().getConfig();
        expect(dbo.isDemoData, isFalse);
        expect(ConfigEntity.fromConfigDBO(dbo).isDemoData, isFalse);
      },
    );

    test('cleared profile box does not leak isDemoData from app box', () async {
      await appBox.put(
        'ConfigKey',
        ConfigDBO(false, false, false, AppThemeDBO.system, isDemoData: true),
      );
      await profileBox.clear();

      final dbo = await source().getConfig();
      expect(dbo.isDemoData, isNull);
      expect(ConfigEntity.fromConfigDBO(dbo).isDemoData, isFalse);
    });
  });
}
