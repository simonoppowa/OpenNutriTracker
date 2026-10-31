import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

void main() {
  late Box<ConfigDBO> appBox;
  late Box<ConfigDBO> firstBox;
  late Box<ConfigDBO> secondBox;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    final suffix = DateTime.now().microsecondsSinceEpoch;
    appBox = await Hive.openBox<ConfigDBO>('trends_app_$suffix');
    firstBox = await Hive.openBox<ConfigDBO>('trends_first_$suffix');
    secondBox = await Hive.openBox<ConfigDBO>('trends_second_$suffix');
  });

  tearDown(() async {
    await firstBox.deleteFromDisk();
    await secondBox.deleteFromDisk();
    await appBox.deleteFromDisk();
  });

  ConfigDataSource source(Box<ConfigDBO> box) => ConfigDataSource(
    FakeHiveDBProvider(configBox: box, appConfigBox: appBox),
  );

  test('range and visible metrics survive reopening the source', () async {
    final first = source(firstBox);
    await first.initializeConfig();
    await first.setTrendsRangeDays(45, customDays: 45);
    await first.setTrendsMetricVisibility({
      ConfigEntity.trendsCaloriesKey: true,
      ConfigEntity.trendsFatKey: false,
    });

    final readBack = await source(firstBox).getConfig();
    expect(readBack.trendsSelectedRangeDays, 45);
    expect(readBack.trendsCustomRangeDays, 45);
    expect(
      readBack.trendsMetricVisibility?[ConfigEntity.trendsFatKey],
      isFalse,
    );
    expect(
      readBack.trendsMetricVisibility?[ConfigEntity.trendsProteinKey] ?? true,
      isTrue,
    );

    await source(firstBox).setTrendsRangeDays(30);
    final preset = await source(firstBox).getConfig();
    expect(preset.trendsSelectedRangeDays, 30);
    expect(preset.trendsCustomRangeDays, 45);
  });

  test('trends settings remain in their own profile', () async {
    final first = source(firstBox);
    await first.initializeConfig();
    await first.setTrendsRangeDays(60, customDays: 60);
    await first.setTrendsMetricVisibility({ConfigEntity.trendsCarbsKey: false});

    final second = source(secondBox);
    await second.initializeConfig();
    final fresh = await second.getConfig();
    expect(ConfigEntity.fromConfigDBO(fresh).trendsSelectedRangeDays, 7);
    expect(fresh.trendsCustomRangeDays, isNull);
    expect(
      fresh.trendsMetricVisibility?[ConfigEntity.trendsCarbsKey] ?? true,
      isTrue,
    );
  });
}
