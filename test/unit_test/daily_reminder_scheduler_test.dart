import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/utils/daily_reminder_scheduler.dart';
import 'package:opennutritracker/core/utils/locale_provider.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _Config implements ConfigRepository {
  _Config(this.config);

  ConfigEntity config;

  /// When set, the next [getConfig] reads the config at once but holds the
  /// answer until this completes — a refresh caught mid-flight.
  Completer<void>? gate;

  @override
  Future<ConfigEntity> getConfig() async {
    final read = config;
    final pending = gate;
    gate = null;
    if (pending != null) await pending.future;
    return read;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    config = _config(enabled: enabled);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingNotificationService extends NotificationService {
  final scheduled = <Map<String, Object>>[];

  /// What the OS would hold: the last schedule, unless cancelled since.
  Map<String, Object>? pending;

  /// When set, the next [cancelDailyReminder] fails and the alarm stays.
  bool failNextCancel = false;

  /// When set, the next [scheduleDailyReminder] fails before the OS has it.
  bool failNextSchedule = false;

  /// When set, every [initialize] fails, as a broken plugin would.
  bool failInitialize = false;

  @override
  Future<void> initialize() async {
    if (failInitialize) throw StateError('timezone lookup failed');
  }

  @override
  Future<void> cancelDailyReminder() async {
    if (failNextCancel) {
      failNextCancel = false;
      throw StateError('notification plugin unavailable');
    }
    pending = null;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    if (failNextSchedule) {
      failNextSchedule = false;
      throw StateError('exact alarms not permitted');
    }
    // The real service cancels, then schedules, with a gap between.
    pending = null;
    await Future<void>.delayed(Duration.zero);
    scheduled.add(
      pending = {
        'hour': hour,
        'minute': minute,
        'title': title,
        'body': body,
        'channelName': channelName,
      },
    );
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

      await DailyReminderScheduler(
        _Config(_config(enabled: true)),
        notifications,
      ).reschedule(locale: const Locale('it'));

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
      await DailyReminderScheduler(
        _Config(_config(enabled: false)),
        notifications,
      ).reschedule(locale: const Locale('it'));

      expect(notifications.scheduled, isEmpty);
    });

    test('"System default" follows the device, as the UI does', () async {
      // An unshipped first preference falls through to the next one, the
      // same resolution MaterialApp makes for the UI.
      await DailyReminderScheduler(
        _Config(_config(enabled: true)),
        notifications,
      ).reschedule(
        locale: null,
        deviceLocales: const [Locale('fr'), Locale('de')],
      );

      expect(
        notifications.scheduled.single['body'],
        lookupS(const Locale('de')).notificationsDailyReminderBody,
      );
    });

    test('turning reminders off during a refresh leaves none behind', () async {
      final config = _Config(_config(enabled: true));
      final scheduler = DailyReminderScheduler(config, notifications);

      // The refresh has read "enabled" and is still on its way to the OS
      // when Settings turns reminders off.
      final gate = config.gate = Completer<void>();
      final refresh = scheduler.reschedule(locale: const Locale('it'));
      await pumpEventQueue();
      final disable = scheduler.setEnabled(false, locale: const Locale('en'));
      await pumpEventQueue();
      gate.complete();
      await Future.wait([refresh, disable]);

      expect(config.config.notificationsEnabled, isFalse);
      expect(notifications.pending, isNull);
    });

    test('a refresh after turning reminders off schedules nothing', () async {
      final config = _Config(_config(enabled: true));
      final scheduler = DailyReminderScheduler(config, notifications);

      await scheduler.setEnabled(false, locale: const Locale('en'));
      await scheduler.reschedule(locale: const Locale('it'));

      expect(notifications.pending, isNull);
    });

    test('a cancel that failed is retried by the next refresh', () async {
      final config = _Config(_config(enabled: true));
      final scheduler = DailyReminderScheduler(config, notifications);
      await scheduler.reschedule(locale: const Locale('en'));

      // "Off" is saved before the OS is told, and the OS call fails: the
      // alarm survives a switch that now reads off.
      notifications.failNextCancel = true;
      await expectLater(
        scheduler.setEnabled(false, locale: const Locale('en')),
        throwsStateError,
      );
      expect(config.config.notificationsEnabled, isFalse);
      expect(notifications.pending, isNotNull);

      // The next start-up or language refresh is where that gets put right.
      await scheduler.reschedule(locale: const Locale('en'));

      expect(notifications.pending, isNull);
    });

    test('a schedule that failed leaves reminders off', () async {
      final config = _Config(_config(enabled: false));
      final scheduler = DailyReminderScheduler(config, notifications);

      notifications.failNextSchedule = true;
      await expectLater(
        scheduler.setEnabled(true, locale: const Locale('en')),
        throwsStateError,
      );

      // No alarm, so the switch must not read on either.
      expect(notifications.pending, isNull);
      expect(config.config.notificationsEnabled, isFalse);

      await scheduler.setEnabled(true, locale: const Locale('en'));

      expect(notifications.pending, isNotNull);
      expect(config.config.notificationsEnabled, isTrue);
    });

    test(
      'a refresh that fails is logged, not thrown, and the next one runs',
      () async {
        final config = _Config(_config(enabled: false));
        final scheduler = DailyReminderScheduler(config, notifications);
        final records = <LogRecord>[];
        final sub = Logger.root.onRecord.listen(records.add);
        addTearDown(sub.cancel);

        // Start-up with reminders off still cancels, and a broken plugin
        // must not keep the app from opening.
        notifications.failNextCancel = true;
        await scheduler.refresh(locale: const Locale('en'));
        notifications.failInitialize = true;
        config.config = _config(enabled: true);
        await scheduler.refresh(locale: const Locale('en'));

        expect(records.where((r) => r.level == Level.WARNING), hasLength(2));

        notifications.failInitialize = false;
        await scheduler.refresh(locale: const Locale('en'));

        expect(notifications.pending, isNotNull);
      },
    );

    test('back to "System default" ends in the new device language', () async {
      // Android 13+: Settings starts clearing the per-app override without
      // waiting, so the first refresh still sees the old device list; the
      // corrected list arrives later as a platform locale event.
      final scheduler = DailyReminderScheduler(
        _Config(_config(enabled: true)),
        notifications,
      );
      var deviceLocales = const [Locale('it')];
      final refreshes = <Future<void>>[];
      final provider = LocaleProvider(
        locale: const Locale('it'),
        onChanged: (locale) => refreshes.add(
          scheduler.reschedule(locale: locale, deviceLocales: deviceLocales),
        ),
      );

      provider.updateLocale(null);
      deviceLocales = const [Locale('de')];
      provider.systemLocalesChanged();
      await Future.wait(refreshes);

      expect(
        notifications.pending?['body'],
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

    test('reports a device language change only while following it', () {
      final changes = <Locale?>[];
      final provider = LocaleProvider(locale: null, onChanged: changes.add);

      provider.systemLocalesChanged();
      provider.updateLocale(const Locale('it'));
      provider.systemLocalesChanged();

      expect(changes, [null, const Locale('it')]);
    });
  });
}
