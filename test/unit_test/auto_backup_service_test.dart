import 'dart:async';

import 'package:archive/archive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/settings/data/auto_backup_settings.dart';
import 'package:opennutritracker/features/settings/domain/auto_backup_service.dart';

import '../helpers/fake_backup_reminder.dart';

/// A WebDAV folder in memory, answering the calls `WebDavClient` makes.
class _FakeServer {
  final files = <String, List<int>>{};
  bool folderExists = true;
  int? failWith;
  final methods = <String>[];
  Future<void> Function()? onPut;

  http.Client client() => MockClient((request) async {
    methods.add(request.method);
    if (failWith != null) return http.Response('', failWith!);
    final name = Uri.decodeComponent(request.url.pathSegments.last);
    switch (request.method) {
      case 'PROPFIND':
        if (!folderExists) return http.Response('', 404);
        final hrefs = [
          '<d:href>/dav/nutri/</d:href>',
          for (final file in files.keys) '<d:href>/dav/nutri/$file</d:href>',
        ];
        return http.Response(
          '<d:multistatus xmlns:d="DAV:">'
          '${hrefs.map((h) => '<d:response>$h</d:response>').join()}'
          '</d:multistatus>',
          207,
        );
      case 'MKCOL':
        folderExists = true;
        return http.Response('', 201);
      case 'PUT':
        await onPut?.call();
        files[name] = request.bodyBytes;
        return http.Response('', 201);
      case 'GET':
        final bytes = files[name];
        return bytes == null
            ? http.Response('', 404)
            : http.Response.bytes(bytes, 200);
      case 'DELETE':
        files.remove(name);
        return http.Response('', 204);
    }
    return http.Response('', 405);
  });
}

void main() {
  late _FakeServer server;
  late AutoBackupSettingsStore store;
  late FakeBackupReminder reminder;
  late DateTime now;
  late AutoBackupService service;

  Archive bundle() =>
      Archive()..addFile(ArchiveFile.bytes('user_intake.json', '[]'.codeUnits));

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    server = _FakeServer();
    store = AutoBackupSettingsStore(const FlutterSecureStorage());
    reminder = FakeBackupReminder();
    now = DateTime(2026, 10, 19, 9, 30);
    service = AutoBackupService(
      store,
      () async => bundle(),
      reminder,
      httpClient: server.client,
      clock: () => now,
    );
    await store.save(
      const AutoBackupSettings(
        enabled: true,
        folderUrl: 'https://files.example.org/dav/nutri/',
        token: 'token',
      ),
    );
  });

  test('does nothing while switched off', () async {
    await store.save((await store.load()).copyWith(enabled: false));

    expect(await service.runIfDue(), AutoBackupOutcome.disabled);
    expect(server.methods, isEmpty);
  });

  test('uploads a dated zip and remembers the success', () async {
    expect(await service.runIfDue(), AutoBackupOutcome.uploaded);

    expect(server.files.keys, ['nutritracker-backup-20261019-093000.zip']);
    final settings = await store.load();
    expect(settings.lastSuccessAt, now);
    expect(settings.lastError, isNull);
    expect(reminder.backedUp, 1);
  });

  test('waits for the interval after a success', () async {
    await service.runIfDue();
    now = now.add(const Duration(hours: 23));

    expect(await service.runIfDue(), AutoBackupOutcome.notDue);

    now = now.add(const Duration(hours: 1));
    expect(await service.runIfDue(), AutoBackupOutcome.uploaded);
    expect(server.files, hasLength(2));
  });

  test('creates the folder when it does not exist yet', () async {
    server.folderExists = false;

    expect(await service.runNow(), AutoBackupOutcome.uploaded);
    expect(server.methods, contains('MKCOL'));
  });

  test('keeps the newest backups and leaves other files alone', () async {
    await store.save((await store.load()).copyWith(keepCount: 2));
    server.files['notes.txt'] = [1];
    for (final day in [15, 16, 17]) {
      server.files['nutritracker-backup-202610$day-080000.zip'] = [1];
    }

    await service.runNow();

    expect(
      server.files.keys,
      unorderedEquals([
        'notes.txt',
        'nutritracker-backup-20261017-080000.zip',
        'nutritracker-backup-20261019-093000.zip',
      ]),
    );
  });

  test(
    'a failure is stored, not thrown, and the next start tries again',
    () async {
      server.failWith = 401;

      expect(await service.runIfDue(), AutoBackupOutcome.failed);
      final failed = await store.load();
      expect(failed.lastError, 'unauthorized');
      expect(failed.lastErrorAt, now);
      expect(failed.lastSuccessAt, isNull);
      expect(reminder.backedUp, 0);

      server.failWith = null;
      expect(await service.runIfDue(), AutoBackupOutcome.uploaded);
      expect((await store.load()).lastError, isNull);
    },
  );

  test('the error text never carries the token', () async {
    server.failWith = 500;

    await service.runNow();

    expect((await store.load()).lastError, isNot(contains('token')));
  });

  test('a password encrypts the uploaded zip', () async {
    await store.save((await store.load()).copyWith(password: 'geheim'));

    await service.runNow();

    final bytes = server.files.values.single;
    expect(
      ZipDecoder()
          .decodeBytes(bytes, password: 'geheim')
          .findFile('user_intake.json'),
      isNotNull,
    );
    expect(
      () => ZipDecoder().decodeBytes(bytes).single.content,
      throwsA(anything),
    );
  });

  test('lists the backups newest first and downloads one', () async {
    await store.save((await store.load()).copyWith(password: 'geheim'));
    await service.runNow();
    now = now.add(const Duration(days: 1));
    await service.runNow();
    server.files['notes.txt'] = [1];

    final names = await service.listBackups();
    expect(names, [
      'nutritracker-backup-20261020-093000.zip',
      'nutritracker-backup-20261019-093000.zip',
    ]);
    final archive = await service.download(names.first);
    expect(archive.findFile('user_intake.json'), isNotNull);
  });

  test('two calls at once upload once', () async {
    final results = await Future.wait([service.runNow(), service.runNow()]);

    expect(results, everyElement(AutoBackupOutcome.uploaded));
    expect(server.methods.where((m) => m == 'PUT'), hasLength(1));
  });

  test('the settings keep their secrets in secure storage', () async {
    final stored = await const FlutterSecureStorage().readAll();

    expect(stored.keys, ['AutoBackupSettings']);
    expect(stored.values.single, contains('token'));
  });

  test('a settings change made during an upload survives it', () async {
    server.onPut = () async =>
        store.save((await store.load()).copyWith(enabled: false, keepCount: 3));

    await service.runNow();

    final after = await store.load();
    expect(after.enabled, isFalse);
    expect(after.keepCount, 3);
    expect(after.lastSuccessAt, now);
  });

  test('a stalled server is stored as unreachable', () async {
    final stalled = AutoBackupService(
      store,
      () async => bundle(),
      reminder,
      httpClient: () => MockClient((request) async {
        throw TimeoutException('stalled');
      }),
      clock: () => now,
    );

    expect(await stalled.runNow(), AutoBackupOutcome.failed);
    expect((await store.load()).lastError, 'unreachable');
  });
}
