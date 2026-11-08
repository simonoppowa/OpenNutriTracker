import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// Weight log rows are keyed by the local day they were saved on, but show
/// the date stored inside them. A time-zone change can move that stored
/// date across local midnight, so the date a row shows and the key it is
/// filed under part ways (#1418). The tests below fake that shift by filing
/// a row under one day's key with the next day's date in it — the state a
/// zone change leaves behind — rather than changing the process time zone.
void main() {
  late Box<WeightLogDBO> box;
  late GetWeightLogUsecase getUsecase;
  late DeleteWeightLogUsecase deleteUsecase;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    box = await Hive.openBox<WeightLogDBO>(
      'delete_weight_log_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    final repository = WeightLogRepository(
      WeightLogDataSource(FakeHiveDBProvider(weightLogBox: box)),
    );
    getUsecase = GetWeightLogUsecase(repository);
    deleteUsecase = DeleteWeightLogUsecase(repository);
  });

  tearDown(() async {
    await box.deleteFromDisk();
  });

  Future<WeightLogEntity> shownEntry(double weightKg) async {
    final entries = await getUsecase.getAllEntries();
    return entries.singleWhere((entry) => entry.weightKg == weightKg);
  }

  group('a row whose date moved across midnight', () {
    setUp(() async {
      // Filed under 10 March, but its date now reads as 11 March.
      await box.put(
        '2026-03-10',
        WeightLogDBO(date: DateTime(2026, 3, 11), weightKg: 80.0),
      );
      // The real 11 March row, which shows the same date.
      await box.put(
        '2026-03-11',
        WeightLogDBO(date: DateTime(2026, 3, 11), weightKg: 81.0),
      );
    });

    test('is listed with the day it is filed under', () async {
      final shifted = await shownEntry(80.0);

      expect(shifted.date, DateTime(2026, 3, 11));
      expect(shifted.filedDay, DateTime(2026, 3, 10));
    });

    test('deleting it removes that row and leaves the neighbour', () async {
      await deleteUsecase.deleteEntry(await shownEntry(80.0));

      expect(box.keys, ['2026-03-11']);
      expect(box.get('2026-03-11')!.weightKg, 81.0);
    });

    test('deleting the neighbour leaves the shifted row', () async {
      await deleteUsecase.deleteEntry(await shownEntry(81.0));

      expect(box.keys, ['2026-03-10']);
      expect(box.get('2026-03-10')!.weightKg, 80.0);
    });
  });

  test('a row whose date matches its key is deleted as before', () async {
    await box.put(
      '2026-03-10',
      WeightLogDBO(date: DateTime(2026, 3, 10), weightKg: 80.0),
    );
    await box.put(
      '2026-03-12',
      WeightLogDBO(date: DateTime(2026, 3, 12), weightKg: 79.5),
    );

    await deleteUsecase.deleteEntry(await shownEntry(80.0));

    expect(box.keys, ['2026-03-12']);
  });

  test(
    'an entry that was not read from the log is deleted by its date',
    () async {
      await box.put(
        '2026-03-10',
        WeightLogDBO(date: DateTime(2026, 3, 10), weightKg: 80.0),
      );

      await deleteUsecase.deleteEntry(
        WeightLogEntity(date: DateTime(2026, 3, 10), weightKg: 80.0),
      );

      expect(box.isEmpty, isTrue);
    },
  );

  test('the day it is filed under does not make two readings unequal', () {
    final read = WeightLogEntity(
      date: DateTime(2026, 3, 11),
      weightKg: 80.0,
      filedDay: DateTime(2026, 3, 10),
    );
    final typed = WeightLogEntity(date: DateTime(2026, 3, 11), weightKg: 80.0);

    expect(read, typed);
  });
}
