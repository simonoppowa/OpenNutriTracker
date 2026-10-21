import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/features/reminders/data/reminder_scheduler.dart';
import 'package:opennutritracker/features/reminders/data/reminder_store.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';
import 'package:opennutritracker/features/reminders/domain/reminder_planner.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/test_l10n.dart';

class _Store implements ReminderStore {
  List<Reminder> reminders;
  _Store(this.reminders);

  @override
  Future<List<Reminder>> load() async => reminders;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifications extends NotificationService {
  final log = <String>[];
  final cancelled = <int>{};
  var legacyCancelled = false;
  final scheduled =
      <
        ({int id, int weekday, int hour, int minute, String title, String body})
      >[];

  final once = <({int id, DateTime at, String title})>[];

  @override
  Future<void> cancelDailyReminder() async => legacyCancelled = true;

  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async => once.add((id: id, at: at, title: title));

  @override
  Future<void> cancelIds(Iterable<int> ids) async {
    log.add('cancel');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    cancelled.addAll(ids);
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    log.add('schedule');
    await Future<void>.delayed(const Duration(milliseconds: 1));
    scheduled.add((
      id: id,
      weekday: weekday,
      hour: hour,
      minute: minute,
      title: title,
      body: body,
    ));
  }
}

Reminder _reminder(
  ReminderType type,
  Set<int> weekdays, {
  bool enabled = true,
}) => Reminder(
  id: type.name,
  type: type,
  hour: 7,
  minute: 15,
  weekdays: weekdays,
  enabled: enabled,
);

void main() {
  tzdata.initializeTimeZones();

  group('next weekday', () {
    final berlin = tz.getLocation('Europe/Berlin');

    test('later the same day when the time is still ahead', () {
      final now = tz.TZDateTime(berlin, 2026, 10, 21, 6);

      final next = NotificationService.computeNextWeekday(
        now,
        DateTime.wednesday,
        7,
        15,
      );

      expect(next, tz.TZDateTime(berlin, 2026, 10, 21, 7, 15));
    });

    test('next week once the time has passed', () {
      final now = tz.TZDateTime(berlin, 2026, 10, 21, 8);

      final next = NotificationService.computeNextWeekday(
        now,
        DateTime.wednesday,
        7,
        15,
      );

      expect(next, tz.TZDateTime(berlin, 2026, 10, 28, 7, 15));
    });

    test('keeps the wall time across the clock change', () {
      final now = tz.TZDateTime(berlin, 2026, 10, 21, 8);

      final next = NotificationService.computeNextWeekday(
        now,
        DateTime.monday,
        7,
        15,
      );

      expect(next, tz.TZDateTime(berlin, 2026, 10, 26, 7, 15));
      expect(next.hour, 7);
    });
  });

  test(
    'a sync clears every reminder slot and the old daily reminder',
    () async {
      final notifications = _Notifications();

      await ReminderScheduler(_Store(const []), notifications).sync(l10nEn);

      expect(notifications.legacyCancelled, isTrue);
      expect(notifications.cancelled, reminderNotificationIds.toSet());
      expect(notifications.scheduled, isEmpty);
    },
  );

  test('schedules each chosen weekday with the texts of its type', () async {
    final notifications = _Notifications();

    await ReminderScheduler(
      _Store([
        _reminder(ReminderType.water, {1, 5}),
        _reminder(ReminderType.weigh, {2}, enabled: false),
      ]),
      notifications,
    ).sync(l10nEn);

    expect(notifications.scheduled.map((n) => n.weekday), [1, 5]);
    expect(notifications.scheduled.first.hour, 7);
    expect(notifications.scheduled.first.minute, 15);
    expect(notifications.scheduled.first.title, l10nEn.reminderWaterTitle);
    expect(notifications.scheduled.first.body, l10nEn.reminderWaterBody);
  });

  test('every type has its own text', () {
    final texts = {
      for (final type in ReminderType.values) reminderTexts(type, l10nEn),
    };

    expect(texts, hasLength(ReminderType.values.length));
  });

  test('overlapping syncs run one after the other', () async {
    final notifications = _Notifications();
    final scheduler = ReminderScheduler(
      _Store([
        _reminder(ReminderType.water, {1}),
      ]),
      notifications,
    );

    await Future.wait([scheduler.sync(l10nEn), scheduler.sync(l10nEn)]);

    expect(notifications.log, ['cancel', 'schedule', 'cancel', 'schedule']);
  });

  test(
    'meal reminders go out once per day, today left out when logged',
    () async {
      final notifications = _Notifications();

      await ReminderScheduler(
        _Store([_reminder(ReminderType.lunch, Reminder.everyDay)]),
        notifications,
        now: () => DateTime(2026, 10, 21, 6),
        loggedToday: () async => {ReminderType.lunch},
      ).sync(l10nEn);

      expect(notifications.scheduled, isEmpty);
      expect(notifications.once.first.at, DateTime(2026, 10, 22, 7, 15));
      expect(notifications.once, hasLength(6));
      expect(notifications.once.first.title, l10nEn.reminderLunchTitle);
    },
  );
}
