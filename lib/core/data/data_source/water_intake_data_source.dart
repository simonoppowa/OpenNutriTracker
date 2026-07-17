import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// Stores water intake entries — one row per sip. We hold every entry rather
/// than coalescing to a daily total so the "undo last" affordance can roll a
/// single mistap back without throwing away the rest of the day's log, and
/// so a future "graph of hydration through the day" view is cheap to add.
class WaterIntakeDataSource {
  final log = Logger('WaterIntakeDataSource');
  final HiveDBProvider _db;

  WaterIntakeDataSource(this._db);

  Box<WaterIntakeDBO> get _waterIntakeBox => _db.waterIntakeBox;

  Future<void> addEntry(WaterIntakeDBO entry) async {
    log.fine('Adding water intake ${entry.amountMl} ml at ${entry.dateTime}');
    await _waterIntakeBox.put(entry.id, entry);
  }

  Future<void> addAllEntries(List<WaterIntakeDBO> entries) async {
    log.fine('Adding ${entries.length} water intake entries');
    await _waterIntakeBox.putAll({
      for (final entry in entries) entry.id: entry,
    });
  }

  Future<List<WaterIntakeDBO>> allEntries() async {
    return _waterIntakeBox.values.toList();
  }

  Future<List<WaterIntakeDBO>> entriesInRange(
    DateTime from,
    DateTime to,
  ) async {
    return _waterIntakeBox.values
        .where(
          (entry) =>
              !entry.dateTime.isBefore(from) && entry.dateTime.isBefore(to),
        )
        .toList();
  }

  Future<WaterIntakeDBO?> getEntry(String id) async {
    return _waterIntakeBox.get(id);
  }

  Future<void> deleteEntry(String id) async {
    log.fine('Deleting water intake entry $id');
    await _waterIntakeBox.delete(id);
  }
}
