import 'package:archive/archive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/settings/data/auto_backup_settings.dart';
import 'package:opennutritracker/features/settings/data/backup_folder.dart';
import 'package:opennutritracker/features/settings/domain/auto_backup_service.dart';

import '../helpers/fake_backup_reminder.dart';

/// A picked Files-app folder in memory. [refreshTo] makes the next call hand
/// back a renewed bookmark, as iOS does for a stale one.
class _MemoryFolder implements BackupFolder {
  final files = <String, List<int>>{};
  final bookmarksSeen = <String>[];
  String? refreshTo;
  String? failWith;
  ({String bookmark, String name})? picked = (
    bookmark: 'bm-1',
    name: 'NutriTracker Backups',
  );

  String? _renewed() {
    final renewed = refreshTo;
    refreshTo = null;
    return renewed;
  }

  void _check(String bookmark) {
    bookmarksSeen.add(bookmark);
    if (failWith != null) throw BackupFolderException(failWith!);
  }

  @override
  Future<({String bookmark, String name})?> pick() async => picked;

  @override
  Future<({List<String> names, String? bookmark})> list(String bookmark) async {
    _check(bookmark);
    return (names: files.keys.toList(), bookmark: _renewed());
  }

  @override
  Future<String?> write(String bookmark, String name, List<int> bytes) async {
    _check(bookmark);
    files[name] = bytes;
    return _renewed();
  }

  @override
  Future<({List<int> bytes, String? bookmark})> read(
    String bookmark,
    String name,
  ) async {
    _check(bookmark);
    return (bytes: files[name]!, bookmark: _renewed());
  }

  @override
  Future<String?> delete(String bookmark, String name) async {
    _check(bookmark);
    files.remove(name);
    return _renewed();
  }
}

void main() {
  late _MemoryFolder folder;
  late AutoBackupSettingsStore store;
  late DateTime now;
  late AutoBackupService service;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    folder = _MemoryFolder();
    store = AutoBackupSettingsStore(const FlutterSecureStorage());
    now = DateTime(2026, 10, 21, 9, 30);
    service = AutoBackupService(
      store,
      () async =>
          Archive()
            ..addFile(ArchiveFile.bytes('user_intake.json', '[]'.codeUnits)),
      FakeBackupReminder(),
      folder: folder,
      clock: () => now,
    );
  });

  test('choosing a folder switches the backup to it', () async {
    expect(await service.chooseFolder(), 'NutriTracker Backups');

    final settings = await store.load();
    expect(settings.target, AutoBackupTarget.folder);
    expect(settings.folderBookmark, 'bm-1');
    expect(settings.folderName, 'NutriTracker Backups');
    expect(settings.isConfigured, isTrue);
  });

  test('a cancelled choice changes nothing', () async {
    folder.picked = null;

    expect(await service.chooseFolder(), isNull);
    expect((await store.load()).target, AutoBackupTarget.server);
  });

  test('the folder target without a folder reports a folder error', () async {
    await store.save(const AutoBackupSettings(target: AutoBackupTarget.folder));

    await expectLater(
      service.listBackups(),
      throwsA(
        isA<BackupFolderException>().having((e) => e.code, 'code', 'not_found'),
      ),
    );
  });

  group('with a folder', () {
    setUp(() async {
      await service.chooseFolder();
      await store.save(
        (await store.load()).copyWith(enabled: true, keepCount: 2),
      );
    });

    test('uploads into the folder and keeps the newest', () async {
      folder.files['notes.txt'] = [1];
      for (final hour in [9, 10, 11]) {
        now = DateTime(2026, 10, 21, hour);
        expect(await service.runNow(), AutoBackupOutcome.uploaded);
      }

      expect(folder.files.keys.toSet(), {
        'notes.txt',
        'nutritracker-backup-20261021-100000.zip',
        'nutritracker-backup-20261021-110000.zip',
      });
      expect((await store.load()).lastSuccessAt, now);
    });

    test('lists and restores from the folder', () async {
      await service.runNow();

      final names = await service.listBackups();
      final archive = await service.download(names.single);

      expect(names, ['nutritracker-backup-20261021-093000.zip']);
      expect(archive.findFile('user_intake.json'), isNotNull);
    });

    test('a renewed bookmark is kept for the next time', () async {
      folder.refreshTo = 'bm-2';

      await service.runNow();
      await service.listBackups();

      expect((await store.load()).folderBookmark, 'bm-2');
      expect(folder.bookmarksSeen.last, 'bm-2');
    });

    test('a folder that cannot be reached is stored as such', () async {
      folder.failWith = 'access_denied';

      expect(await service.runNow(), AutoBackupOutcome.failed);
      expect((await store.load()).lastError, 'folder access_denied');
    });

    test('the test lists the folder', () async {
      await service.testConnection(await store.load());

      expect(folder.bookmarksSeen, ['bm-1']);
    });
  });

  test('the folder settings survive a round trip', () {
    const settings = AutoBackupSettings(
      target: AutoBackupTarget.folder,
      folderBookmark: 'bm',
      folderName: 'Backups',
    );

    final restored = AutoBackupSettings.fromJson(settings.toJson());

    expect(restored.target, AutoBackupTarget.folder);
    expect(restored.folderBookmark, 'bm');
    expect(restored.folderName, 'Backups');
    expect(
      AutoBackupSettings.fromJson(const {}).target,
      AutoBackupTarget.server,
    );
  });
}
