import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/app_locale_service.dart';

// #626: the Kotlin side of this channel is what keeps Android's per-app
// language picker agreeing with the app's own. These pin the shape of the
// calls it receives, and the failure behaviour on a platform that has no
// native side listening at all.

const _channel = MethodChannel('com.opennutritracker/locale');

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

  group('AppLocaleService', () {
    test('reads the language the OS holds', () async {
      handleWith((_) async => 'pl');

      expect(await AppLocaleService.getApplicationLocale(), 'pl');
      expect(calls.single.method, 'getApplicationLocale');
    });

    test('sends the chosen language under a tag argument', () async {
      handleWith(null);

      await AppLocaleService.setApplicationLocale('de');

      expect(calls.single.method, 'setApplicationLocale');
      expect(calls.single.arguments, {'tag': 'de'});
    });

    // "System default" in our picker means "stop overriding", which the
    // native side reads as a null tag and turns into an empty LocaleList.
    test('sends null to clear the override', () async {
      handleWith(null);

      await AppLocaleService.setApplicationLocale(null);

      expect(calls.single.arguments, {'tag': null});
    });

    test('a platform failure does not escape', () async {
      handleWith((_) => throw PlatformException(code: 'unavailable'));

      await expectLater(AppLocaleService.getApplicationLocale(), completion(isNull));
      await expectLater(AppLocaleService.setApplicationLocale('de'), completes);
    });
  });

  // Nothing on the other side of the channel is the normal case on iOS, on
  // desktop, and in any widget test that pumps the settings screen. Failing
  // there would break a screen someone opened to fix their language.
  test('a missing native side is not an error', () async {
    expect(await AppLocaleService.getApplicationLocale(), isNull);
    await expectLater(AppLocaleService.setApplicationLocale('de'), completes);
  });
}
