import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/food_rpc_client.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/offline_food_db/offline_food_db.dart';
import 'package:sqlite3/sqlite3.dart';

import 'fixture_db.dart';

/// Stands in for Supabase and records what it was asked.
class _Fallback implements FoodRpcClient {
  final calls = <String>[];

  @override
  Future<List<Map<String, dynamic>>> rpc(
    String fn,
    Map<String, dynamic> params,
  ) async {
    calls.add(fn);
    return const [];
  }
}

void main() {
  late Directory dir;
  late _Fallback fallback;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('offline_food_db');
    fallback = _Fallback();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  OfflineFoodDb database(http.Client client) => OfflineFoodDb(
    fallback: fallback,
    httpClient: client,
    directory: () async => dir,
  );

  http.Client serving(List<int> body, {int status = 200}) =>
      MockClient((request) async => http.Response.bytes(body, status));

  Future<List<Object?>> potatoIds(OfflineFoodDb db) async => [
    for (final r in await db.rpc(SPConst.searchFoodSummaryFn, {
      'term': 'potato',
    }))
      r['food_id'],
  ];

  test('without a file, Supabase answers', () async {
    final db = database(serving(const []));
    await db.open();

    expect(db.isActive, isFalse);
    expect(db.state.value.info, isNull);
    await db.rpc(SPConst.searchFoodSummaryFn, {'term': 'potato'});
    expect(fallback.calls, [SPConst.searchFoodSummaryFn]);
  });

  test('a download installs, switches over and survives a restart', () async {
    final db = database(serving(fixtureGz.readAsBytesSync()));
    final phases = <OfflineFoodDbPhase>[];
    db.state.addListener(() => phases.add(db.state.value.phase));

    await db.download();

    expect(db.isActive, isTrue);
    expect(
      phases,
      containsAllInOrder([
        OfflineFoodDbPhase.downloading,
        OfflineFoodDbPhase.verifying,
        OfflineFoodDbPhase.idle,
      ]),
    );
    final state = db.state.value;
    expect(state.failed, isFalse);
    expect(state.info!.foodCount, 12);
    expect(state.info!.foodsBySource, {
      'fdc_survey': 6,
      'fdc_sr_legacy': 3,
      'fineli': 3,
    });
    expect(state.info!.buildDate, isNotNull);
    expect(state.received, fixtureGz.lengthSync());
    expect(await potatoIds(db), hasLength(7));
    expect(fallback.calls, isEmpty, reason: 'no restart needed');
    expect(db.sources().map((s) => s.code), [
      'fdc_sr_legacy',
      'fdc_survey',
      'fineli',
    ]);
    expect(
      dir.listSync().map((f) => f.uri.pathSegments.last),
      [OfflineFoodDb.fileName],
      reason: 'the .part files are gone',
    );

    // The next start opens it again.
    final restarted = database(serving(const []));
    await restarted.open();
    expect(restarted.isActive, isTrue);
    expect(await potatoIds(restarted), hasLength(7));
  });

  test('a corrupt download leaves the installed database alone', () async {
    final good = database(serving(fixtureGz.readAsBytesSync()));
    await good.download();

    final db = database(serving(gzip.encode('not a database'.codeUnits)));
    await db.open();
    await db.download();

    expect(db.state.value.failed, isTrue);
    expect(db.isActive, isTrue);
    expect(await potatoIds(db), hasLength(7));
  });

  test('an HTTP error is a failure, not an install', () async {
    final db = database(serving(const [], status: 404));
    await db.download();

    expect(db.state.value.failed, isTrue);
    expect(db.state.value.busy, isFalse);
    expect(db.isActive, isFalse);
  });

  test('a file with another schema version is not used', () async {
    final path = '${dir.path}/other.sqlite';
    final other = sqlite3.open(path)
      ..execute('create table meta (key text primary key, value text)')
      ..execute("insert into meta values ('schema_version', '99')");
    other.close();
    final db = database(serving(gzip.encode(File(path).readAsBytesSync())));

    await db.download();

    expect(db.state.value.failed, isTrue);
    expect(db.isActive, isFalse);
    expect(File('${dir.path}/${OfflineFoodDb.fileName}').existsSync(), isFalse);

    File(path).renameSync('${dir.path}/${OfflineFoodDb.fileName}');
    await db.open();
    expect(db.isActive, isFalse);
  });

  test('remove goes back to Supabase at once', () async {
    final db = database(serving(fixtureGz.readAsBytesSync()));
    await db.download();

    await db.remove();

    expect(db.isActive, isFalse);
    expect(db.state.value.info, isNull);
    expect(File('${dir.path}/${OfflineFoodDb.fileName}').existsSync(), isFalse);
    await db.rpc(SPConst.searchFoodSummaryFn, {'term': 'potato'});
    expect(fallback.calls, [SPConst.searchFoodSummaryFn]);
  });

  test('cancel stops a download', () async {
    late OfflineFoodDb db;
    final client = MockClient.streaming((request, _) async {
      db.cancel();
      return http.StreamedResponse(
        Stream.fromIterable([fixtureGz.readAsBytesSync()]),
        200,
      );
    });
    db = database(client);

    await db.download();

    expect(db.isActive, isFalse);
    expect(db.state.value.failed, isFalse);
    expect(db.state.value.busy, isFalse);
    expect(dir.listSync(), isEmpty);
  });
}
