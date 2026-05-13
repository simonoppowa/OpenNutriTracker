import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class WeightLogDataSource {
  final log = Logger('WeightLogDataSource');
  final Box<WeightLogDBO> _weightLogBox;

  WeightLogDataSource(this._weightLogBox);

  /// Stores a single entry keyed by its day (`yyyy-MM-dd`). Two entries
  /// for the same calendar day overwrite each other so the log carries
  /// at most one weight reading per day — the reporters in #38 were
  /// asking for a daily trend, not minute-by-minute samples.
  Future<void> addEntry(WeightLogDBO entry) async {
    log.fine('Adding weight log entry for ${entry.date}');
    await _weightLogBox.put(entry.date.toParsedDay(), entry);
  }

  Future<void> addAllEntries(List<WeightLogDBO> entries) async {
    log.fine('Adding ${entries.length} weight log entries');
    await _weightLogBox.putAll({
      for (final entry in entries) entry.date.toParsedDay(): entry,
    });
  }

  Future<List<WeightLogDBO>> allEntries() async {
    return _weightLogBox.values.toList();
  }

  Future<List<WeightLogDBO>> entriesInRange(
    DateTime from,
    DateTime to,
  ) async {
    return _weightLogBox.values
        .where(
          (entry) => !entry.date.isBefore(from) && !entry.date.isAfter(to),
        )
        .toList();
  }

  Future<WeightLogDBO?> getEntry(DateTime date) async {
    return _weightLogBox.get(date.toParsedDay());
  }

  Future<void> deleteEntry(DateTime date) async {
    log.fine('Deleting weight log entry for $date');
    await _weightLogBox.delete(date.toParsedDay());
  }
}
