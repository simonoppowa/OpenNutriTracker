import 'package:flutter/foundation.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

/// Remembers when the last JSON backup was saved and decides when the home
/// screen reminds of the next one. A sideloaded app can lose its data when
/// its signature expires, so an old backup is worth a nudge.
class BackupReminder {
  static const defaultReminderDays = 7;

  /// The periods the export dialog offers; 0 switches the reminder off.
  static const reminderDayOptions = [0, 3, 7, 14, 30];

  final ConfigDataSource _config;
  final DateTime Function() _clock;
  final _changes = ValueNotifier<int>(0);

  /// Fires after [markBackedUp] or [setReminderDays] stored a change, so a
  /// mounted reminder can reload.
  Listenable get changes => _changes;

  BackupReminder(this._config, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Whether a reminder is due: there is no backup yet, or the last one is
  /// at least [reminderDays] days old. A [reminderDays] of 0 never reminds.
  static bool isDue({
    required DateTime? lastBackupAt,
    required DateTime now,
    int reminderDays = defaultReminderDays,
  }) {
    if (reminderDays <= 0) return false;
    if (lastBackupAt == null) return true;
    return now.difference(lastBackupAt) >= Duration(days: reminderDays);
  }

  Future<({DateTime? lastBackupAt, int reminderDays, bool isDue})>
  load() async {
    final config = await _config.getConfig();
    final days = config.backupReminderDays ?? defaultReminderDays;
    return (
      lastBackupAt: config.lastBackupAt,
      reminderDays: days,
      isDue: isDue(
        lastBackupAt: config.lastBackupAt,
        now: _clock(),
        reminderDays: days,
      ),
    );
  }

  /// Records that a JSON backup was just saved.
  Future<void> markBackedUp() =>
      _update((config) => config.lastBackupAt = _clock());

  Future<void> setReminderDays(int days) =>
      _update((config) => config.backupReminderDays = days);

  Future<void> _update(void Function(ConfigDBO config) change) async {
    final config = await _config.getConfig();
    change(config);
    await _config.addConfig(config);
    _changes.value++;
  }
}
