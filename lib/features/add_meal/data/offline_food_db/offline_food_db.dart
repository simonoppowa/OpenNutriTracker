import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/food_rpc_client.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/offline_food_db/sqlite_food_rpc_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// What `meta` says about an installed `foods.sqlite`.
@immutable
class OfflineFoodDbInfo {
  const OfflineFoodDbInfo({
    required this.buildDate,
    required this.sizeBytes,
    required this.foodCount,
    required this.foodsBySource,
  });

  final DateTime? buildDate;
  final int sizeBytes;
  final int foodCount;
  final Map<String, int> foodsBySource;
}

enum OfflineFoodDbPhase { idle, downloading, verifying }

/// The installed file, if any, and what an install in progress is doing.
@immutable
class OfflineFoodDbState {
  const OfflineFoodDbState({
    this.info,
    this.phase = OfflineFoodDbPhase.idle,
    this.received = 0,
    this.total,
    this.failed = false,
  });

  /// Null when no database is installed.
  final OfflineFoodDbInfo? info;
  final OfflineFoodDbPhase phase;

  /// Bytes of the download so far, and its size when the server sent one.
  final int received;
  final int? total;

  /// The last install failed (the previous database, if any, is untouched).
  final bool failed;

  bool get busy => phase != OfflineFoodDbPhase.idle;

  OfflineFoodDbState copyWith({
    OfflineFoodDbInfo? Function()? info,
    OfflineFoodDbPhase? phase,
    int? received,
    int? Function()? total,
    bool? failed,
  }) => OfflineFoodDbState(
    info: info == null ? this.info : info(),
    phase: phase ?? this.phase,
    received: received ?? this.received,
    total: total == null ? this.total : total(),
    failed: failed ?? this.failed,
  );
}

class OfflineFoodDbException implements Exception {
  OfflineFoodDbException(this.message);

  final String message;

  @override
  String toString() => 'OfflineFoodDbException: $message';
}

class _Cancelled implements Exception {
  const _Cancelled();
}

/// Owns `foods.sqlite` in the app-support directory and answers the food
/// functions from it while it is installed, from [fallback] (Supabase)
/// otherwise.
///
/// Registered as the app's [FoodRpcClient], so installing, updating or
/// removing the file switches every later search over at once — no restart.
/// A new file is downloaded and unpacked beside the old one, opened and
/// checked (schema version, integrity, a real search), and only then moved
/// over it; a failure leaves the installed database as it was.
class OfflineFoodDb implements FoodRpcClient {
  OfflineFoodDb({
    required FoodRpcClient fallback,
    http.Client? httpClient,
    Future<Directory> Function()? directory,
    Uri? url,
  }) : _fallback = fallback,
       _http = httpClient ?? http.Client(),
       _directory = directory ?? getApplicationSupportDirectory,
       url = url ?? defaultUrl;

  static const fileName = 'foods.sqlite';

  /// The newest release of the backend repo, where the maintainer uploads
  /// the `foods.sqlite.gz` that `scripts/shared/build_sqlite.py` builds.
  static final defaultUrl = Uri.parse(
    'https://github.com/simonoppowa/OpenNutriTracker-Backend/releases/'
    'latest/download/foods.sqlite.gz',
  );

  /// Gaps longer than this in the download count as a dead connection.
  static const _stallTimeout = Duration(seconds: 30);

  final log = Logger('OfflineFoodDb');
  final FoodRpcClient _fallback;
  final http.Client _http;
  final Future<Directory> Function() _directory;
  final Uri url;

  final state = ValueNotifier(const OfflineFoodDbState());

  Database? _db;
  SqliteFoodRpcClient? _sqlite;
  bool _cancelled = false;

  /// Whether searches are answered by the offline database right now.
  bool get isActive => _sqlite != null;

  @override
  Future<List<Map<String, dynamic>>> rpc(
    String fn,
    Map<String, dynamic> params,
  ) => (_sqlite ?? _fallback).rpc(fn, params);

  Future<File> _file() async => File('${(await _directory()).path}/$fileName');

