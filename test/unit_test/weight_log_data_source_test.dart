import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  group('WeightLogDataSource', () {
    late Box<WeightLogDBO> box;
    late WeightLogDataSource dataSource;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      Hive.init('.');
      box = await Hive.openBox<WeightLogDBO>(
        'weight_log_test_${DateTime.now().microsecondsSinceEpoch}',
      );
      dataSource = WeightLogDataSource(box);
    });

    tearDown(() async {
      await box.deleteFromDisk();
    });

    test('write then read returns the same entry', () async {
      final day = DateTime.utc(2025, 3, 12);

      await dataSource.addEntry(
        WeightLogDBO(date: day, weightKg: 71.4, note: 'morning'),
      );

      final entry = await dataSource.getEntry(day);
      expect(entry, isNotNull);
      expect(entry!.weightKg, equals(71.4));
      expect(entry.note, equals('morning'));
    });

    test('saving twice for the same day overwrites the previous reading',
        () async {
      final day = DateTime.utc(2025, 3, 12);

      await dataSource.addEntry(WeightLogDBO(date: day, weightKg: 71.4));
      await dataSource.addEntry(WeightLogDBO(date: day, weightKg: 71.0));

      final all = await dataSource.allEntries();
      expect(all.length, equals(1));
      expect(all.first.weightKg, equals(71.0));
    });

    test('entriesInRange returns only entries inside the bounds, inclusive',
        () async {
      await dataSource.addAllEntries([
        WeightLogDBO(date: DateTime.utc(2025, 3, 10), weightKg: 72.0),
        WeightLogDBO(date: DateTime.utc(2025, 3, 12), weightKg: 71.4),
        WeightLogDBO(date: DateTime.utc(2025, 3, 14), weightKg: 71.1),
        WeightLogDBO(date: DateTime.utc(2025, 3, 20), weightKg: 70.5),
      ]);

      final result = await dataSource.entriesInRange(
        DateTime.utc(2025, 3, 12),
        DateTime.utc(2025, 3, 14),
      );

      expect(result.length, equals(2));
      final dates = result.map((e) => e.date).toList();
      expect(dates, containsAll([
        DateTime.utc(2025, 3, 12),
        DateTime.utc(2025, 3, 14),
      ]));
    });

    test('deleteEntry removes the entry for that day only', () async {
      final keep = DateTime.utc(2025, 3, 10);
      final drop = DateTime.utc(2025, 3, 12);

      await dataSource.addEntry(WeightLogDBO(date: keep, weightKg: 72.0));
      await dataSource.addEntry(WeightLogDBO(date: drop, weightKg: 71.4));

      await dataSource.deleteEntry(drop);

      final all = await dataSource.allEntries();
      expect(all.length, equals(1));
      expect(all.first.date, equals(keep));
    });

    test('allEntries returns every saved entry', () async {
      await dataSource.addEntry(
        WeightLogDBO(date: DateTime.utc(2025, 1, 1), weightKg: 73.0),
      );
      await dataSource.addEntry(
        WeightLogDBO(date: DateTime.utc(2025, 2, 1), weightKg: 72.5),
      );

      final all = await dataSource.allEntries();
      expect(all.length, equals(2));
    });
  });
}
