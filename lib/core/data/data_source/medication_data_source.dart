import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/medication_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class MedicationDataSource {
  final log = Logger('MedicationDataSource');
  final HiveDBProvider _db;

  MedicationDataSource(this._db);

  Box<MedicationDBO> get _medicationBox => _db.medicationBox;

  Future<void> addEntry(MedicationDBO entry) async {
    log.fine('Adding medication ${entry.name} (${entry.amount} ${entry.unit}) at ${entry.day}');
    await _medicationBox.put(entry.id, entry);
  }

  Future<void> addAllEntries(List<MedicationDBO> entries) async {
    log.fine('Adding ${entries.length} medication entries');
    await _medicationBox.putAll({
      for (final entry in entries) entry.id: entry,
    });
  }

  Future<List<MedicationDBO>> allEntries() async {
    return _medicationBox.values.toList();
  }

  Future<List<MedicationDBO>> entriesForDay(DateTime day) async {
    final targetDay = DateTime(day.year, day.month, day.day);
    return _medicationBox.values
        .where((entry) =>
            entry.day.year == targetDay.year &&
            entry.day.month == targetDay.month &&
            entry.day.day == targetDay.day)
        .toList();
  }

  Future<MedicationDBO?> getEntry(String id) async {
    return _medicationBox.get(id);
  }

  Future<void> deleteEntry(String id) async {
    log.fine('Deleting medication entry $id');
    await _medicationBox.delete(id);
  }
}
