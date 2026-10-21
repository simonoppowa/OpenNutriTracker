import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/settings/data/backup_folder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  void answer(Object? Function(MethodCall call) handler) {
    calls = [];
    messenger.setMockMethodCallHandler(ChannelBackupFolder.channel, (
      call,
    ) async {
      calls.add(call);
      return handler(call);
    });
  }

  tearDown(
    () => messenger.setMockMethodCallHandler(ChannelBackupFolder.channel, null),
  );

  const folder = ChannelBackupFolder();

  test('a picked folder comes back with its bookmark and name', () async {
    answer((_) => {'bookmark': 'bm', 'name': 'Backups'});

    expect(await folder.pick(), (bookmark: 'bm', name: 'Backups'));
  });

  test('a cancelled pick is null', () async {
    answer((_) => null);

    expect(await folder.pick(), isNull);
  });

  test('writes hand the bytes and the bookmark over', () async {
    answer((_) => {'bookmark': 'bm-2'});

    final renewed = await folder.write('bm', 'b.zip', [1, 2, 3]);

    expect(renewed, 'bm-2');
    expect(calls.single.method, 'write');
    expect(calls.single.arguments['bookmark'], 'bm');
    expect(calls.single.arguments['name'], 'b.zip');
    expect(calls.single.arguments['bytes'], [1, 2, 3]);
  });

  test('lists and reads', () async {
    answer(
      (call) => switch (call.method) {
        'list' => {
          'names': ['a.zip', 'b.zip'],
        },
        _ => {
          'bytes': Uint8List.fromList([7]),
        },
      },
    );

    expect((await folder.list('bm')).names, ['a.zip', 'b.zip']);
    expect((await folder.list('bm')).bookmark, isNull);
    expect((await folder.read('bm', 'a.zip')).bytes, [7]);
  });

  test('a native error keeps its code', () async {
    answer((_) => throw PlatformException(code: 'access_denied'));

    expect(
      () => folder.delete('bm', 'a.zip'),
      throwsA(
        isA<BackupFolderException>().having(
          (e) => e.code,
          'code',
          'access_denied',
        ),
      ),
    );
  });

  test('without the native side it is unavailable', () async {
    expect(
      () => folder.list('bm'),
      throwsA(
        isA<BackupFolderException>().having(
          (e) => e.code,
          'code',
          'unavailable',
        ),
      ),
    );
  });
}
