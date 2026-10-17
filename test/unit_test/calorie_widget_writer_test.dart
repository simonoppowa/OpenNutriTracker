import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
