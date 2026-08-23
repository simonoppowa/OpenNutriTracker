import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/app_locale_sync.dart';

// #626: the app gained a second front door to its language setting when
// android:localeConfig started surfacing Android's own per-app picker. These
// cover which door wins, so the two can never quietly disagree and leave
// someone changing a setting that does nothing.

const _supported = [
  Locale('en'),
  Locale('de'),
  Locale('cs'),
  Locale('it'),
  Locale('pl'),
  Locale('sk'),
  Locale('tr'),
  Locale('uk'),
  Locale('zh'),
];

class _Recorder {
  final persisted = <String?>[];
  final pushed = <String?>[];

  Future<void> persist(String? code) async => persisted.add(code);
  Future<void> push(String? tag) async => pushed.add(tag);
}

Future<String?> _reconcile(
  _Recorder recorder, {
  String? saved,
  String? system,
}) =>
    reconcileAppLocale(
      savedLocaleCode: saved,
      systemLocaleTag: system,
      supportedLocales: _supported,
      persistSelectedLocale: recorder.persist,
      pushToSystem: recorder.push,
    );

void main() {
  group('reconcileAppLocale', () {
    test('the system override wins and is saved', () async {
      final recorder = _Recorder();

      final result =
          await _reconcile(recorder, saved: 'de', system: 'pl');

      expect(result, 'pl');
      expect(recorder.persisted, ['pl'],
          reason: 'Settings should show what the OS picker holds');
      expect(recorder.pushed, isEmpty,
          reason: 'the OS already has this value; writing it back is noise');
    });

    test('an override that already matches is not written again', () async {
      final recorder = _Recorder();

      final result =
          await _reconcile(recorder, saved: 'de', system: 'de');

      expect(result, 'de');
      expect(recorder.persisted, isEmpty);
      expect(recorder.pushed, isEmpty);
    });

    // The upgrade path: someone chose a language in the app long before this
    // wiring existed, so the OS has no override yet. Their choice is what
    // they meant, and it seeds the system rather than being overwritten by it.
    test('with no override, a saved choice seeds the system', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: 'uk', system: null);

      expect(result, 'uk');
      expect(recorder.pushed, ['uk']);
      expect(recorder.persisted, isEmpty);
    });

    test('with nothing on either side, nothing happens', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: null, system: null);

      expect(result, isNull);
      expect(recorder.pushed, isEmpty);
      expect(recorder.persisted, isEmpty);
    });

    test('a region-qualified tag resolves to the language we ship', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: null, system: 'de-DE');

      expect(result, 'de');
      expect(recorder.persisted, ['de']);
    });

    test('a script-and-region tag resolves the same way', () async {
      final recorder = _Recorder();

      final result =
          await _reconcile(recorder, saved: null, system: 'zh-Hans-CN');

      expect(result, 'zh');
      expect(recorder.persisted, ['zh']);
    });

    // A tag we do not ship must not strand anyone in a half-translated app.
    test('an unshipped language is treated as no override', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: 'de', system: 'ja');

      expect(result, 'de');
      expect(recorder.persisted, isEmpty);
      expect(recorder.pushed, ['de'],
          reason: 'the OS holds a language we cannot render; correct it');
    });

    test('an empty tag is treated as no override', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: 'it', system: '');

      expect(result, 'it');
      expect(recorder.pushed, ['it']);
    });
  });

  group('supportedLanguageCode', () {
    test('maps supported tags onto their language subtag', () {
      expect(supportedLanguageCode('en', _supported), 'en');
      expect(supportedLanguageCode('pl-PL', _supported), 'pl');
      expect(supportedLanguageCode('CS', _supported), 'cs');
      expect(supportedLanguageCode('uk_UA', _supported), 'uk');
    });

    test('rejects absent, empty and unshipped tags', () {
      expect(supportedLanguageCode(null, _supported), isNull);
      expect(supportedLanguageCode('', _supported), isNull);
      expect(supportedLanguageCode('ja-JP', _supported), isNull);
    });
  });
}
