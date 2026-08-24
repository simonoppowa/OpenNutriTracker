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
  int seededMarks = 0;

  Future<void> persist(String? code) async => persisted.add(code);
  Future<void> push(String? tag) async => pushed.add(tag);
  Future<void> markSeeded() async => seededMarks++;
}

Future<String?> _reconcile(
  _Recorder recorder, {
  String? saved,
  String? system,
  bool seeded = false,
  bool readFailed = false,
}) => reconcileAppLocale(
  savedLocaleCode: saved,
  systemLocaleTag: system,
  systemTagReadFailed: readFailed,
  localeSyncSeeded: seeded,
  supportedLocales: _supported,
  persistSelectedLocale: recorder.persist,
  pushToSystem: recorder.push,
  markLocaleSyncSeeded: recorder.markSeeded,
);

void main() {
  group('reconcileAppLocale', () {
    test('the system override wins and is saved', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: 'de', system: 'pl');

      expect(result, 'pl');
      expect(
        recorder.persisted,
        ['pl'],
        reason: 'Settings should show what the OS picker holds',
      );
      expect(
        recorder.pushed,
        isEmpty,
        reason: 'the OS already has this value; writing it back is noise',
      );
      expect(
        recorder.seededMarks,
        1,
        reason: 'an OS value existing means both sides are already met',
      );
    });

    test('an override that already matches is not written again', () async {
      final recorder = _Recorder();

      final result = await _reconcile(
        recorder,
        saved: 'de',
        system: 'de',
        seeded: true,
      );

      expect(result, 'de');
      expect(recorder.persisted, isEmpty);
      expect(recorder.pushed, isEmpty);
      expect(
        recorder.seededMarks,
        0,
        reason: 'already recorded; another config write is noise',
      );
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
      expect(
        recorder.seededMarks,
        0,
        reason:
            'seeded means the OS was SEEN holding a value; recording it on '
            'the attempt would turn a platform that cannot hold one — where '
            'this branch repeats forever — into a user who cleared it',
      );
    });

    // The observation that completes the migration: the pushed value comes
    // back on the next read, which is when seeded may be recorded. On a
    // platform with no per-app override the push no-ops, this never fires,
    // and the saved choice survives every launch.
    test('a saved choice on an override-less platform survives', () async {
      final recorder = _Recorder();

      await _reconcile(recorder, saved: 'uk', system: null);
      final result = await _reconcile(recorder, saved: 'uk', system: null);

      expect(result, 'uk');
      expect(
        recorder.persisted,
        isEmpty,
        reason: 'nothing may clear a choice the user never cleared',
      );
      expect(recorder.seededMarks, 0);
    });

    // The other reading of "no override": it was seeded before, so its
    // absence now is the user having picked System default in Android's
    // picker. Re-pushing the saved choice would undo their action; instead
    // the saved choice follows the OS and is cleared.
    test('once seeded, a cleared override clears the saved choice', () async {
      final recorder = _Recorder();

      final result = await _reconcile(
        recorder,
        saved: 'uk',
        system: null,
        seeded: true,
      );

      expect(result, isNull);
      expect(
        recorder.pushed,
        isEmpty,
        reason: 'pushing the old choice back is the bug this exists for',
      );
      expect(
        recorder.persisted,
        [null],
        reason: 'System default means follow the system in both pickers',
      );
      expect(recorder.seededMarks, 0);
    });

    test('with nothing on either side, nothing happens', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: null, system: null);

      expect(result, isNull);
      expect(recorder.pushed, isEmpty);
      expect(recorder.persisted, isEmpty);
      expect(recorder.seededMarks, 0);
    });

    test('a region-qualified tag resolves to the language we ship', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: null, system: 'de-DE');

      expect(result, 'de');
      expect(recorder.persisted, ['de']);
    });

    test('a script-and-region tag resolves the same way', () async {
      final recorder = _Recorder();

      final result = await _reconcile(
        recorder,
        saved: null,
        system: 'zh-Hans-CN',
      );

      expect(result, 'zh');
      expect(recorder.persisted, ['zh']);
    });

    // A tag we do not ship must not strand anyone in a half-translated app —
    // but it is still the user's explicit OS-level choice, so it is ignored,
    // not overwritten. The app keeps its saved language and the OS keeps its.
    test('an unshipped language is ignored, not corrected', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: 'de', system: 'ja');

      expect(result, 'de');
      expect(recorder.persisted, isEmpty);
      expect(
        recorder.pushed,
        isEmpty,
        reason:
            'overwriting an OS-level choice we merely cannot render '
            'is a stronger action than ignoring it',
      );
      expect(
        recorder.seededMarks,
        1,
        reason:
            'the OS demonstrably holds an override, so its later absence '
            'must read as the user clearing it — not as never-seeded, which '
            'would re-push the saved code over their System default',
      );
    });

    test('an empty tag is treated as no override', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: 'it', system: '');

      expect(result, 'it');
      expect(recorder.pushed, ['it']);
      expect(recorder.seededMarks, 0);
    });

    // A channel failure is not an answer. Deciding anything on it — most of
    // all the seeded+absent clear below — would destroy a language the user
    // never touched.
    test('a failed read changes nothing, even when seeded', () async {
      final recorder = _Recorder();

      final result = await _reconcile(
        recorder,
        saved: 'de',
        system: null,
        seeded: true,
        readFailed: true,
      );

      expect(result, 'de');
      expect(recorder.pushed, isEmpty);
      expect(recorder.persisted, isEmpty);
      expect(recorder.seededMarks, 0);
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
