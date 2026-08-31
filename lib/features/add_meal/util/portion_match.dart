/// Works out which of a food's portions the user meant, from the words they
/// typed.
///
/// "3 slices of bread" should pick the slice, not the cup. The parser cannot
/// do it: it keys off unit *symbols* (`g`, `ml`, `oz`) because a vocabulary
/// of words would grow with every locale, which is the objection that ruled
/// out number-words in #600. So the word survives into the query text and is
/// matched here instead — against the food's **own** portion labels, which
/// arrive translated from the backend. The vocabulary lives in the data, per
/// food, per language, and the app never holds a word list. #864.
///
/// Deliberately quiet about failure. No match means the row keeps the
/// preselection it would have had, so a miss costs nothing and a false
/// positive would cost a wrong portion on a plausible-looking row — which is
/// the failure this whole issue exists to stop.
library;

import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

/// A parenthetical: "1 cup (8 fl oz)".
final _parenthetical = RegExp(r'\([^)]*\)');

/// Anything that is not a letter, for splitting both sides into words.
final _nonLetter = RegExp(r'[^\p{L}]+', unicode: true);

/// Below this a word is too short to match on. "oz" would otherwise hit
/// "ozark", and two letters carry too little signal in any language.
const _minTermLength = 3;

/// How much longer an inflected form may be than the term it matches.
///
/// Two covers the endings that actually appear — slice/slices,
/// Scheibe/Scheiben, plátek/plátky — without letting a term match an
/// unrelated longer word. It is a bound, not a grammar: no per-language
/// plural rules, which is the same reason this file holds no word list.
const _maxInflection = 2;

Set<String> _words(String text) => text
    .toLowerCase()
    .split(_nonLetter)
    .where((w) => w.length >= _minTermLength)
    .toSet();

/// The words of a portion label that are worth matching on.
/// The count needs no stripping: [_words] keeps only runs of letters, so the
/// "1" in "1 slice" and the "1/2" in "1/2 bagel" never become terms.
Set<String> _termsOf(String label) =>
    _words(label.replaceAll(_parenthetical, ' '));

/// True when [token] is [term], or either is the other with a short ending.
bool _matches(String token, String term) {
  if (token == term) return true;
  if (token.startsWith(term) && token.length - term.length <= _maxInflection) {
    return true;
  }
  return term.startsWith(token) && term.length - token.length <= _maxInflection;
}

/// Which portion [query] names, or null when it names none.
///
/// Scored by the length of the longest term that matched, so a query hitting
/// both "1 large" and "1 large single serving bag" resolves to whichever
/// matched on more word, and ties go to the earlier portion — the backend's
/// order, whose first entry is the default the row would have taken anyway.
int? matchPortionToQuery(String query, List<MealPortionEntity> portions) {
  if (portions.isEmpty) return null;
  final tokens = _words(query);
  if (tokens.isEmpty) return null;

  int? best;
  var bestScore = 0;
  for (var i = 0; i < portions.length; i++) {
    for (final term in _termsOf(portions[i].label)) {
      if (!tokens.any((t) => _matches(t, term))) continue;
      if (term.length > bestScore) {
        bestScore = term.length;
        best = i;
      }
    }
  }
  return best;
}
