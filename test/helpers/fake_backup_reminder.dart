import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/settings/domain/backup_reminder.dart';

/// A [BackupReminder] with a fixed state that records what is set on it.
class FakeBackupReminder extends Fake implements BackupReminder {
  FakeBackupReminder({
    this.lastBackupAt,
    this.reminderDays = BackupReminder.defaultReminderDays,
    this.due = true,
  });

  DateTime? lastBackupAt;
  int reminderDays;
  bool due;
  final setDays = <int>[];
  final notifier = ValueNotifier<int>(0);

  @override
  Listenable get changes => notifier;

  @override
  Future<({DateTime? lastBackupAt, int reminderDays, bool isDue})>
  load() async =>
      (lastBackupAt: lastBackupAt, reminderDays: reminderDays, isDue: due);

  var backedUp = 0;

  @override
  Future<void> markBackedUp() async => backedUp++;

  @override
  Future<void> setReminderDays(int days) async {
    setDays.add(days);
    reminderDays = days;
  }
}
