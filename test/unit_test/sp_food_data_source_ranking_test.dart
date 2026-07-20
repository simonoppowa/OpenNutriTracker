import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';

SpFoodDTO _food(String name, {int foodId = 0}) => SpFoodDTO(
      foodId: foodId,
      source: 'off',
      sourceCode: 'off',
      name: name,
    );

Map<String, dynamic> _translationRow(int foodId, String description) => {
      SPConst.translationFoodId: foodId,
      SPConst.translationDescription: description,
      SPConst.translationSource: 'human',
    };

void main() {
  group('rankAndTruncateFoodsByName', () {
    test('ranks the most relevant food first', () {
      final exact = _food('Milk');
      final loose = _food('Milk Chocolate Hazelnut Spread');
      final unrelated = _food('Chicken Breast');

      final ranked = rankAndTruncateFoodsByName([unrelated, loose, exact], 'milk');

      expect(ranked.map((f) => f.name), ['Milk', 'Milk Chocolate Hazelnut Spread', 'Chicken Breast']);
    });

    test('truncates to SPConst.maxNumberOfItems', () {
      final foods = List.generate(SPConst.maxNumberOfItems + 30, (i) => _food('Milk item $i'));

      final ranked = rankAndTruncateFoodsByName(foods, 'milk');

      expect(ranked, hasLength(SPConst.maxNumberOfItems));
    });

    // Regression: a naive `.limit(20)` applied *before* ranking would drop
    // a genuinely-best match if Postgres happened to return it outside the
    // first 20 rows (arbitrary/physical order, since there's no ORDER BY —
    // see SpFoodDataSource._candidatePoolSize). This proves the exact match
    // survives truncation even when it's the very last candidate handed in.
    test('a genuinely-best match is not lost to truncation even when it arrives last', () {
      final fillerMatches =
          List.generate(SPConst.maxNumberOfItems + 10, (i) => _food('Milk filler $i'));
      final bestMatch = _food('Milk');
      final candidates = [...fillerMatches, bestMatch];

      final ranked = rankAndTruncateFoodsByName(candidates, 'milk');

      expect(ranked.first.name, 'Milk');
    });

    test('does not mutate the input list', () {
      final unrelated = _food('Chicken Breast');
      final exact = _food('Milk');
      final input = [unrelated, exact];

      rankAndTruncateFoodsByName(input, 'milk');

      expect(input, [unrelated, exact]);
    });
  });

  group('rankAndTruncateTranslationRows', () {
    test('ranks the most relevant translated description first', () {
      final exact = _translationRow(1, 'Milch');
      final loose = _translationRow(2, 'Milch-Schokoladen-Aufstrich mit Haselnuss');
      final unrelated = _translationRow(3, 'Hähnchenbrust');

      final ranked = rankAndTruncateTranslationRows([unrelated, loose, exact], 'Milch');

      expect(
        ranked.map((r) => r[SPConst.translationFoodId]),
        [1, 2, 3],
      );
    });

    test('truncates to SPConst.maxNumberOfItems', () {
      final rows = List.generate(
        SPConst.maxNumberOfItems + 30,
        (i) => _translationRow(i, 'Milch Eintrag $i'),
      );

      final ranked = rankAndTruncateTranslationRows(rows, 'Milch');

      expect(ranked, hasLength(SPConst.maxNumberOfItems));
    });

    // Same regression as rankAndTruncateFoodsByName, but for the raw
    // food_translation rows ranked ahead of the food_summary fetch.
    test('a genuinely-best match is not lost to truncation even when it arrives last', () {
      final fillerRows = List.generate(
        SPConst.maxNumberOfItems + 10,
        (i) => _translationRow(i, 'Milch Eintrag $i'),
      );
      final bestRow = _translationRow(999, 'Milch');
      final candidates = [...fillerRows, bestRow];

      final ranked = rankAndTruncateTranslationRows(candidates, 'Milch');

      expect(ranked.first[SPConst.translationFoodId], 999);
    });

    test('does not mutate the input list', () {
      final unrelated = _translationRow(1, 'Hähnchenbrust');
      final exact = _translationRow(2, 'Milch');
      final input = [unrelated, exact];

      rankAndTruncateTranslationRows(input, 'Milch');

      expect(input, [unrelated, exact]);
    });
  });
}
