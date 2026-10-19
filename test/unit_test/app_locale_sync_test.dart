import 'dart:async';
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
  /// What a read-back of the OS tag answers after a push. By default it
  /// echoes the pushed value — a platform that holds per-app overrides.
  /// Pass false for one that cannot hold them, where a push no-ops.
  _Recorder({this.readBackFollowsPush = true});

  final bool readBackFollowsPush;
  final persisted = <String?>[];
  final pushed = <String?>[];
  int seededMarks = 0;
  int seededClears = 0;

  Future<void> persist(String? code) async => persisted.add(code);
  Future<void> push(String? tag) async => pushed.add(tag);
  Future<({String? tag, bool readFailed})> readBack() async =>
      (tag: readBackFollowsPush ? pushed.lastOrNull : null, readFailed: false);
  Future<void> markSeeded() async => seededMarks++;
  Future<void> clearSeeded() async => seededClears++;
}

/// One device across several launches: the saved choice, the OS override
/// and the seeded marker all persist between [launch] calls, the way the
/// config box and Android's per-app setting do.
class _Device {
  _Device({this.saved, this.osTag, this.seeded = false});

  String? saved;
  String? osTag;
  bool seeded;

  /// Whether a push reaches the OS. False models the swallowed
  /// PlatformException in AppLocaleService.setApplicationLocale.
  bool pushTakes = true;
  final pushed = <String?>[];

  /// The in-app picker: saves the choice and pushes it to the OS through
  /// [pushInAppLocaleChoice], as the Settings dialog does. No locale-change
  /// callback follows, the case where the choice leaves the platform's
  /// locale list as it was.
  Future<void> pickInApp(String? code) {
    saved = code;
    return pushInAppLocaleChoice(
      localeCode: code,
      pushToSystem: _push,
      readSystemTag: _read,
      markLocaleSyncSeeded: () async => seeded = true,
      clearLocaleSyncSeeded: () async => seeded = false,
    );
  }

  Future<void> _push(String? tag) async {
    pushed.add(tag);
    if (pushTakes) osTag = tag;
  }

  Future<({String? tag, bool readFailed})> _read() async =>
      (tag: osTag, readFailed: false);

  Future<String?> launch() => reconcileAppLocale(
    savedLocaleCode: saved,
    systemLocaleTag: osTag,
    systemTagReadFailed: false,
    localeSyncSeeded: seeded,
    supportedLocales: _supported,
    persistSelectedLocale: (code) async => saved = code,
    pushToSystem: _push,
    readSystemTag: () async => (tag: osTag, readFailed: false),
    markLocaleSyncSeeded: () async => seeded = true,
    clearLocaleSyncSeeded: () async => seeded = false,
  );
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
  readSystemTag: recorder.readBack,
  markLocaleSyncSeeded: recorder.markSeeded,
  clearLocaleSyncSeeded: recorder.clearSeeded,
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
    // they meant, and it seeds the system rather than being overwritten by
    // it. The read-back sees the pushed value, so seeded is recorded in the
    // same call — a clear arriving any time afterwards is honoured, with no
    // window in which it would read as never-seeded and be re-pushed.
    test('a saved choice seeds the system and the echo records it', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: 'uk', system: null);

