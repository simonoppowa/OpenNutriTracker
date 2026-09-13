/// Works out which of a food's portions was meant, from the words the user
/// typed or the one word a model named.
///
/// "3 slices of bread" should pick the slice, not the cup. The parser cannot
/// do it: it keys off unit *symbols* (`g`, `ml`, `oz`) because a vocabulary
/// of words would grow with every locale, which is the objection that ruled
/// out number-words in #600. So the word survives into the query text and is
/// matched here instead — against the food's **own** portion labels, which
/// arrive translated from the backend. The vocabulary lives in the data, per
/// food, per language, and the app never holds a word list. #864.
///
/// Two callers, two labels. The user's words are in their language, so
/// [matchPortionToQuery] tries them against the label as it arrived —
/// translated where a human verified it. A model's `portion` key is English
/// in every locale (#1157), so [matchPortionToKey] tries it against the
/// English label the backend sends beside the translated one; "slice" against
/// "1 Scheibe" would otherwise miss on exactly the locale whose labels were
/// reviewed. Same scoring, same tie rule, different string.
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

/// The label a model's key is matched against, and the one the tie rule
/// reads: English where the backend sent it, else whatever the label is —
/// which in eight of nine locales is the English string anyway.
String _englishLabelOf(MealPortionEntity portion) =>
    portion.englishLabel ?? portion.label;

/// Which portion the words the user typed name, or null when they name none.
///
/// Matched against [MealPortionEntity.label], the string the reader sees:
/// their words are in their language, and the localized label is what those
/// words mean.
int? matchPortionToQuery(String query, List<MealPortionEntity> portions) =>
    _match(query, portions, (portion) => portion.label);

/// Which portion the model's [key] names, or null when it names none — or
/// when there is no key, which is the usual case on the typed path.
///
/// Matched against the English label. The prompt pins the key to English
/// whatever language the meal was written in, so the match is independent of
/// how far a locale's translation review has got: a German reader's "3
/// Scheiben Brot" arrives as `portion: "slice"` and lands on the same row an
/// English reader's would. #1157.
int? matchPortionToKey(String? key, List<MealPortionEntity> portions) =>
    key == null ? null : _match(key, portions, _englishLabelOf);

/// Scored by the length of the longest term that matched, so a query hitting
/// both "1 bag" and "1 large single serving bag" resolves to whichever
/// matched on more word.
///
/// Rows that tie on that score go to [_middleRung] — the one whose English
/// label says `medium` or `regular` — and failing that to the earlier row:
/// the backend's order, whose first entry is the default the row would have
/// taken anyway.
int? _match(
  String text,
  List<MealPortionEntity> portions,
  String Function(MealPortionEntity) labelOf,
) {
  if (portions.isEmpty) return null;
  final tokens = _words(text);
  if (tokens.isEmpty) return null;

  var bestScore = 0;
  final tied = <int>[];
  for (var i = 0; i < portions.length; i++) {
    var score = 0;
    for (final term in _termsOf(labelOf(portions[i]))) {
      if (term.length > score && tokens.any((t) => _matches(t, term))) {
        score = term.length;
      }
    }
    if (score == 0 || score < bestScore) continue;
    if (score > bestScore) {
      bestScore = score;
      tied.clear();
    }
    tied.add(i);
  }
  if (tied.isEmpty) return null;
  return _middleRung(tied, portions) ?? tied.first;
}

/// The words that name the middle of a size ladder in FDC's own vocabulary:
/// `small or thin` / `medium or regular` / `large or thick`.
const _middleRungWords = {'medium', 'regular'};

/// Among [tied] rows, the first whose English label names the middle rung,
/// or null when none does.
///
/// A bare "slice" ties every slice a food has, and FDC lists ladders
/// small-first — so the earliest row was the *thin* slice, 24 g of bread
/// where a person who said "a slice" meant the 28 g regular one. The data
/// names its own middle, and a word that names no size means that middle
/// in the data's convention. This only ever selects among rows the word
/// already tied; the unqualified default — what "3 bread" logs — is
/// untouched, which is #864 decision 7. Read off the English label because
/// the ladder words are English and the label is sent in every locale.
/// #1162.
int? _middleRung(List<int> tied, List<MealPortionEntity> portions) {
  for (final i in tied) {
    if (_termsOf(_englishLabelOf(portions[i])).any(_middleRungWords.contains)) {
      return i;
    }
  }
  return null;
}
