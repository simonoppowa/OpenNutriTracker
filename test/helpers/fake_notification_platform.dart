import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

/// Stands in for the native side of flutter_local_notifications on Android,
/// so a real `NotificationService` can run in a unit test.
///
/// It keeps pending notifications by id, the way the plugin does: a
/// `zonedSchedule` with an id that is already pending replaces it (the
/// alarm's `PendingIntent` is keyed by that id, and the plugin's cache drops
/// the old entry), and a failed one leaves what was pending untouched.
class FakeNotificationPlatform {
  static const _notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  static const _timezone = MethodChannel('flutter_timezone');

  /// What would fire: the arguments of each pending schedule, by id.
  final pending = <int, Map<Object?, Object?>>{};

  /// When set, the next `zonedSchedule` fails, as a platform error would.
  bool failNextSchedule = false;

  /// When set, the next `cancel` fails and what was pending stays.
  bool failNextCancel = false;

  /// When set, the next query for pending notifications fails.
  bool failNextPendingQuery = false;

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void install() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    _messenger.setMockMethodCallHandler(
      _timezone,
      (_) async => <String, Object>{'identifier': 'Europe/Berlin'},
    );
    _messenger.setMockMethodCallHandler(_notifications, (call) async {
      switch (call.method) {
        case 'zonedSchedule':
          if (failNextSchedule) {
            failNextSchedule = false;
            throw PlatformException(code: 'schedule_failed');
          }
          final arguments = call.arguments as Map<Object?, Object?>;
          pending[arguments['id']! as int] = arguments;
        case 'cancel':
          if (failNextCancel) {
            failNextCancel = false;
            throw PlatformException(code: 'cancel_failed');
          }
          final arguments = call.arguments as Map<Object?, Object?>;
          pending.remove(arguments['id']);
        case 'cancelAll':
          pending.clear();
        case 'pendingNotificationRequests':
          if (failNextPendingQuery) {
            failNextPendingQuery = false;
            throw PlatformException(code: 'query_failed');
          }
          return [
            for (final arguments in pending.values)
              {
                'id': arguments['id'],
                'title': arguments['title'],
                'body': arguments['body'],
                'payload': arguments['payload'],
              },
          ];
      }
      return true;
    });
  }

  void uninstall() {
    _messenger.setMockMethodCallHandler(_timezone, null);
    _messenger.setMockMethodCallHandler(_notifications, null);
    debugDefaultTargetPlatformOverride = null;
    tz.setLocalLocation(tz.UTC);
  }
}
