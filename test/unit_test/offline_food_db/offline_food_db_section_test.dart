import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/food_rpc_client.dart';
import 'package:opennutritracker/features/add_meal/data/offline_food_db/offline_food_db.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/offline_food_db_section.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';
import 'fixture_db.dart';

class _NoBackend implements FoodRpcClient {
  @override
  Future<List<Map<String, dynamic>>> rpc(
    String fn,
    Map<String, dynamic> params,
  ) async => const [];
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('offline_section'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<OfflineFoodDb> pump(WidgetTester tester, {bool installed = false}) {
    return tester
        .runAsync(() async {
          final db = OfflineFoodDb(
            fallback: _NoBackend(),
            httpClient: MockClient(
              (_) async =>
                  http.Response.bytes(fixtureGz.readAsBytesSync(), 200),
            ),
            directory: () async => dir,
          );
          if (installed) await db.download();
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: S.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: OfflineFoodDbSection(database: db),
                ),
              ),
            ),
          );
          return db;
        })
        .then((db) => db!);
  }

  Finder byId(String id) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.identifier == id,
  );

  testWidgets('not installed: offers a download', (tester) async {
    await pump(tester);

    expect(find.text(l10nEn.offlineFoodDbTitle), findsOneWidget);
    expect(find.text(l10nEn.offlineFoodDbNotInstalled), findsOneWidget);
    expect(find.text(l10nEn.offlineFoodDbDownload), findsOneWidget);
    expect(byId('food-sources-offline-download'), findsOneWidget);
    expect(byId('food-sources-offline-remove'), findsNothing);
  });

  testWidgets('installed: shows meta and offers update and remove', (
    tester,
  ) async {
    await pump(tester, installed: true);

    expect(find.text(l10nEn.offlineFoodDbInstalled), findsOneWidget);
    expect(find.textContaining('12 foods'), findsOneWidget);
    expect(find.text(l10nEn.offlineFoodDbUpdate), findsOneWidget);
    expect(byId('food-sources-offline-remove'), findsOneWidget);
    expect(byId('food-sources-offline-sources'), findsOneWidget);
  });

  testWidgets('remove asks first, then goes back to not installed', (
    tester,
  ) async {
    final db = await pump(tester, installed: true);

    await tester.tap(find.text(l10nEn.offlineFoodDbRemove));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.offlineFoodDbRemoveTitle), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text(l10nEn.offlineFoodDbRemove).last);
      await tester.pump();
    });
    await tester.pumpAndSettle();

    expect(db.isActive, isFalse);
    expect(find.text(l10nEn.offlineFoodDbNotInstalled), findsOneWidget);
  });
}
