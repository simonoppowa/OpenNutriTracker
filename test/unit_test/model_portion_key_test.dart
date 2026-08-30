import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

Map<String, dynamic> get _itemProps =>
    ((mealItemsToolSchema['properties'] as Map)['items']
            as Map)['items'] as Map<String, dynamic>;

void main() {
  group('the model may name a portion, never measure one (#864)', () {
    test('the schema still has no nutrition field', () {
      // The guarantee the whole feature rests on. `portion` is a lookup key;
      // if this list ever grows a weight or an energy value, the model has
      // started measuring.
      final properties =
          (_itemProps['properties'] as Map).keys.cast<String>().toSet();
      expect(properties, {'query', 'quantity', 'unit', 'portion'});
      expect(_itemProps['additionalProperties'], isFalse);
    });

    test('portion is a string, and only query is required', () {
      final portion = (_itemProps['properties'] as Map)['portion'] as Map;
      expect(portion['type'], 'string');
      expect(_itemProps['required'], ['query']);
    });

    test('a portion in the reply survives to the item', () {
      final items = mealItemsFromJson([
        {'query': 'bread', 'quantity': 3, 'portion': 'slice'},
      ]);
      expect(items.single.portion, 'slice');
    });

    test('and survives validation, which rebuilds every item', () {
      // The failure this nearly shipped as: `validateParsedMealItems`
      // reconstructs each item, so a dropped field would leave the key set
      // and never used — the feature doing nothing, with nothing to notice.
      final result = validateParsedMealItems(
        mealItemsFromJson([
          {'query': 'bread', 'quantity': 3, 'portion': 'slice'},
        ]),
      );
      expect(result.items.single.portion, 'slice');
    });

    test('a number where a name belongs is dropped, not coerced', () {
      // A key is a word. A number here means the model misread the field,
      // not that it meant three of something.
      final items = mealItemsFromJson([
        {'query': 'bread', 'quantity': 3, 'portion': 3},
      ]);
      expect(items.single.portion, isNull);
    });

    test('blank and whitespace are no key at all', () {
      final items = mealItemsFromJson([
        {'query': 'a', 'portion': ''},
        {'query': 'b', 'portion': '   '},
      ]);
      expect(items.map((i) => i.portion), [isNull, isNull]);
    });

    test('the deterministic parser never sets one', () {
      // It keys off unit symbols and leaves any household word in the query,
      // where matchPortionToQuery finds it. Nothing offline invents a key.
      final parsed = parseMealText('3 slices of bread');
      expect(parsed.items.single.portion, isNull);
    });
  });
}
