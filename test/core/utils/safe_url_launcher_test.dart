import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/safe_url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

/// url_launcher's platform channel, mocked as in the onboarding page test
/// (the platform-interface package is only a transitive dependency).
const _channel = MethodChannel('plugins.flutter.io/url_launcher');

void mockLauncher(Future<Object?> Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('returns true when the link opens', () async {
    final launched = <String>[];
    mockLauncher((call) async {
      launched.add((call.arguments as Map<Object?, Object?>)['url'] as String);
      return true;
    });

    expect(await tryLaunchExternalUrl('https://example.org/a'), isTrue);
    expect(launched, ['https://example.org/a']);
  });

  test('returns false when the launcher reports it could not open', () async {
    mockLauncher((call) async => false);

    expect(await tryLaunchExternalUrl('https://example.org'), isFalse);
  });

  test('ACTIVITY_NOT_FOUND is swallowed, not thrown', () async {
    mockLauncher((call) async {
      throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
    });

    expect(await tryLaunchExternalUrl('https://example.org'), isFalse);
  });

  test('iOS argument_error is swallowed, not thrown', () async {
    mockLauncher((call) async {
      throw PlatformException(
        code: 'argument_error',
        message: 'Unable to parse URL',
      );
    });

    expect(await tryLaunchExternalUrl('http://bad host'), isFalse);
  });

  test('a string Uri cannot parse never reaches the platform', () async {
    var called = false;
    mockLauncher((call) async {
      called = true;
      return true;
    });

    expect(await tryLaunchExternalUrl('http://[::1'), isFalse);
    expect(called, isFalse);
  });

  test('opens in an external application by default', () async {
    String? mode;
    mockLauncher((call) async {
      mode = (call.arguments as Map<Object?, Object?>)['useSafariVC']
          ?.toString();
      return true;
    });

    expect(await tryLaunchExternalUrl('https://example.org'), isTrue);
    expect(mode, 'false');
  });

  test('a custom mode reaches the platform, and its failure is swallowed',
      () async {
    final modes = <String>[];
    mockLauncher((call) async {
      modes.add(call.method);
      throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
    });

    expect(
      await tryLaunchExternalUrl(
        'https://example.org',
        mode: LaunchMode.inAppBrowserView,
      ),
      isFalse,
    );
    expect(modes, ['launch']);
  });
}
