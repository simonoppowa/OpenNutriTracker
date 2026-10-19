import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/locale_provider.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_writer.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  late Map<String, Object?> stored;
  late List<String> calls;
  late Set<String> groups;
  late List<MapEntry<String, Object?>> saves;
  String? failOn;

  setUp(() {
    stored = {};
    saves = [];
    failOn = null;
    calls = [];
    groups = {};
    PackageInfo.setMockInitialValues(
      appName: 'OpenNutriTracker',
      packageName: 'com.opennutritracker.ont.opennutritracker',
      version: '2.4.0',
      buildNumber: '66',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          final args = call.arguments as Map<Object?, Object?>?;
          groups.addAll(
            [args?['appGroupId'], args?['groupId']].whereType<String>(),
          );
          switch (call.method) {
            case 'saveWidgetData':
              final id = args!['id'] as String;
              final data = args['data'];
              if (id == failOn) {
                throw PlatformException(code: 'write-failed');
              }
              saves.add(MapEntry(id, data));
              if (data == null) {
                stored.remove(id);
              } else {
                stored[id] = data;
              }
              return true;
            case 'getWidgetData':
              return stored[args!['id']];
            default:
              return true;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  final snapshot = CalorieWidgetSnapshot.fromHome(
    consumedKcal: 180,
    goalKcal: 2000,
    offsetMinutes: 0,
    now: DateTime(2026, 9, 23, 13, 0),
  );
  final german = CalorieWidgetLabels.of(lookupS(const Locale('de')), snapshot);

  const snapshotKey = CalorieWidgetSnapshot.storageKey;
  const labelsKey = CalorieWidgetLabels.storageKey;

  test('a snapshot is one stored value, with the labels for its figures', () async {
    final store = HomeWidgetCalorieStore(isIOS: false);

    await store.write(snapshot, german);

    expect(stored, {
      labelsKey: german.encodeLanguage(),
      snapshotKey: snapshot.encode(german),
    });
    expect(
      saves.where((save) => save.key == snapshotKey),
      hasLength(1),
      reason: 'one platform call, so the extension never reads half of it',
    );
    expect(jsonDecode(stored[snapshotKey]! as String), {
      'hasData': true,
      'day': '2026-09-23',
      'offsetMinutes': 0,
      'consumed': 180,
      'goal': 2000,
      'labels': german.figureJson(),
    });
  });

  test('clear removes the figures and keeps the translated labels', () async {
    final store = HomeWidgetCalorieStore(isIOS: false);
    await store.write(snapshot, german);

    await store.clear();

    // The placeholder a wipe leads to stays in German rather than falling
    // back to the extension's English until onboarding writes again.
    expect(stored, {labelsKey: german.encodeLanguage()});
  });

  test('a write that fails leaves the previous snapshot whole', () async {
    // Yesterday's snapshot must not be read with today's day id and half
    // of today's figures.
    final store = HomeWidgetCalorieStore(isIOS: false);
    await store.write(snapshot, german);
    final today = CalorieWidgetSnapshot.fromHome(
      consumedKcal: 640,
      goalKcal: 2100,
      offsetMinutes: 0,
      now: DateTime(2026, 9, 24, 9, 0),
    );
    failOn = snapshotKey;

    await expectLater(
      store.write(today, german),
      throwsA(isA<PlatformException>()),
    );

    expect(stored[snapshotKey], snapshot.encode(german));
  });

  test('a write read before a clear is dropped, a fresh one is not', () async {
    // Home read the outgoing profile's totals, then a profile switch or
    // delete-all cleared the widget before Home published them.
    final store = HomeWidgetCalorieStore(isIOS: false);
    final readAt = store.generation;
    await store.clear();

    await store.write(snapshot, german, generation: readAt);
    expect(stored.keys, isNot(contains(snapshotKey)));

    await store.write(snapshot, german, generation: store.generation);
    expect(stored[snapshotKey], snapshot.encode(german));
  });

  test('a write and a clear issued together leave no figures', () async {
    // They run one at a time, so the clear cannot land between the write's
    // two values.
    final store = HomeWidgetCalorieStore(isIOS: false);
    await Future.wait([
      store.write(snapshot, german, generation: store.generation),
      store.clear(),
    ]);

    expect(stored.keys, isNot(contains(snapshotKey)));
  });

  test('clear reloads the iOS widget so it drops the old figures', () async {
    final store = HomeWidgetCalorieStore(isIOS: true);
    await store.write(snapshot, german);
    calls.clear();

    await store.clear();

    expect(stored.keys, [labelsKey]);
    expect(calls.first, 'setAppGroupId');
    expect(calls.last, 'updateWidget');
  });

  group('the App Group follows the flavour', () {
    test('the App Store bundle id gets the production group', () {
      expect(
        CalorieWidgetSnapshot.appGroupIdFor(
          'com.opennutritracker.ont.opennutritracker',
        ),
        'group.com.opennutritracker.ont.opennutritracker',
      );
    });

    test('the develop bundle id gets a group of its own', () {
      expect(
        CalorieWidgetSnapshot.appGroupIdFor(
          'com.opennutritracker.ont.opennutritracker.develop',
        ),
        'group.com.opennutritracker.ont.opennutritracker.develop',
      );
    });

    test('a develop install never touches the production group', () async {
      // `just dev_seed` next to the App Store build: its demo figures and
      // its wipe must stay in the develop group.
      final store = HomeWidgetCalorieStore(
        isIOS: true,
        bundleId: () async =>
            'com.opennutritracker.ont.opennutritracker.develop',
      );

      await store.write(snapshot, german);
      await store.clear();
      await store.relabel(lookupS(const Locale('de')));

      expect(groups, {CalorieWidgetSnapshot.developAppGroupId});
    });

    test('by default the group comes from the running bundle id', () async {
      final store = HomeWidgetCalorieStore(isIOS: true);

      await store.write(snapshot, german);

      expect(groups, {CalorieWidgetSnapshot.appGroupId});
    });
  });

  group('a language change', () {
    tearDown(AppLocale.reset);

    final english = CalorieWidgetLabels.of(
      lookupS(const Locale('en')),
      snapshot,
    );

    test('relabel translates the labels around the stored figures', () async {
      final store = HomeWidgetCalorieStore(isIOS: true);
      await store.write(snapshot, english);
      calls.clear();

      await store.relabel(lookupS(const Locale('de')));

      expect(stored, {
        labelsKey: german.encodeLanguage(),
        snapshotKey: snapshot.encode(german),
      });
      expect(calls.last, 'updateWidget');
    });

    test('relabel after a wipe writes no figure labels', () async {
      final store = HomeWidgetCalorieStore(isIOS: false);
      await store.write(snapshot, english);
      await store.clear();

      await store.relabel(lookupS(const Locale('de')));

      expect(stored, {labelsKey: german.encodeLanguage()});
    });

    test('the language picker relabels the widget', () async {
      final store = _RecordingStore();
      final provider = LocaleProvider(
        locale: const Locale('en'),
        calorieWidgetStore: store,
      );
      expect(store.relabelled, isEmpty, reason: 'start-up leaves it to Home');

      provider.updateLocale(const Locale('de'));
      await pumpEventQueue();

      expect(store.relabelled.single.trendsCaloriesLabel, german.title);
    });

    test('a device language change relabels it under System default', () async {
      final store = _RecordingStore();
      final provider = LocaleProvider(calorieWidgetStore: store);

      provider.systemLocalesChanged();
      await pumpEventQueue();
      expect(store.relabelled, hasLength(1));

      provider.updateLocale(const Locale('de'));
      await pumpEventQueue();
      provider.systemLocalesChanged();
      await pumpEventQueue();
      expect(
        store.relabelled,
        hasLength(2),
        reason: 'a chosen language does not follow the device',
      );
    });

    test('a launch into onboarding relabels the widget itself', () async {
      // Home never runs on this launch, so nothing else would bring the
      // labels a wipe kept into a language changed while the app was shut.
      final store = _RecordingStore();
      LocaleProvider(
        locale: const Locale('de'),
        calorieWidgetStore: store,
        relabelCalorieWidget: true,
      );
      await pumpEventQueue();

      expect(store.relabelled.single.trendsCaloriesLabel, german.title);
    });

    test('a widget that cannot be relabelled does not block it', () async {
      final provider = LocaleProvider(
        locale: const Locale('en'),
        calorieWidgetStore: _RecordingStore(fails: true),
      );

      provider.updateLocale(const Locale('de'));
      await pumpEventQueue();

      expect(provider.locale, const Locale('de'));
      expect(AppLocale.localeName, 'de');
    });
  });
}

class _RecordingStore implements CalorieWidgetStore {
  final bool fails;
  final relabelled = <S>[];

  _RecordingStore({this.fails = false});

  @override
  int get generation => 0;

  @override
  Future<void> write(
    CalorieWidgetSnapshot snapshot,
    CalorieWidgetLabels labels, {
    int? generation,
  }) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> relabel(S s) async {
    relabelled.add(s);
    if (fails) throw MissingPluginException('home_widget');
  }
}
