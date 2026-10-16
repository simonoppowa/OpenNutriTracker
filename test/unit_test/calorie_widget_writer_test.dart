import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_writer.dart';

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

  Future<void> writeToday(CalorieWidgetStore store) {
    final snapshot = CalorieWidgetSnapshot.fromHome(
      consumedKcal: 180,
      goalKcal: 2000,
      offsetMinutes: 0,
      now: DateTime(2026, 9, 23, 13, 0),
    );
    return store.write(
      snapshot,
      const CalorieWidgetLabels(
        title: 'Calories',
        unit: 'kcal',
        goal: 'of 2000',
        accessibility: '180 of 2000 kilocalories',
        openApp: 'Open the app',
        description: "Today's calories eaten and your goal.",
      ),
    );
  }

  test('clear removes every key write stored', () async {
    final store = HomeWidgetCalorieStore(isIOS: false);
    await writeToday(store);
    expect(
      stored.keys,
      containsAll([...CalorieWidgetSnapshot.keys, ...CalorieWidgetLabels.keys]),
      reason: 'setup',
    );

    await store.clear();

    expect(stored, isEmpty);
  });

  test('clear reloads the iOS widget so it drops the old figures', () async {
    final store = HomeWidgetCalorieStore(isIOS: true);
    await writeToday(store);
    calls.clear();

    await store.clear();

    expect(stored, isEmpty);
    expect(calls.first, 'setAppGroupId');
    expect(calls.last, 'updateWidget');
  });
}
