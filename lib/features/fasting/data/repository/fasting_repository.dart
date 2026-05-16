import 'package:opennutritracker/features/fasting/data/data_source/fasting_data_source.dart';
import 'package:opennutritracker/features/fasting/domain/entity/fasting_session_entity.dart';

class FastingRepository {
  final FastingDataSource _dataSource;

  FastingRepository(this._dataSource);

  Future<void> addSession(FastingSessionEntity session) async {
    await _dataSource.addSession(session.toDBO());
  }

  Future<void> updateSession(FastingSessionEntity session) async {
    await _dataSource.updateSession(session.toDBO());
  }

  Future<FastingSessionEntity?> getActiveSession() async {
    final dbo = await _dataSource.getActiveSession();
    if (dbo == null) return null;
    return FastingSessionEntity.fromDBO(dbo);
  }

  Future<FastingSessionEntity?> getSession(String id) async {
    final dbo = await _dataSource.getSession(id);
    if (dbo == null) return null;
    return FastingSessionEntity.fromDBO(dbo);
  }

  Future<List<FastingSessionEntity>> allSessions() async {
    final all = await _dataSource.allSessions();
    return all.map(FastingSessionEntity.fromDBO).toList();
  }
}
