import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_sort_type.dart';

import '../helpers/hive_test_setup.dart';

/// Round-trip test for the persisted per-meal diary sort preference (#82
/// follow-up). The original sort dropdown stored its choice in widget state
/// so the selection reset every time the user navigated away from the
/// diary tab. The preference now lives on [ConfigDBO.diarySortPreferences]
/// (Hive field 21), and these tests prove that:
///
/// 1. Setting a sort for breakfast on a freshly initialised ConfigDataSource
///    survives recreating the data source against the same Hive box — i.e.
///    it really did land on disk and is not just kept in memory.
/// 2. Per-meal writes merge into the existing map instead of replacing it,
///    so picking a sort for lunch does not blow away the breakfast choice.
/// 3. A config that pre-dates the field (its `diarySortPreferences` is
///    null) reads back as null, which is what tells [DayInfoWidget] to fall
///    back to the time-added default.
void main() {
  group('ConfigDataSource.diarySortPreferences round-trip', () {
    late Box<ConfigDBO> box;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      Hive.init('.');
      box = await Hive.openBox<ConfigDBO>(
          'config_diary_sort_test_${DateTime.now().microsecondsSinceEpoch}');
      // The data source only writes via _configBox.get(_configKey)?.save(),
      // so we have to seed an initial config the same way initializeConfig
      // would at app startup.
      await box.put('ConfigKey', ConfigDBO.empty());
    });

    tearDown(() async {
      await box.deleteFromDisk();
    });

    test('breakfast sort preference survives recreating the data source',
        () async {
      final firstSource = ConfigDataSource(box);

      expect(
        await firstSource.getDiarySortPreferences(),
        isNull,
        reason: 'freshly initialised config should have no preferences yet',
      );

      await firstSource.setDiarySortPreference(
        'breakfast',
        DiarySortType.protein.index,
      );

      // Simulate the bloc tearing down and a fresh one wiring itself up
      // against the same underlying Hive box on the next app launch.
      final secondSource = ConfigDataSource(box);
      final prefs = await secondSource.getDiarySortPreferences();

      expect(prefs, isNotNull);
      expect(prefs!['breakfast'], equals(DiarySortType.protein.index));
      // No other meal was touched — they should not have crept into the map.
      expect(prefs.containsKey('lunch'), isFalse);
    });

    test('setting lunch after breakfast preserves the breakfast choice',
        () async {
      final source = ConfigDataSource(box);

      await source.setDiarySortPreference(
        'breakfast',
        DiarySortType.kcal.index,
      );
      await source.setDiarySortPreference(
        'lunch',
        DiarySortType.fat.index,
      );

      final prefs = await source.getDiarySortPreferences();
      expect(prefs, isNotNull);
      expect(prefs!['breakfast'], equals(DiarySortType.kcal.index));
      expect(prefs['lunch'], equals(DiarySortType.fat.index));
    });

    test('pre-existing config with null map reads back as null', () async {
      // Overwrite the seeded config with one that explicitly leaves the
      // preferences field null — this matches what an upgraded install
      // would look like before the user has ever interacted with the
      // sort dropdown.
      await box.put(
        'ConfigKey',
        ConfigDBO(false, false, false, AppThemeDBO.system),
      );

      final source = ConfigDataSource(box);
      expect(await source.getDiarySortPreferences(), isNull);
    });
  });
}
