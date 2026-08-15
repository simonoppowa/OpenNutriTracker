import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

ConfigDBO _dbo({
  bool? healthImportEnabled,
  double? healthWorkoutKcalMultiplier,
  DateTime? healthLastImportAt,
}) => ConfigDBO(
  false,
  false,
  false,
  AppThemeDBO.system,
  healthImportEnabled: healthImportEnabled,
  healthWorkoutKcalMultiplier: healthWorkoutKcalMultiplier,
  healthLastImportAt: healthLastImportAt,
);

void main() {
  group('ConfigEntity health import defaults', () {
    test('a config written before the feature existed reads as opted out', () {
      final config = ConfigEntity.fromConfigDBO(ConfigDBO.empty());

      expect(config.healthImportEnabled, isFalse);
      expect(config.healthWorkoutKcalMultiplier, isNull);
      expect(config.healthLastImportAt, isNull);
    });

    test('no stored multiplier credits every reported calorie', () {
      final config = ConfigEntity.fromConfigDBO(_dbo());

      expect(config.effectiveHealthWorkoutKcalMultiplier, equals(1.0));
    });

    test('a stored multiplier is used verbatim', () {
      final config = ConfigEntity.fromConfigDBO(
        _dbo(healthWorkoutKcalMultiplier: 0.7),
      );

      expect(config.healthWorkoutKcalMultiplier, equals(0.7));
      expect(config.effectiveHealthWorkoutKcalMultiplier, equals(0.7));
    });

    test('both range bounds are accepted', () {
      final floor = ConfigEntity.fromConfigDBO(
        _dbo(
          healthWorkoutKcalMultiplier:
              ConfigEntity.minHealthWorkoutKcalMultiplier,
        ),
      );
      final ceiling = ConfigEntity.fromConfigDBO(
        _dbo(
          healthWorkoutKcalMultiplier:
              ConfigEntity.maxHealthWorkoutKcalMultiplier,
        ),
      );

      expect(floor.effectiveHealthWorkoutKcalMultiplier, equals(0.5));
      expect(ceiling.effectiveHealthWorkoutKcalMultiplier, equals(1.0));
    });

    test(
      'a multiplier outside the supported range is dropped, not scaled by',
      () {
        final tooLow = ConfigEntity.fromConfigDBO(
          _dbo(healthWorkoutKcalMultiplier: 0.1),
        );
        final tooHigh = ConfigEntity.fromConfigDBO(
          _dbo(healthWorkoutKcalMultiplier: 4.2),
        );

        expect(tooLow.healthWorkoutKcalMultiplier, isNull);
        expect(tooLow.effectiveHealthWorkoutKcalMultiplier, equals(1.0));
        expect(tooHigh.healthWorkoutKcalMultiplier, isNull);
        expect(tooHigh.effectiveHealthWorkoutKcalMultiplier, equals(1.0));
      },
    );

    test('the opt-in flag and the watermark round-trip', () {
      final watermark = DateTime.utc(2026, 5, 23, 14, 30);
      final config = ConfigEntity.fromConfigDBO(
        _dbo(healthImportEnabled: true, healthLastImportAt: watermark),
      );

      expect(config.healthImportEnabled, isTrue);
      expect(config.healthLastImportAt, equals(watermark));
    });
  });

  group('ConfigDataSource health settings ownership', () {
    // The activity box the importer writes into is per-profile, so the
    // settings driving it have to be too: one profile opting in must not
    // switch the import on for the next one, and each profile's watermark
    // has to track the workouts *it* imported.
    late Box<ConfigDBO> appBox;
    late Box<ConfigDBO> profileABox;
    late Box<ConfigDBO> profileBBox;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      Hive.init('.');
      appBox = await Hive.openBox<ConfigDBO>('health_owner_app_test');
      profileABox = await Hive.openBox<ConfigDBO>('health_owner_a_test');
      profileBBox = await Hive.openBox<ConfigDBO>('health_owner_b_test');
      await appBox.clear();
      await profileABox.clear();
      await profileBBox.clear();
    });

    tearDown(() async {
      await Hive.close();
      await Hive.deleteFromDisk();
    });

    ConfigDataSource sourceFor(Box<ConfigDBO> profileBox) => ConfigDataSource(
      FakeHiveDBProvider(configBox: profileBox, appConfigBox: appBox),
    );

    test('a second profile does not inherit the first one\'s opt-in', () async {
      final profileA = sourceFor(profileABox);
      await profileA.initializeConfig();
      await profileA.setConfigHealthImportEnabled(true);
      await profileA.setConfigHealthWorkoutKcalMultiplier(0.7);
      await profileA.setConfigHealthLastImportAt(DateTime(2026, 5, 23, 12));

      final profileB = sourceFor(profileBBox);
      await profileB.initializeConfig();
      final config = await profileB.getConfig();

      expect(config.healthImportEnabled, isNull);
      expect(config.healthWorkoutKcalMultiplier, isNull);
      expect(config.healthLastImportAt, isNull);
    });

    test('each profile keeps its own settings and watermark', () async {
      final profileA = sourceFor(profileABox);
      await profileA.initializeConfig();
      await profileA.setConfigHealthImportEnabled(true);
      await profileA.setConfigHealthWorkoutKcalMultiplier(0.7);
      await profileA.setConfigHealthLastImportAt(DateTime(2026, 5, 23, 12));

      final profileB = sourceFor(profileBBox);
      await profileB.initializeConfig();
      await profileB.setConfigHealthImportEnabled(true);
      await profileB.setConfigHealthWorkoutKcalMultiplier(0.9);
      await profileB.setConfigHealthLastImportAt(DateTime(2026, 5, 24, 9));

      final configA = await profileA.getConfig();
      expect(configA.healthWorkoutKcalMultiplier, equals(0.7));
      expect(configA.healthLastImportAt, equals(DateTime(2026, 5, 23, 12)));

      final configB = await profileB.getConfig();
      expect(configB.healthWorkoutKcalMultiplier, equals(0.9));
      expect(configB.healthLastImportAt, equals(DateTime(2026, 5, 24, 9)));
    });

    test('a shared preference still comes from the app box', () async {
      // The split has to stay a split: theme is device-wide, so a profile
      // that never touched it reads what the other profile chose.
      final profileA = sourceFor(profileABox);
      await profileA.initializeConfig();
      await profileA.setConfigAppTheme(AppThemeDBO.dark);

      final profileB = sourceFor(profileBBox);
      await profileB.initializeConfig();

      expect(await profileB.getAppTheme(), equals(AppThemeDBO.dark));
    });

    test(
      'a profile with no config box of its own reads as opted out',
      () async {
        final profileA = sourceFor(profileABox);
        await profileA.initializeConfig();
        await profileA.setConfigHealthImportEnabled(true);

        // No initializeConfig: the box is empty, as it is mid-switch or after
        // a profile reset. The app box's copy must not leak in.
        final config = await sourceFor(profileBBox).getConfig();

        expect(config.healthImportEnabled, isNull);
      },
    );
  });
}
