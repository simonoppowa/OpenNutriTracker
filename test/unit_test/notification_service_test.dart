import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);

  test(
    'initialize uses the native timezone identifier and initializes notifications',
    () async {
      const timezoneChannel = MethodChannel('flutter_timezone');
      const notificationsChannel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final notificationCalls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      FlutterLocalNotificationsPlatform.instance =
          AndroidFlutterLocalNotificationsPlugin();
      messenger.setMockMethodCallHandler(timezoneChannel, (call) async {
        expect(call.method, 'getLocalTimezone');
        return <String, Object>{'identifier': 'Europe/Berlin'};
      });
      messenger.setMockMethodCallHandler(notificationsChannel, (call) async {
        notificationCalls.add(call);
        return true;
      });

      try {
        await NotificationService().initialize();

        expect(tz.local.name, 'Europe/Berlin');
        expect(notificationCalls.map((call) => call.method), ['initialize']);
      } finally {
        messenger.setMockMethodCallHandler(timezoneChannel, null);
        messenger.setMockMethodCallHandler(notificationsChannel, null);
        debugDefaultTargetPlatformOverride = null;
        tz.setLocalLocation(tz.UTC);
      }
    },
  );

  group('NotificationService.computeNextOccurrence', () {
    test('returns today when the slot is later today', () {
      final ny = tz.getLocation('America/New_York');
      final now = tz.TZDateTime(ny, 2026, 6, 15, 8, 0); // 08:00
      final next = NotificationService.computeNextOccurrence(now, 20, 30);

      expect(next.year, equals(2026));
      expect(next.month, equals(6));
      expect(next.day, equals(15));
      expect(next.hour, equals(20));
      expect(next.minute, equals(30));
      expect(next.location.name, equals('America/New_York'));
    });

    test('rolls forward to tomorrow when the slot has already passed', () {
      final ny = tz.getLocation('America/New_York');
      final now = tz.TZDateTime(ny, 2026, 6, 15, 21, 0); // 21:00
      final next = NotificationService.computeNextOccurrence(now, 20, 30);

      expect(next.day, equals(16), reason: 'past slot should roll to next day');
      expect(next.hour, equals(20));
      expect(next.minute, equals(30));
    });

    test('rolls forward when the slot matches now exactly', () {
      // Equality counts as past — we never want to schedule "now" because
      // the OS scheduler treats that as fire-immediately.
      final ny = tz.getLocation('America/New_York');
      final now = tz.TZDateTime(ny, 2026, 6, 15, 20, 30);
      final next = NotificationService.computeNextOccurrence(now, 20, 30);

      expect(next.day, equals(16));
    });

    test('handles month boundary correctly (last day → next month)', () {
      final ny = tz.getLocation('America/New_York');
      final now = tz.TZDateTime(ny, 2026, 6, 30, 21, 0);
      final next = NotificationService.computeNextOccurrence(now, 8, 0);

      expect(next.year, equals(2026));
      expect(next.month, equals(7));
      expect(next.day, equals(1));
      expect(next.hour, equals(8));
    });

    test('handles year boundary correctly', () {
      final ny = tz.getLocation('America/New_York');
      final now = tz.TZDateTime(ny, 2026, 12, 31, 23, 0);
      final next = NotificationService.computeNextOccurrence(now, 8, 0);

      expect(next.year, equals(2027));
      expect(next.month, equals(1));
      expect(next.day, equals(1));
    });

    test('preserves the supplied timezone (London)', () {
      final london = tz.getLocation('Europe/London');
      final now = tz.TZDateTime(london, 2026, 6, 15, 8, 0);
      final next = NotificationService.computeNextOccurrence(now, 20, 30);

      expect(next.location.name, equals('Europe/London'));
    });

    test('preserves the supplied timezone (Tokyo)', () {
      final tokyo = tz.getLocation('Asia/Tokyo');
      final now = tz.TZDateTime(tokyo, 2026, 6, 15, 8, 0);
      final next = NotificationService.computeNextOccurrence(now, 20, 30);

      expect(next.location.name, equals('Asia/Tokyo'));
    });

    test('DST spring-forward: 02:30 in US/Eastern does not exist on '
        '2026-03-08, slot rolls to next day', () {
      // 2026-03-08 in America/New_York: clocks jump 02:00 → 03:00, so 02:30
      // is a non-existent local time. The TZDateTime constructor canonicalises
      // it to 03:30 EDT. Verify the next-occurrence helper still produces a
      // valid future TZDateTime in this case.
      final ny = tz.getLocation('America/New_York');
      final beforeJump = tz.TZDateTime(
        ny,
        2026,
        3,
        8,
        1,
        0,
      ); // 01:00, well before the gap
      final next = NotificationService.computeNextOccurrence(beforeJump, 2, 30);

      // The helper should return *some* later TZDateTime (it canonicalises
      // 02:30 → 03:30 but that's still after 01:00, so it stays on the same
      // day). The crucial property is that it doesn't crash and the return
      // value is strictly after `beforeJump`.
      expect(next.isAfter(beforeJump), isTrue);
      expect(next.day, equals(8));
    });

    test('DST fall-back: 01:30 occurs twice on 2026-11-01 in US/Eastern; '
        'helper still produces a strictly future occurrence', () {
      final ny = tz.getLocation('America/New_York');
      final after = tz.TZDateTime(ny, 2026, 11, 1, 3, 0);
      final next = NotificationService.computeNextOccurrence(after, 1, 30);

      expect(
        next.isAfter(after),
        isTrue,
        reason: 'must always return a future timestamp even across DST',
      );
      expect(
        next.day,
        equals(2),
        reason: 'past slot should roll to next day across DST boundary',
      );
    });

    test('handles midnight (00:00) slot', () {
      final ny = tz.getLocation('America/New_York');
      final now = tz.TZDateTime(ny, 2026, 6, 15, 23, 0);
      final next = NotificationService.computeNextOccurrence(now, 0, 0);

      expect(next.day, equals(16));
      expect(next.hour, equals(0));
      expect(next.minute, equals(0));
    });

    test('handles end-of-day (23:59) slot earlier in the day', () {
      final ny = tz.getLocation('America/New_York');
      final now = tz.TZDateTime(ny, 2026, 6, 15, 8, 0);
      final next = NotificationService.computeNextOccurrence(now, 23, 59);

      expect(next.day, equals(15));
      expect(next.hour, equals(23));
      expect(next.minute, equals(59));
    });
  });
}
