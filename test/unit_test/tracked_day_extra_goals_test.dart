import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

void main() {
  late Box<TrackedDayDBO> box;
  late TrackedDayDataSource dataSource;
  final day = DateTime.utc(2026, 10, 19);

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    box = await Hive.openBox<TrackedDayDBO>('tracked_day_extra_goals_test');
    dataSource = TrackedDayDataSource(FakeHiveDBProvider(trackedDayBox: box));
    await dataSource.saveTrackedDay(
      TrackedDayDBO(day: day, calorieGoal: 2000, caloriesTracked: 0),
    );
  });

  tearDown(() async {
    await box.clear();
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test('extra nutrient goals are stored and read back from disk', () async {
    await dataSource.updateDayExtraNutrientGoals(day, {
      'zinc': 12,
      'vitamin_c': 100,
    });
    await box.close();
    box = await Hive.openBox<TrackedDayDBO>('tracked_day_extra_goals_test');
    dataSource = TrackedDayDataSource(FakeHiveDBProvider(trackedDayBox: box));

    final stored = await dataSource.getTrackedDay(day);

    expect(stored!.extraNutrientGoals, {'zinc': 12.0, 'vitamin_c': 100.0});
    expect(stored.calorieGoal, 2000);
  });

  test('saving replaces the goals, an empty map clears them', () async {
    await dataSource.updateDayExtraNutrientGoals(day, {'zinc': 12});
    await dataSource.updateDayExtraNutrientGoals(day, {'niacin': 18});

    expect((await dataSource.getTrackedDay(day))!.extraNutrientGoals, {
      'niacin': 18.0,
    });

    await dataSource.updateDayExtraNutrientGoals(day, {});

    expect((await dataSource.getTrackedDay(day))!.extraNutrientGoals, isNull);
  });

  test('a day without a row stays without one', () async {
    final other = DateTime.utc(2026, 10, 20);

    await dataSource.updateDayExtraNutrientGoals(other, {'zinc': 12});

    expect(await dataSource.getTrackedDay(other), isNull);
  });
}
