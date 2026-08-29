import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/health_rationale_service.dart';

// #927: Health Connect asks the app to explain what it wants health data for
// by starting it with one of two intents. The manifest declared both and
// `MainActivity` ignored them, so the question was answered by dropping the
// user on the diary. The channel tests pin the Dart contract; the manifest
// tests pin the halves that live outside Dart and cannot fail a compile.

const _channel = MethodChannel('com.opennutritracker/health_rationale');

/// The two actions, spelled exactly as Android delivers them. Duplicated here
/// on purpose — a test that read them from the source it checks would agree
/// with any typo.
const _rationaleAction = 'androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE';
const _permissionUsageAction = 'android.intent.action.VIEW_PERMISSION_USAGE';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void handleWith(Future<Object?>? Function(MethodCall)? handler) {
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return handler == null ? null : await handler(call);
    });
  }

  setUp(calls.clear);
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  group('HealthRationaleService', () {
    test('reports a pending request', () async {
      handleWith((_) async => true);

      expect(await HealthRationaleService.consumePendingRequest(), isTrue);
      expect(calls.single.method, 'consumePendingRequest');
    });

    test('reports nothing pending on an ordinary launch', () async {
      handleWith((_) async => false);

      expect(await HealthRationaleService.consumePendingRequest(), isFalse);
    });

    // A null would mean the platform answered without a value. Opening the
    // screen on that would put people on a settings page they never asked
    // for, so the ambiguous answer has to read as "no".
    test('treats a null answer as nothing pending', () async {
      handleWith((_) async => null);

      expect(await HealthRationaleService.consumePendingRequest(), isFalse);
    });

    // iOS, desktop and every widget test: no native side is registered. The
    // call must answer rather than throw into whatever is driving it.
    test('answers no on a platform with no native side', () async {
      expect(await HealthRationaleService.consumePendingRequest(), isFalse);
    });

    test('answers no when the platform side fails', () async {
      handleWith((_) async => throw PlatformException(code: 'error'));

      expect(await HealthRationaleService.consumePendingRequest(), isFalse);
    });
  });

  // These are the checks that would have caught the original bug: the manifest
  // was right and unread, which no Dart test could have noticed.
  group('the Android side is wired to answer', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/opennutritracker/ont/'
      'opennutritracker/MainActivity.kt',
    ).readAsStringSync();

    test('the manifest offers both ways in', () {
      expect(manifest, contains(_rationaleAction));
      expect(manifest, contains(_permissionUsageAction));
    });

    test('the activity reads both actions the manifest advertises', () {
      // Declaring a filter the activity does not handle is precisely the bug
      // in #927: the user reaches the app and no question gets answered.
      expect(
        activity,
        contains(_rationaleAction),
        reason: 'manifest advertises the rationale action; MainActivity must '
            'recognise it or the user lands on the diary',
      );
      expect(
        activity,
        contains(_permissionUsageAction),
        reason: 'manifest advertises the permission-usage action; '
            'MainActivity must recognise it',
      );
    });

    // singleTop means a running process is handed the intent through
    // onNewIntent. Reading only the launching intent works once per process
    // and then silently stops, which is a worse failure than the original
    // because it passes a first manual test.
    test('the activity survives being reached twice', () {
      expect(
        manifest,
        contains('android:launchMode="singleTop"'),
        reason: 'the onNewIntent override below is only needed while this '
            'holds — if the launch mode changed, re-check the activity',
      );
      expect(activity, contains('onNewIntent'));
    });

    // Without the permission guard any app on the device could open this
    // activity; Google's own snippet carries it.
    test('the permission-usage alias stays guarded', () {
      expect(
        manifest,
        contains(
          'android:permission="android.permission.START_VIEW_PERMISSION_USAGE"',
        ),
      );
    });
  });
}
