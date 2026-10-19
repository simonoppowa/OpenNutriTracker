import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/water_intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/personal_backup_extras.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

void main() {
  late Directory hiveDir;
  late Box<WaterIntakeDBO> waterBox;
  late PersonalBackupExtras extras;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveDir = await Directory.systemTemp.createTemp('backup_extras_test');
    Hive.init(hiveDir.path);
    registerHiveAdaptersOnce();
    waterBox = await Hive.openBox<WaterIntakeDBO>('water_test');
    extras = PersonalBackupExtras(
      WaterIntakeRepository(
        WaterIntakeDataSource(FakeHiveDBProvider(waterIntakeBox: waterBox)),
      ),
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  WaterIntakeDBO water(String id, int ml, DateTime at) =>
      WaterIntakeDBO(id: id, dateTime: at, amountMl: ml);

  Future<Archive> exportArchive() async {
    final archive = Archive();
    await extras.addTo(archive);
    return ZipDecoder().decodeBytes(ZipEncoder().encode(archive));
  }

  group('water intake', () {
    test('is written as water_intake.json', () async {
      await waterBox.putAll({
        'w1': water('w1', 250, DateTime(2026, 10, 1, 8)),
        'w2': water('w2', 500, DateTime(2026, 10, 1, 12, 30)),
      });

      final archive = await exportArchive();
      final file = archive.findFile(PersonalBackupExtras.waterIntakeFileName);

      expect(file, isNotNull);
      final rows = jsonDecode(utf8.decode(file!.content as List<int>)) as List;
      expect(rows.map((row) => row['id']), unorderedEquals(['w1', 'w2']));
    });

    test('a restore brings every entry back', () async {
      await waterBox.putAll({
        'w1': water('w1', 250, DateTime(2026, 10, 1, 8)),
        'w2': water('w2', 500, DateTime(2026, 10, 2, 9)),
      });
      final archive = await exportArchive();
      await waterBox.clear();

      final restore = extras.prepareRestore(archive);
      await restore();

      final restored = {for (final entry in waterBox.values) entry.id: entry};
      expect(restored.keys, unorderedEquals(['w1', 'w2']));
      expect(restored['w1']!.amountMl, 250);
      expect(restored['w2']!.dateTime, DateTime(2026, 10, 2, 9));
    });

    test('restoring the same backup twice adds nothing', () async {
      await waterBox.put('w1', water('w1', 250, DateTime(2026, 10, 1, 8)));
      final archive = await exportArchive();

      await extras.prepareRestore(archive)();
      await extras.prepareRestore(archive)();

      expect(waterBox.length, 1);
    });

    test('a backup without the file leaves the entries alone', () async {
      await waterBox.put('w1', water('w1', 250, DateTime(2026, 10, 1, 8)));

      await extras.prepareRestore(Archive())();

      expect(waterBox.length, 1);
    });

    test('a malformed file is rejected before anything is written', () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            PersonalBackupExtras.waterIntakeFileName,
            utf8.encode('{"not": "a list"}'),
          ),
        );

      expect(
        () => extras.prepareRestore(archive),
        throwsA(
          isA<ExportImportFailure>().having(
            (failure) => failure.reason,
            'reason',
            ExportImportFailureReason.unreadableOrWrongFormat,
          ),
        ),
      );
      expect(waterBox.isEmpty, isTrue);
    });
  });
}