      expect(result, 'uk');
      expect(recorder.pushed, ['uk']);
      expect(recorder.persisted, isEmpty);
      expect(
        recorder.seededMarks,
        1,
        reason:
            'seeded means the OS was SEEN holding a value — here via the '
            'read-back of the push, not the attempt itself',
      );
    });

    // On a platform with no per-app override the push no-ops and the
    // read-back stays empty, so seeded is never recorded and the migration
    // branch repeats — harmlessly — instead of the platform ever being
    // mistaken for a user who cleared their override.
    test('a saved choice on an override-less platform survives', () async {
      final recorder = _Recorder(readBackFollowsPush: false);

      await _reconcile(recorder, saved: 'uk', system: null);
      final result = await _reconcile(recorder, saved: 'uk', system: null);

      expect(result, 'uk');
      expect(
        recorder.persisted,
        isEmpty,
        reason: 'nothing may clear a choice the user never cleared',
      );
      expect(
        recorder.pushed,
        ['uk', 'uk'],
        reason: 'the repeat is the design: pushes that never take are no-ops',
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
      expect(
        recorder.seededClears,
        1,
        reason: 'the clear is acted on, so the record of the override it '
            'removed is spent',
      );
    });

    // Codex on #1230: the marker used to stay set for good once an override
    // had been seen. After an OS clear, a language picked in the app whose
    // push silently failed then left "saved, no OS tag, seeded" behind,
    // which the next launch read as a second OS clear and deleted.
    test('after an OS clear, a new in-app choice whose push failed survives',
        () async {
      final device = _Device(saved: 'pl', osTag: 'pl', seeded: true);

      device.osTag = null; // System default in Android's picker
      expect(await device.launch(), isNull);
      expect(device.saved, isNull);

      device.pushTakes = false;
      await device.pickInApp('de');

      final result = await device.launch();

      expect(
        result,
        'de',
        reason: 'a failed push is not the user clearing their choice',
      );
      expect(device.saved, 'de');
      expect(
        device.pushed,
        ['de', 'de'],
        reason: 'the launch retries the push the picker could not deliver',
      );
      expect(device.seeded, isFalse);
    });

    test('once the retried push takes, a later OS clear is still honoured',
        () async {
      final device = _Device(saved: 'pl', osTag: 'pl', seeded: true);
      device.osTag = null;
      await device.launch();
      device.pushTakes = false;
      await device.pickInApp('de');
      await device.launch();

      device.pushTakes = true;
      expect(await device.launch(), 'de');
      expect(device.osTag, 'de');
      expect(device.seeded, isTrue);

      device.osTag = null;
      expect(await device.launch(), isNull);
      expect(device.saved, isNull);
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

      final result =
          await _reconcile(recorder, saved: null, system: 'zh-Hans-CN');

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

    test('an unshipped language already seeded is not recorded again',
        () async {
      final recorder = _Recorder();

      final result =
          await _reconcile(recorder, saved: 'de', system: 'ja', seeded: true);

      expect(result, 'de');
      expect(recorder.persisted, isEmpty);
      expect(recorder.pushed, isEmpty);
      expect(recorder.seededMarks, 0);
    });

    // The override went away with nothing saved -- System default chosen in
    // the app, say. The marker still describes an override that is gone, so
    // it is consumed; left set, a later in-app choice whose push failed
    // would be deleted as if the OS had cleared it.
    test('once seeded, nothing on either side only spends the marker',
        () async {
      final recorder = _Recorder();

      final result =
          await _reconcile(recorder, saved: null, system: null, seeded: true);

      expect(result, isNull);
      expect(recorder.persisted, isEmpty);
      expect(recorder.pushed, isEmpty);
      expect(recorder.seededMarks, 0);
      expect(recorder.seededClears, 1);
    });

    test('an empty tag is treated as no override', () async {
      final recorder = _Recorder();

      final result = await _reconcile(recorder, saved: 'it', system: '');

      expect(result, 'it');
      expect(recorder.pushed, ['it']);
      expect(recorder.seededMarks, 1);
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
      expect(recorder.seededClears, 0);
    });
  });

  group('pushInAppLocaleChoice', () {
    Future<_Recorder> pick(
      String? code, {
      String? readBack,
      bool failed = false,
    }) async {
      final recorder = _Recorder();
      await pushInAppLocaleChoice(
        localeCode: code,
        pushToSystem: recorder.push,
        readSystemTag: () async => (tag: readBack, readFailed: failed),
        markLocaleSyncSeeded: recorder.markSeeded,
        clearLocaleSyncSeeded: recorder.clearSeeded,
      );
      return recorder;
    }

    test('a pick the OS reads back records seeded', () async {
      final recorder = await pick('de', readBack: 'de');

      expect(recorder.pushed, ['de']);
      expect(recorder.seededMarks, 1);
      expect(recorder.seededClears, 0);
    });

    test('System default consumes the marker', () async {
      final recorder = await pick(null);

      expect(recorder.pushed, [null]);
      expect(recorder.seededMarks, 0);
      expect(recorder.seededClears, 1);
    });

    test('a push that did not take consumes the marker', () async {
      final recorder = await pick('de');

      expect(recorder.seededMarks, 0);
      expect(
        recorder.seededClears,
        1,
        reason: 'the next launch retries the push instead of reading a clear',
      );
    });

    test('a failed read decides nothing', () async {
      final recorder = await pick('de', failed: true);

      expect(recorder.pushed, ['de']);
      expect(recorder.seededMarks, 0);
      expect(recorder.seededClears, 0);
    });

    // Copilot on #1230: the picker used to push without recording anything,
    // so a pick that fired no locale-change callback left the marker unset.
    // An OS clear before the next launch then read as never-seeded, and the
    // launch pushed the cleared language back.
    test('pick, no callback, OS clear, launch: the clear is honoured',
        () async {
      final device = _Device();

      await device.pickInApp('de');
      device.osTag = null; // System default in Android's picker

      expect(await device.launch(), isNull);
      expect(device.saved, isNull);
      expect(
        device.pushed,
        ['de'],
        reason: 'the cleared language must not be pushed back',
      );
      expect(device.osTag, isNull);
    });

    test('a failed pick after an unseen OS clear is retried, not deleted',
        () async {
      final device = _Device(saved: 'pl', osTag: 'pl', seeded: true);
      device.osTag = null; // cleared while the app ran, no callback seen

      device.pushTakes = false;
      await device.pickInApp('de');
      device.pushTakes = true;

      expect(await device.launch(), 'de');
      expect(device.saved, 'de');
      expect(device.osTag, 'de');
      expect(device.seeded, isTrue);
    });
  });

  group('in-app picker against runtime reconciliation', () {
    // Copilot on #1230: the runtime guard serialized reconciliation only, so
    // a pick could run while an OS-clear reconciliation was paused on its
    // write. Resumed, the older run cleared the pick's marker and adopted
    // null; with no locale-change callback to repair it, a later OS clear
    // then read as never-seeded and the cleared language was pushed back.
    test('a pick during an OS-clear reconciliation keeps its marker', () async {
      final device = _Device(saved: 'pl', osTag: 'pl', seeded: true);
      final lock = LocaleSyncLock();
      final shown = <String?>[];
      final reachedPersist = Completer<void>();
      final persistGate = Completer<void>();

      device.osTag = null; // System default in Android's picker, app alive
      final runtime = lock.run(() async {
        final code = await reconcileAppLocale(
          savedLocaleCode: device.saved,
          systemLocaleTag: device.osTag,
          systemTagReadFailed: false,
          localeSyncSeeded: device.seeded,
          supportedLocales: _supported,
          persistSelectedLocale: (code) async {
            reachedPersist.complete();
            await persistGate.future;
            device.saved = code;
          },
          pushToSystem: device._push,
          readSystemTag: device._read,
          markLocaleSyncSeeded: () async => device.seeded = true,
          clearLocaleSyncSeeded: () async => device.seeded = false,
        );
        shown.add(code);
      });
      await reachedPersist.future;

      final pick = applyInAppLocaleChoice(
        lock: lock,
        localeCode: 'de',
        persistSelectedLocale: (code) async => device.saved = code,
        applyToApp: () => shown.add('de'),
        pushToSystem: device._push,
        readSystemTag: device._read,
        markLocaleSyncSeeded: () async => device.seeded = true,
        clearLocaleSyncSeeded: () async => device.seeded = false,
      );
      // Let the pick get as far as it can before the reconciliation resumes.
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      persistGate.complete();
      await Future.wait([runtime, pick]);

      expect(shown, [null, 'de'], reason: 'the pick lands after the clear');
      expect(device.saved, 'de');
      expect(device.osTag, 'de');
      expect(device.seeded, isTrue, reason: 'the older run must not clear it');

      device.osTag = null; // a later clear in Android's picker
      expect(await device.launch(), isNull);
      expect(
        device.pushed,
        ['de'],
        reason: 'the cleared language must not be pushed back',
      );
    });

    test('a task that throws does not stall the next one', () async {
      final lock = LocaleSyncLock();

      await expectLater(
        lock.run<void>(() async => throw StateError('channel')),
        throwsStateError,
      );
      expect(await lock.run(() async => 'next'), 'next');
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
