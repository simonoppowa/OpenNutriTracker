import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/locale_provider.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_writer.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  late Map<String, Object?> stored;
  late List<String> calls;

  setUp(() {
    stored = {};
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          final args = call.arguments as Map<Object?, Object?>?;
          switch (call.method) {
            case 'saveWidgetData':
              final id = args!['id'] as String;
              final data = args['data'];
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

  test('clear removes the figures and keeps the translated labels', () async {
    final store = HomeWidgetCalorieStore(isIOS: false);
    await store.write(snapshot, german);
    expect(
      stored.keys,
      containsAll([...CalorieWidgetSnapshot.keys, ...CalorieWidgetLabels.keys]),
      reason: 'setup',
    );

    await store.clear();

    // The placeholder a wipe leads to stays in German rather than falling
    // back to the extension's English until onboarding writes again.
    expect(stored, german.languagePayload());
  });

  test('clear reloads the iOS widget so it drops the old figures', () async {
    final store = HomeWidgetCalorieStore(isIOS: true);
    await store.write(snapshot, german);
    calls.clear();

    await store.clear();

    expect(stored.keys, unorderedEquals(CalorieWidgetLabels.languageKeys));
    expect(calls.first, 'setAppGroupId');
    expect(calls.last, 'updateWidget');
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

      expect(stored, {...snapshot.toPayload(), ...german.toPayload()});
      expect(calls.last, 'updateWidget');
    });

    test('relabel after a wipe writes no figure labels', () async {
      final store = HomeWidgetCalorieStore(isIOS: false);
      await store.write(snapshot, english);
      await store.clear();

      await store.relabel(lookupS(const Locale('de')));

      expect(stored, german.languagePayload());
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
  Future<void> write(
    CalorieWidgetSnapshot snapshot,
    CalorieWidgetLabels labels,
  ) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> relabel(S s) async {
    relabelled.add(s);
    if (fails) throw MissingPluginException('home_widget');
  }
}
