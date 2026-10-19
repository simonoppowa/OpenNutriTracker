import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/settings/data/auto_backup_settings.dart';
import 'package:opennutritracker/features/settings/data/webdav_client.dart';
import 'package:opennutritracker/features/settings/domain/auto_backup_service.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/auto_backup_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _FakeService extends Fake implements AutoBackupService {
  Object? connectionError;
  final tested = <AutoBackupSettings>[];
  var backups = <String>[];
  var ranNow = 0;
  final downloaded = <String>[];

  @override
  Future<void> testConnection(AutoBackupSettings settings) async {
    tested.add(settings);
    if (connectionError != null) throw connectionError!;
  }

  @override
  Future<AutoBackupOutcome> runNow() async {
    ranNow++;
    return AutoBackupOutcome.uploaded;
  }

  @override
  Future<List<String>> listBackups() async => backups;

  @override
  Future<Archive> download(String name) async {
    downloaded.add(name);
    return Archive();
  }
}

void main() {
  late AutoBackupSettingsStore store;
  late _FakeService service;
  late List<bool> restores;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = AutoBackupSettingsStore(const FlutterSecureStorage());
    service = _FakeService();
    restores = [];
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: AutoBackupScreen(
          store: store,
          service: service,
          restore: (archive, {required replaceExisting}) async =>
              restores.add(replaceExisting),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillIn(WidgetTester tester, {required String folder}) async {
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsIdentifier('auto-backup-folder'),
        matching: find.byType(TextField),
      ),
      folder,
    );
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsIdentifier('auto-backup-token'),
        matching: find.byType(TextField),
      ),
      'token',
    );
  }

  Future<void> tapButton(WidgetTester tester, String id) async {
    await tester.ensureVisible(find.bySemanticsIdentifier(id));
    await tester.tap(find.bySemanticsIdentifier(id));
    await tester.pumpAndSettle();
  }

  testWidgets('saves the folder and the token', (tester) async {
    await pumpScreen(tester);
    await fillIn(tester, folder: 'https://files.example.org/dav/nutri/');

    await tapButton(tester, 'auto-backup-save');

    final saved = await store.load();
    expect(saved.folderUrl, 'https://files.example.org/dav/nutri/');
    expect(saved.token, 'token');
  });

  testWidgets('refuses an address that is not https', (tester) async {
    await pumpScreen(tester);
    await fillIn(tester, folder: 'http://files.example.org/dav/');

    await tapButton(tester, 'auto-backup-save');

    expect(find.text('Enter an https address.'), findsOneWidget);
    expect((await store.load()).folderUrl, isEmpty);
  });

  testWidgets('tells whether the connection works', (tester) async {
    await pumpScreen(tester);
    await fillIn(tester, folder: 'https://files.example.org/dav/nutri/');

    await tapButton(tester, 'auto-backup-test');
    expect(find.text('The connection works.'), findsOneWidget);

    service.connectionError = const WebDavException('x', statusCode: 401);
    await tapButton(tester, 'auto-backup-test');
    expect(
      find.text('The connection failed: the server rejected the token'),
      findsOneWidget,
    );
  });

  testWidgets('backs up on request', (tester) async {
    await pumpScreen(tester);
    await fillIn(tester, folder: 'https://files.example.org/dav/nutri/');

    await tapButton(tester, 'auto-backup-now');

    expect(service.ranNow, 1);
  });

  testWidgets('restores the chosen backup, replacing when asked', (
    tester,
  ) async {
    service.backups = [
      'nutritracker-backup-20261019-093000.zip',
      'nutritracker-backup-20261018-093000.zip',
    ];
    await pumpScreen(tester);
    await fillIn(tester, folder: 'https://files.example.org/dav/nutri/');

    await tapButton(tester, 'auto-backup-restore');
    await tester.tap(find.text('nutritracker-backup-20261018-093000.zip'));
    await tester.tap(find.bySemanticsIdentifier('auto-backup-restore-replace'));
    await tester.pump();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(find.text('Replace all data?'), findsOneWidget);
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(service.downloaded, ['nutritracker-backup-20261018-093000.zip']);
    expect(restores, [true]);
    expect(find.text('Backup restored.'), findsOneWidget);
  });

  testWidgets('says so when the server holds no backup', (tester) async {
    await pumpScreen(tester);
    await fillIn(tester, folder: 'https://files.example.org/dav/nutri/');

    await tapButton(tester, 'auto-backup-restore');

    expect(
      find.text('There are no backups on the server yet.'),
      findsOneWidget,
    );
    expect(restores, isEmpty);
  });

  testWidgets('cancelling the replace question restores nothing', (
    tester,
  ) async {
    service.backups = ['nutritracker-backup-20261019-093000.zip'];
    await pumpScreen(tester);
    await fillIn(tester, folder: 'https://files.example.org/dav/nutri/');

    await tapButton(tester, 'auto-backup-restore');
    await tester.tap(find.bySemanticsIdentifier('auto-backup-restore-replace'));
    await tester.pump();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(service.downloaded, isEmpty);
    expect(restores, isEmpty);
  });
}
