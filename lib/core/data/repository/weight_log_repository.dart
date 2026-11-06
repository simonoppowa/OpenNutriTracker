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

  /// Every entry, by the day it is filed under: [WeightLogEntity.filedDay],
  /// the day of its storage key. That is the day [getEntry] and [addEntry]
  /// find it by, which the entry's own date need not be after a time-zone
  /// change.
  Future<Map<DateTime, WeightLogEntity>> getEntriesByDay() async {
    final entries = await getAllEntries();
    return {for (final entry in entries) entry.filedDay ?? entry.date: entry};
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
