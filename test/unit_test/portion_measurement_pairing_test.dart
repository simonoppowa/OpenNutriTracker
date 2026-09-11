// The photo harness pairs each validated item back to the wire item it came
// from, to report what the model actually sent. The pairing rests on two
// facts about the app's own decoding — `mealItemsFromJson` and
// `validateParsedMealItems` keep order and only ever drop — and on the
// validator trimming the query while `_mealItemFrom` does not. This runs the
// pairing over the real two steps, so a change to either shows up here
// rather than as an item silently missing from a report.

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

import '../../tool/portion_measurement/metrics.dart' as tool;

List<Map<String, Object?>> _wire() => [
  {'query': 'egg ', 'quantity': 2, 'portion': 'large'},
  {'query': '', 'quantity': 1},
  {'query': 'toast', 'quantity': 2, 'portion': 'slice'},
  {'query': 'rice', 'quantity': -1},
  {'query': 'egg', 'quantity': 3},
  {'quantity': 5},
  {'query': '  Orange Juice  '},
  {'query': 'egg', 'quantity': 1e9},
];

void main() {
  test('the validated list is a subsequence of the wire, trimmed', () {
    final validated = validateParsedMealItems(mealItemsFromJson(_wire())).items;
    expect(
      [for (final i in validated) i.query],
      ['egg', 'toast', 'egg', 'Orange Juice'],
    );
  });

  test('every validated item pairs with its own wire item, in order', () {
    final wire = _wire();
    final validated = validateParsedMealItems(mealItemsFromJson(wire)).items;
    final paired = tool.pairRawItems(wire, validated);
    expect(paired.length, validated.length);
    expect(paired, everyElement(isNotNull));
    expect(
      [for (final r in paired) r!.json],
      [wire[0], wire[2], wire[4], wire[6]],
    );
    // `egg ` — the case an exact comparison lost.
    expect(paired[0]!.query, 'egg ');
    expect(paired[0]!.portion, 'large');
    // The second egg is the second egg, not the first again.
    expect(paired[2]!.quantity, 3);
  });

  test('a reordered client still pairs something with the same words', () {
    // Best effort, not exact: with the order gone, two wire entries for
    // `egg` cannot be told apart, so only the words are checked.
    final wire = _wire();
    final validated = validateParsedMealItems(mealItemsFromJson(wire)).items;
    final reversed = validated.reversed.toList();
    final paired = tool.pairRawItems(wire, reversed);
    expect(paired, everyElement(isNotNull));
    for (final (i, item) in reversed.indexed) {
      expect(paired[i]!.query!.trim().toLowerCase(), item.query.toLowerCase());
    }
    // No wire entry is handed out twice.
    expect(paired.map((r) => r!.json).toSet().length, paired.length);
  });

  test('an item nothing on the wire explains is null, not skipped', () {
    final wire = _wire();
    final validated = [
      ...validateParsedMealItems(mealItemsFromJson(wire)).items,
      const ParsedMealItem(query: 'bacon', quantity: 4, unit: null, portion: null),
    ];
    final paired = tool.pairRawItems(wire, validated);
    expect(paired.length, validated.length);
    expect(paired.last, isNull);
    expect(paired.take(4), everyElement(isNotNull));
  });
}
