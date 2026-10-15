import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/utils/daily_reminder_scheduler.dart';
import 'package:opennutritracker/core/utils/locale_provider.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _Config implements ConfigRepository {
  _Config(this.config);

  final ConfigEntity config;

  @override
  Future<ConfigEntity> getConfig() async => config;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingNotificationService extends NotificationService {
  final scheduled = <Map<String, Object>>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    scheduled.add({
      'hour': hour,
      'minute': minute,
      'title': title,
      'body': body,
      'channelName': channelName,
    });
  }
}

ConfigEntity _config({required bool enabled}) => ConfigEntity(
  true,
  true,
  false,
  AppThemeEntity.system,
  notificationsEnabled: enabled,
  notificationHour: 19,
  notificationMinute: 45,
);

void main() {
  group('rescheduling the daily reminder for a new language (#1366)', () {
    late _RecordingNotificationService notifications;

    setUp(() => notifications = _RecordingNotificationService());

    test('schedules the new language\'s text at the saved time', () async {
      final it = lookupS(const Locale('it'));
      // Without a translation the assertion below could pass on English.
      expect(
        it.notificationsDailyReminderBody,
        isNot(lookupS(const Locale('en')).notificationsDailyReminderBody),
      );

      await rescheduleDailyReminder(
        configRepository: _Config(_config(enabled: true)),
        notificationService: notifications,
        locale: const Locale('it'),
      );

      expect(notifications.scheduled, [
        {
          'hour': 19,
          'minute': 45,
          'title': it.notificationsDailyReminderTitle,
          'body': it.notificationsDailyReminderBody,
          'channelName': it.notificationsDailyReminderChannelName,
        },
      ]);
    });

    test('schedules nothing while reminders are off', () async {
      await rescheduleDailyReminder(
        configRepository: _Config(_config(enabled: false)),
        notificationService: notifications,
        locale: const Locale('it'),
      );

      expect(notifications.scheduled, isEmpty);
    });

    test('"System default" follows the device, as the UI does', () async {
      // An unshipped first preference falls through to the next one, the
      // same resolution MaterialApp makes for the UI.
      await rescheduleDailyReminder(
        configRepository: _Config(_config(enabled: true)),
        notificationService: notifications,
        locale: null,
        deviceLocales: const [Locale('fr'), Locale('de')],
      );

      expect(
        notifications.scheduled.single['body'],
        lookupS(const Locale('de')).notificationsDailyReminderBody,
      );
    });
  });

  group('LocaleProvider', () {
    test('reports a language change, including back to "System default"', () {
      final changes = <Locale?>[];
      final provider = LocaleProvider(
        locale: const Locale('en'),
        onChanged: changes.add,
      );
      expect(changes, isEmpty, reason: 'start-up schedules on its own');

      provider.updateLocale(const Locale('it'));
      provider.updateLocale(null);

      expect(changes, [const Locale('it'), null]);
    });
  });
}