  /// Opens the installed database, if there is one with the schema version
  /// this build reads. Never throws: without it the app searches Supabase,
  /// as it would with no file at all.
  Future<void> open() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return;
      final (db, info) = _openChecked(file.path, thorough: false);
      _activate(db, info);
    } catch (e) {
      log.warning('Offline food database not opened: $e');
    }
  }

  /// Downloads, checks and installs the newest database, replacing the one
  /// installed. Progress and the outcome are reported on [state].
  Future<void> download() async {
    if (state.value.busy) return;
    _cancelled = false;
    final dir = await _directory();
    final gz = File('${dir.path}/$fileName.gz.part');
    final unpacked = File('${dir.path}/$fileName.part');
    state.value = state.value.copyWith(
      phase: OfflineFoodDbPhase.downloading,
      received: 0,
      total: () => null,
      failed: false,
    );
    try {
      final response = await _http
          .send(http.Request('GET', url))
          .timeout(_stallTimeout);
      if (response.statusCode != 200) {
        throw OfflineFoodDbException('HTTP ${response.statusCode}');
      }
      final total = response.contentLength;
      final sink = gz.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream.timeout(_stallTimeout)) {
          if (_cancelled) throw const _Cancelled();
          sink.add(chunk);
          received += chunk.length;
          state.value = state.value.copyWith(
            received: received,
            total: () => total,
          );
        }
      } finally {
        await sink.close();
      }
      if (_cancelled) throw const _Cancelled();

      state.value = state.value.copyWith(phase: OfflineFoodDbPhase.verifying);
      await gz.openRead().transform(gzip.decoder).pipe(unpacked.openWrite());
      final (checked, _) = _openChecked(unpacked.path, thorough: true);
      checked.close();

      // Same directory, so the rename is atomic: a reader sees the old file
      // or the new one, never half of either.
      final target = await _file();
      _deactivate();
      await unpacked.rename(target.path);
      final (db, info) = _openChecked(target.path, thorough: false);
      _activate(db, info);
      log.info('Offline food database installed (${info.foodCount} foods)');
    } on _Cancelled {
      log.fine('Offline food database download cancelled');
    } catch (e) {
      log.warning('Offline food database install failed: $e');
      state.value = state.value.copyWith(failed: true);
      // A failure after the old file was closed must not leave search
      // without it.
      if (!isActive) await open();
    } finally {
      for (final f in [gz, unpacked]) {
        if (f.existsSync()) f.deleteSync();
      }
      state.value = state.value.copyWith(phase: OfflineFoodDbPhase.idle);
    }
  }

  /// Stops a download in progress; the installed database stays as it is.
  void cancel() => _cancelled = true;

  /// Deletes the database; searches go back to Supabase at once.
  Future<void> remove() async {
    _deactivate();
    final file = await _file();
    if (file.existsSync()) file.deleteSync();
    state.value = state.value.copyWith(info: () => null, failed: false);
  }

  /// Name and licence note of every source in the installed database, for
  /// the attribution its licences require.
  List<({String code, String name, String? licence})> sources() {
    final db = _db;
    if (db == null) return const [];
    return [
      for (final row in db.select(
        'select code, name, license_note from food_source '
        'where code in (select distinct source from food_summary) '
        'order by code',
      ))
        (
          code: row['code'] as String,
          name: row['name'] as String,
          licence: row['license_note'] as String?,
        ),
    ];
  }

  (Database, OfflineFoodDbInfo) _openChecked(
    String path, {
    required bool thorough,
  }) {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final meta = {
        for (final row in db.select('select key, value from meta'))
          row['key'] as String: row['value'] as String,
      };
      final version = meta['schema_version'];
      if (version != '$offlineFoodDbSchemaVersion') {
        throw OfflineFoodDbException('schema version $version');
      }
      if (thorough) {
        final check = db.select('pragma quick_check').first.columnAt(0);
        if (check != 'ok') throw OfflineFoodDbException('quick_check: $check');
        // The statements a search runs, FTS5 included, end to end.
        final client = SqliteFoodRpcClient(db);
        client.query(SPConst.searchFoodSummaryFn, {'term': 'water'});
        client.query(SPConst.searchFoodTranslationFn, {
          'term': 'water',
          'loc': 'de',
        });
      }
      final sources = meta['sources'];
      final info = OfflineFoodDbInfo(
        buildDate: DateTime.tryParse(meta['build_date'] ?? ''),
        sizeBytes: File(path).lengthSync(),
        foodCount: int.tryParse(meta['food_count'] ?? '') ?? 0,
        foodsBySource: sources == null
            ? const {}
            : (jsonDecode(sources) as Map<String, dynamic>).cast(),
      );
      if (info.foodCount <= 0) throw OfflineFoodDbException('no foods');
      return (db, info);
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  void _activate(Database db, OfflineFoodDbInfo info) {
    _db = db;
    _sqlite = SqliteFoodRpcClient(db);
    state.value = state.value.copyWith(info: () => info);
  }

  void _deactivate() {
    _sqlite = null;
    _db?.close();
    _db = null;
  }
}
