import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// `isDemoData` says whether the *active profile* holds sample data
/// (`docs/demo-data.md`), so it has to live in the per-profile config box.
/// It used to be read from the shared app box: onboarding a second profile
/// cleared it for every profile, and the seeded profile lost its demo-mode
/// banner for good.
void main() {
  group('ConfigDataSource isDemoData is per profile', () {
    late Box<ConfigDBO> appBox;
    late Box<ConfigDBO> demoProfileBox;
    late Box<ConfigDBO> realProfileBox;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      Hive.init('.');
      appBox = await Hive.openBox<ConfigDBO>('demo_flag_app_test');
      demoProfileBox = await Hive.openBox<ConfigDBO>('demo_flag_demo_test');
      realProfileBox = await Hive.openBox<ConfigDBO>('demo_flag_real_test');
      await appBox.clear();
      await demoProfileBox.clear();
      await realProfileBox.clear();
    });

    tearDown(() async {
      await Hive.close();
      await Hive.deleteFromDisk();
    });

    ConfigDataSource sourceFor(Box<ConfigDBO> profileBox) => ConfigDataSource(
      FakeHiveDBProvider(configBox: profileBox, appConfigBox: appBox),
    );

    test(
      'onboarding a second profile keeps the seeded profile in demo mode',
      () async {
        final demo = sourceFor(demoProfileBox);
        await demo.initializeConfig();
        await demo.setIsDemoData(true);

        // The new profile finishes real onboarding, which clears the flag.
        final real = sourceFor(realProfileBox);
        await real.initializeConfig();
        await real.setConfigAppTheme(AppThemeDBO.dark);
        await real.setIsDemoData(false);

        expect((await demo.getConfig()).isDemoData, isTrue);
        expect((await real.getConfig()).isDemoData, isFalse);
      },
    );

    test('a new profile does not inherit the demo flag', () async {
      final demo = sourceFor(demoProfileBox);
      await demo.initializeConfig();
      await demo.setIsDemoData(true);

      final real = sourceFor(realProfileBox);
      await real.initializeConfig();

      expect((await real.getConfig()).isDemoData, isNot(isTrue));
    });

    test('writes on the other profile do not copy the flag across', () async {
      final demo = sourceFor(demoProfileBox);
      await demo.initializeConfig();
      await demo.setIsDemoData(true);

      // A shared-field write from the real profile rewrites the app box and
      // its own profile box; neither may flip the real profile into demo
      // mode or the demo profile out of it.
      final real = sourceFor(realProfileBox);
      await real.initializeConfig();
      await real.setConfigAppTheme(AppThemeDBO.light);
      await demo.setConfigAppTheme(AppThemeDBO.dark);

      expect((await real.getConfig()).isDemoData, isNot(isTrue));
      expect((await demo.getConfig()).isDemoData, isTrue);
    });

    test('a wiped profile box reads as real data even if the app box has '
        'a stale true', () async {
      // Older builds stored the flag in the app box; a cleared profile
      // (DeleteAllUserDataUsecase clears only the profile's ConfigBox) must
      // not pick it up from there.
      await appBox.put('ConfigKey', ConfigDBO.empty()..isDemoData = true);
      final demo = sourceFor(demoProfileBox);

      expect((await demo.getConfig()).isDemoData, isNot(isTrue));
    });
  });
}
