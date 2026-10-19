import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/features/settings/domain/backup_reminder.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

void main() {
  group('isDue', () {
    final now = DateTime(2026, 10, 20, 9);

    test('is due without any backup yet', () {
      expect(BackupReminder.isDue(lastBackupAt: null, now: now), isTrue);
    });

    test('is due once the reminder period has passed', () {
      expect(
        BackupReminder.isDue(
          lastBackupAt: now.subtract(const Duration(days: 7)),
          now: now,
        ),
        isTrue,
      );
      expect(
        BackupReminder.isDue(
          lastBackupAt: now.subtract(const Duration(days: 6, hours: 23)),
          now: now,
        ),
        isFalse,
      );
    });

    test('uses the chosen number of days', () {
      final last = now.subtract(const Duration(days: 3));
      expect(
        BackupReminder.isDue(lastBackupAt: last, now: now, reminderDays: 3),
        isTrue,
      );
      expect(
        BackupReminder.isDue(lastBackupAt: last, now: now, reminderDays: 14),
        isFalse,
      );
    });

    test('never reminds when switched off', () {
      expect(
        BackupReminder.isDue(lastBackupAt: null, now: now, reminderDays: 0),
        isFalse,
      );
    });
  });

  group('stored state', () {
    late Directory hiveDir;
    late BackupReminder reminder;
    late ConfigDataSource config;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('backup_reminder');
      Hive.init(hiveDir.path);
      registerHiveAdaptersOnce();
      final provider = FakeHiveDBProvider(
        configBox: await Hive.openBox<ConfigDBO>('config'),
        appConfigBox: await Hive.openBox<ConfigDBO>('app_config'),
      );
      config = ConfigDataSource(provider);
      await config.initializeConfig();
      reminder = BackupReminder(config, clock: () => DateTime(2026, 10, 20, 9));
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await hiveDir.delete(recursive: true);
    });

    test('starts with no backup and the default period', () async {
      final state = await reminder.load();

      expect(state.lastBackupAt, isNull);
      expect(state.reminderDays, BackupReminder.defaultReminderDays);
      expect(state.isDue, isTrue);
    });

    test('remembers a backup', () async {
      await reminder.markBackedUp();

      final state = await reminder.load();
      expect(state.lastBackupAt, DateTime(2026, 10, 20, 9));
      expect(state.isDue, isFalse);
    });

    test('tells listeners about a stored change', () async {
      var calls = 0;
      reminder.changes.addListener(() => calls++);

      await reminder.markBackedUp();
      await reminder.setReminderDays(3);

      expect(calls, 2);
    });

    test('remembers the period and keeps the rest of the config', () async {
      await config.setConfigUsesKilojoules(true);

      await reminder.setReminderDays(14);

      expect((await reminder.load()).reminderDays, 14);
      expect((await config.getConfig()).usesKilojoules, isTrue);
    });
  });
}
