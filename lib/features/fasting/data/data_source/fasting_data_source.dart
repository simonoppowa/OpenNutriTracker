import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// Stores fasting sessions keyed by session id. The data source intentionally
/// makes no value-judgement about cancellation vs natural completion — both
/// are simply timestamped on the same record.
class FastingDataSource {
  final _log = Logger('FastingDataSource');
  final HiveDBProvider _db;

  FastingDataSource(this._db);

  Box<FastingSessionDBO> get _box => _db.fastingBox;

  Future<void> addSession(FastingSessionDBO session) async {
    _log.fine('Adding fasting session ${session.id}');
    await _box.put(session.id, session);
  }

  Future<void> updateSession(FastingSessionDBO session) async {
    _log.fine('Updating fasting session ${session.id}');
    await _box.put(session.id, session);
  }

  Future<FastingSessionDBO?> getSession(String id) async {
    return _box.get(id);
  }

  Future<List<FastingSessionDBO>> allSessions() async {
    return _box.values.toList();
  }

  /// Returns the most recent session that has neither completed nor been
  /// cancelled, if any. There should only ever be one — but if the previous
  /// run crashed before writing the end-state, the newest one wins.
  Future<FastingSessionDBO?> getActiveSession() async {
    final active = _box.values
        .where((s) => s.completedAt == null && s.cancelledAt == null)
        .toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return active.first;
  }
}
