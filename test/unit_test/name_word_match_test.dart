import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/name_word_match.dart';

void main() {
  group('nameHasQueryWords', () {
    test('every query word, in any order, up to an ending', () {
      expect(nameHasQueryWords('Tomato Soup', 'soup tomato'), isTrue);
      expect(nameHasQueryWords('Pancake', 'pancakes'), isTrue);
      expect(nameHasQueryWords('Pelmenis', 'pelmeni'), isTrue);
      expect(nameHasQueryWords('Grey peas with bacon', 'bacon, peas'), isTrue);
      expect(nameHasQueryWords('Mixed berry bowl', 'berries'), isTrue);
    });

    test('a word the name lacks, or a blank query, does not match', () {
      expect(nameHasQueryWords('Grey peas with bacon', 'green peas'), isFalse);
      expect(nameHasQueryWords('Pelmenis', 'pelmeni, fried'), isFalse);
      expect(nameHasQueryWords('Pelmenis', '  '), isFalse);
      expect(nameHasQueryWords(null, 'pelmeni'), isFalse);
    });
  });

  group('wordsAgree', () {
    test('a word and its ending agree', () {
      expect(wordsAgree('egg', 'eggs'), isTrue);
      expect(wordsAgree('potato', 'potatoes'), isTrue);
      expect(wordsAgree('cheese', 'cheesy'), isTrue);
      expect(wordsAgree('berry', 'berries'), isTrue);
    });

    test('different words do not', () {
      expect(wordsAgree('fan', 'fanta'), isFalse);
      expect(wordsAgree('pasta', 'paste'), isFalse);
      expect(wordsAgree('fried', 'fries'), isFalse);
      expect(wordsAgree('ap', 'apple'), isFalse);
    });
  });
}
