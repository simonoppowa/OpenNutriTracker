import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/utils/daily_reminder_scheduler.dart';
import 'package:opennutritracker/core/utils/locale_provider.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../helpers/fake_notification_platform.dart';

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

  /// Each value in here fails once when saved, as a full disk would, and
  /// leaves the saved config as it was.
  final failSaving = <bool>{};

  /// Each value in here is saved once and then fails, as a write that
  /// reached the shared box but not the profile box would.
  final failAfterSaving = <bool>{};

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (failSaving.remove(enabled)) throw StateError('config write failed');
    config = _config(enabled: enabled);
    if (failAfterSaving.remove(enabled)) {
      throw StateError('profile config write failed');
    }
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
  Future<bool> isDailyReminderPending() async => pending != null;

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
    // The real service replaces the pending reminder once the OS answers.
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
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('a cancel that fails leaves the switch on with its alarm', () async {
      final config = _Config(_config(enabled: true));
      final scheduler = DailyReminderScheduler(config, notifications);
      await scheduler.reschedule(locale: const Locale('en'));

      // "Off" is saved before the OS is told, and the OS call fails: the
      // alarm survives, so the switch goes back to reading on (#1389).
      notifications.failNextCancel = true;
      await expectLater(
        scheduler.setEnabled(false, locale: const Locale('en')),
        throwsStateError,
      );
      expect(config.config.notificationsEnabled, isTrue);
      expect(notifications.pending, isNotNull);
    });

    test('an alarm a failed undo left goes at the next refresh', () async {
      final config = _Config(_config(enabled: true));
      final scheduler = DailyReminderScheduler(config, notifications);
      await scheduler.reschedule(locale: const Locale('en'));

      // The cancel fails, and so does putting "on" back.
      notifications.failNextCancel = true;
      config.failSaving.add(true);
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

  group('a reschedule that fails keeps the alarm it was replacing (#1389)', () {
    late FakeNotificationPlatform platform;

    setUp(() => (platform = FakeNotificationPlatform()).install());
    tearDown(() => platform.uninstall());

    test('a refresh whose schedule throws leaves the previous alarm', () async {
      final scheduler = DailyReminderScheduler(
        _Config(_config(enabled: true)),
        NotificationService(),
      );
      await scheduler.refresh(locale: const Locale('en'));
      final english = platform.pending[0];
      expect(
        english?['title'],
        lookupS(const Locale('en')).notificationsDailyReminderTitle,
      );

      // A language change whose schedule the platform rejects.
      platform.failNextSchedule = true;
      await scheduler.refresh(locale: const Locale('it'));

      expect(
        platform.pending[0],
        english,
        reason: 'the reminder that was set must still fire',
      );
    });

    test('a refresh that succeeds replaces the alarm in place', () async {
      final scheduler = DailyReminderScheduler(
        _Config(_config(enabled: true)),
        NotificationService(),
      );
      await scheduler.refresh(locale: const Locale('en'));
      await scheduler.refresh(locale: const Locale('it'));

      expect(platform.pending.keys, [0]);
      expect(
        platform.pending[0]?['body'],
        lookupS(const Locale('it')).notificationsDailyReminderBody,
      );
    });

    test('saving "on" that fails takes back the alarm it set', () async {
      final config = _Config(_config(enabled: false));
      final scheduler = DailyReminderScheduler(config, NotificationService());

      config.failSaving.add(true);
      await expectLater(
        scheduler.setEnabled(true, locale: const Locale('en')),
        throwsStateError,
      );

      // The switch still reads off, so no alarm may fire either.
      expect(config.config.notificationsEnabled, isFalse);
      expect(platform.pending, isEmpty);
    });

    test('saving "on" that fails when it was on keeps the alarm', () async {
      final config = _Config(_config(enabled: true));
      final scheduler = DailyReminderScheduler(config, NotificationService());
      await scheduler.refresh(locale: const Locale('en'));

      config.failSaving.add(true);
      await expectLater(
        scheduler.setEnabled(true, locale: const Locale('en')),
        throwsStateError,
      );

      expect(config.config.notificationsEnabled, isTrue);
      expect(platform.pending.keys, [0]);
    });

    test('saving "on" that fails after it reads on keeps the alarm', () async {
      final config = _Config(_config(enabled: false));
      final scheduler = DailyReminderScheduler(config, NotificationService());

      config.failAfterSaving.add(true);
      await expectLater(
        scheduler.setEnabled(true, locale: const Locale('en')),
        throwsStateError,
      );

      // Settings reads on, so the alarm must still be there.
      expect(config.config.notificationsEnabled, isTrue);
      expect(platform.pending.keys, [0]);
    });

    test('saving "off" that fails after it reads off cancels', () async {
      final config = _Config(_config(enabled: true));
      final scheduler = DailyReminderScheduler(config, NotificationService());
      await scheduler.refresh(locale: const Locale('en'));

      config.failAfterSaving.add(false);
      await expectLater(
        scheduler.setEnabled(false, locale: const Locale('en')),
        throwsStateError,
      );

      expect(config.config.notificationsEnabled, isFalse);
      expect(platform.pending, isEmpty);
    });

    test('a cancel that fails after saving "off" puts "on" back', () async {
      final config = _Config(_config(enabled: true));
      final scheduler = DailyReminderScheduler(config, NotificationService());
      await scheduler.refresh(locale: const Locale('en'));

      platform.failNextCancel = true;
      await expectLater(
        scheduler.setEnabled(false, locale: const Locale('en')),
        throwsA(isA<PlatformException>()),
      );

      // The alarm is still set, so the switch must read on with it.
      expect(platform.pending.keys, [0]);
      expect(config.config.notificationsEnabled, isTrue);
    });

    test('a cancel that fails over a stale alarm puts "on" back', () async {
      // Reads off, but an earlier failure (a delete-all whose cancel
      // failed) left the alarm set.
      final config = _Config(_config(enabled: true));
      final scheduler = DailyReminderScheduler(config, NotificationService());
      await scheduler.refresh(locale: const Locale('en'));
      config.config = _config(enabled: false);

      platform.failNextCancel = true;
      await expectLater(
        scheduler.setEnabled(false, locale: const Locale('en')),
        throwsA(isA<PlatformException>()),
      );

      expect(platform.pending.keys, [0]);
      expect(config.config.notificationsEnabled, isTrue);
    });

    test('a cancel that fails with no alarm set leaves it off', () async {
      // A first run that leaves the reminder off must not turn it on.
      final config = _Config(_config(enabled: false));
      final scheduler = DailyReminderScheduler(config, NotificationService());

      platform.failNextCancel = true;
      await expectLater(
        scheduler.setEnabled(false, locale: const Locale('en')),
        throwsA(isA<PlatformException>()),
      );

      expect(platform.pending, isEmpty);
      expect(config.config.notificationsEnabled, isFalse);
    });

    test('turning reminders off still cancels the alarm', () async {
      final config = _Config(_config(enabled: true));
      final scheduler = DailyReminderScheduler(config, NotificationService());
      await scheduler.refresh(locale: const Locale('en'));

      await scheduler.setEnabled(false, locale: const Locale('en'));

      expect(platform.pending, isEmpty);
    });
  });

  group('a failed setEnabled leaves the switch and the alarm agreeing', () {
    late FakeNotificationPlatform platform;

    setUp(() => (platform = FakeNotificationPlatform()).install());
    tearDown(() => platform.uninstall());

    // Where the call starts from: the saved flag, and whether the OS holds
    // the reminder. "Off with an alarm" is what a delete-all whose cancel
    // failed leaves behind.
    const starts = {
      'off': (enabled: false, alarm: false),
      'off with a stale alarm': (enabled: false, alarm: true),
      'on': (enabled: true, alarm: true),
    };

    const unknowable = 'the cancel fails and the OS cannot be asked';

    // What goes wrong, singly and together.
    final failures = <String, void Function(_Config, bool enabled)>{
      'the schedule fails': (_, _) => platform.failNextSchedule = true,
      'the save fails': (c, enabled) => c.failSaving.add(enabled),
      'the save fails after it reads': (c, enabled) =>
          c.failAfterSaving.add(enabled),
      'the cancel fails': (_, _) => platform.failNextCancel = true,
      'the save and the cancel fail': (c, enabled) {
        c.failSaving.add(enabled);
        platform.failNextCancel = true;
      },
      'the save half-fails and the cancel fails': (c, enabled) {
        c.failAfterSaving.add(enabled);
        platform.failNextCancel = true;
      },
      unknowable: (_, _) {
        platform.failNextCancel = true;
        platform.failNextPendingQuery = true;
      },
    };

    for (final MapEntry(key: from, value: start) in starts.entries) {
      for (final enabled in [true, false]) {
        for (final MapEntry(key: what, value: inject) in failures.entries) {
          test('${enabled ? 'on' : 'off'} from $from, when $what', () async {
            final config = _Config(_config(enabled: start.alarm));
            final scheduler = DailyReminderScheduler(
              config,
              NotificationService(),
            );
            await scheduler.refresh(locale: const Locale('en'));
            config.config = _config(enabled: start.enabled);
            expect(platform.pending.isNotEmpty, start.alarm);

            inject(config, enabled);
            try {
              await scheduler.setEnabled(enabled, locale: const Locale('en'));
            } catch (_) {}

            if (start.alarm &&
                !start.enabled &&
                !enabled &&
                what == unknowable) {
              // Nothing says an alarm is set, and the OS can neither cancel
              // it nor say whether it holds one: the user's "off" stands,
              // and the next refresh, which cancels while off, removes it.
              expect(config.config.notificationsEnabled, isFalse);
              await scheduler.refresh(locale: const Locale('en'));
              expect(platform.pending, isEmpty);
              return;
            }
            expect(
              config.config.notificationsEnabled,
              platform.pending.isNotEmpty,
              reason: 'Settings must read what the OS will fire',
            );
            if (!start.enabled && !start.alarm && !enabled) {
              expect(
                config.config.notificationsEnabled,
                isFalse,
                reason: 'a reminder the user never had must not switch on',
              );
            }
          });
        }
      }
    }
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
