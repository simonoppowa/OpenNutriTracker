import 'package:opennutritracker/features/add_meal/util/soft_text_score.dart';

/// Whether every word of [query] is a word of [name], in any order and up
/// to an ending ([wordsAgree]).
///
/// The search's substring match finds "Tomato Soup" for "tomato so" but
/// not for "soup tomato", nor "Pancake" for "pancakes". The user's own
/// meals and recipes are matched by this too, beside the substring match
/// and never instead of it, so a half-typed word ("toma") still finds the
/// recipe.
bool nameHasQueryWords(String? name, String query) {
  final queryWords = tokenize(query);
  if (queryWords.isEmpty) return false;
  final nameWords = tokenize(name);
  return queryWords.every((q) => nameWords.any((t) => wordsAgree(q, t)));
}

/// Whether query word [q] and name word [t] are the same word up to an
/// ending: one is the other plus at most two letters (`egg`/`eggs`,
/// `potato`/`potatoes`; one letter for a three-letter word, so `fan` is not
/// `fanta`), or both share a stem of five letters or more and differ in at
/// most two letters after it, one for the shorter (`cheese`/`cheesy`), or
/// `y` and `ies` (`berry`/`berries`). Four shared letters are not a stem:
/// `pasta` is not `paste`.
bool wordsAgree(String q, String t) {
  if (q == t) return true;
  final (shorter, longer) = q.length <= t.length ? (q, t) : (t, q);
  var shared = 0;
  while (shared < shorter.length &&
      shorter.codeUnitAt(shared) == longer.codeUnitAt(shared)) {
    shared++;
  }
  if (shared == shorter.length) {
    final ending = shorter.length == 3 ? 1 : 2;
    return shorter.length >= 3 && longer.length - shorter.length <= ending;
  }
  if (shorter.endsWith('y') &&
      longer == '${shorter.substring(0, shorter.length - 1)}ies') {
    return true;
  }
  // Both differ after the stem, the shorter by one letter, past five
  // shared: `pasta` is not `paste`, `fried` not `fries`.
  return shared >= 5 &&
      longer.length - shared <= 2 &&
      shorter.length - shared <= 1;
}
