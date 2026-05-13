import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';

class WeightLogRepository {
  final WeightLogDataSource _weightLogDataSource;

  WeightLogRepository(this._weightLogDataSource);

  Future<void> addEntry(WeightLogEntity entry) async {
    await _weightLogDataSource.addEntry(WeightLogDBO.fromWeightLogEntity(entry));
  }

  Future<void> addAllEntries(List<WeightLogDBO> entries) async {
    await _weightLogDataSource.addAllEntries(entries);
  }

  Future<List<WeightLogEntity>> getAllEntries() async {
    final dbos = await _weightLogDataSource.allEntries();
    return dbos.map(WeightLogEntity.fromWeightLogDBO).toList();
  }

  Future<List<WeightLogDBO>> getAllEntriesDBO() async {
    return _weightLogDataSource.allEntries();
  }

  Future<List<WeightLogEntity>> getEntriesInRange(
    DateTime from,
    DateTime to,
  ) async {
    final dbos = await _weightLogDataSource.entriesInRange(from, to);
    return dbos.map(WeightLogEntity.fromWeightLogDBO).toList();
  }

  Future<WeightLogEntity?> getEntry(DateTime date) async {
    final dbo = await _weightLogDataSource.getEntry(date);
    return dbo == null ? null : WeightLogEntity.fromWeightLogDBO(dbo);
  }

  Future<void> deleteEntry(DateTime date) async {
    await _weightLogDataSource.deleteEntry(date);
  }
}
