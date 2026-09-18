// What both harnesses measure about a portion key, in one place so the text
// and photo reports count the same things the same way.

import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/add_meal/util/portion_match.dart';

/// The eight words the prompts steer toward (#1158).
const steeringWords = {
  'slice',
  'piece',
  'cup',
  'tablespoon',
  'teaspoon',
  'small',
  'medium',
  'large',
};

/// The three words a photo may keep (#1156).
const photoSizeWords = {'small', 'medium', 'large'};

/// The unit enum the schema names; anything else on a text line is a
/// household measure the model must put in `portion` instead.
const schemaUnits = {'g', 'kg', 'lb', 'ml', 'l', 'g/ml', 'oz', 'fl.oz', 'serving'};

/// What `validateParsedMealItems` keeps.
const validatedUnits = {'g', 'ml', 'g/ml', 'oz', 'fl.oz', 'serving'};

/// #1155's classes, first match wins in the order size > container > piece,
/// applied to a key rather than a label. Used to say *why* the photo guard
/// dropped a word.
final _containerWord = RegExp(
  r'\b(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|'
  r'scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|'
  r'containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\b',
  caseSensitive: false,
);
final _pieceWord = RegExp(
  r'\b(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|'
  r'links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|'
  r'items?|halves|half)\b',
  caseSensitive: false,
);
final _sizeLikeWord = RegExp(
  r'\b(small|medium|large|jumbo|mini|miniature|extra|regular|thick|thin|'
  r'bite)\b',
  caseSensitive: false,
);

/// Letters only, all ASCII — the shape of an English word, which is not the
/// same as being one: "Scheibe" passes. [keyLanguage] does the finer test.
bool isAsciiLetters(String key) => RegExp(r'^[A-Za-z]+$').hasMatch(key);

/// Where the key's language sits, as far as a harness can tell.
///
/// `steering` is one of the eight; `askedWord` is the English word the
/// line's template asked for when it is not one of the eight — `glass`,
/// `bowl`, `handful`; `inputWord` is a word of the line's own language for
/// that measure (any written form, or an inflection of one), which is the
/// failure #1157 names — "a model that answers *Scheibe* to a German line";
/// `asciiOther` is English-shaped and unverified (the long tail: "wedge",
/// "can"); `nonAscii` cannot be English.
///
/// The asked word is tested before the own word because the two can be one
/// letter apart — `glass` on a *Glas* line is the English answer, not the
/// German one — and the own word is tested on every form the locale writes
/// for the measure, not only the one the line carried, because a model
/// that answers the lemma to a plural line (*Glas* to *Gläser*, *tazza* to
/// *tazze*, *hrnek* to *hrnky*) has answered in the input language just
/// the same.
enum KeyLanguage { steering, askedWord, inputWord, asciiOther, nonAscii }

/// The classes the report's *English* column counts.
const englishKeyLanguages = {
  KeyLanguage.steering,
  KeyLanguage.askedWord,
  KeyLanguage.asciiOther,
};

KeyLanguage keyLanguage(
  String key, {
  String? askedKey,
  Iterable<String> inputMeasureForms = const [],
}) {
  final k = key.trim().toLowerCase();
  if (steeringWords.contains(k)) return KeyLanguage.steering;
  if (askedKey != null && k == askedKey.toLowerCase()) {
    return KeyLanguage.askedWord;
  }
  for (final form in inputMeasureForms) {
    if (_inflectionOf(k, form.toLowerCase())) return KeyLanguage.inputWord;
  }
  return isAsciiLetters(k) ? KeyLanguage.asciiOther : KeyLanguage.nonAscii;
}

/// True when [a] and [b] are the same word under a short ending: they share
/// a stem of at least three letters and each carries at most two letters
/// past it. Symmetric, so it also covers an ending swapped rather than
/// added — tazze/tazza, pezzi/pezzo, hrnky/hrnek, plátky/plátek — which
/// "longer starts with shorter" did not. A stem change (Gläser/Glas) is
/// still not an inflection here; that case is met by passing every form.
bool _inflectionOf(String a, String b) {
  if (a == b) return true;
  final shorter = a.length < b.length ? a.length : b.length;
  var stem = 0;
  while (stem < shorter && a.codeUnitAt(stem) == b.codeUnitAt(stem)) {
    stem++;
  }
  if (stem < 3) return false;
  return a.length - stem <= 2 && b.length - stem <= 2;
}

/// The abbreviation the line carried, if any, and the word it should have
/// become. `tbsp`/`tsp` have zero rows in the table (#1155); `EL`/`TL` are
/// their German equivalents.
const abbreviationExpansions = {
  'tbsp': 'tablespoon',
  'tsp': 'teaspoon',
  'el': 'tablespoon',
  'tl': 'teaspoon',
};

/// True when the key is one of the abbreviations as written, which the
/// prompt tells the model to expand.
bool isAbbreviationKey(String key) =>
    abbreviationExpansions.containsKey(key.trim().toLowerCase());

/// One of the matcher's two answers, with what it does not report: whether
/// the winner won on a tie, and whether the middle-rung rule (#1162)
/// decided that tie.
///
/// Two callers, two labels (`portion_match.dart`): a model's key goes
/// through `matchPortionToKey` against the English label the backend sends
/// beside the localized one (#1208), the user's words through
/// `matchPortionToQuery` against the label as it arrived. [keyMatch] and
/// [queryMatch] call those two — the app's own functions, imported — and
/// recover the tie from the score the matcher keeps private: the sum of
/// the lengths of the label's terms that a token of the text matched
/// (portion_match.dart:115-121), restated in [_termScore]. The rows at the
/// best score are the tie; among them `_middleRung` (:158-165) picks the
/// first whose English label names `medium` or `regular`, and failing that
/// the earliest row (:130). The restated prediction is compared with the
/// app's answer on every call and a disagreement throws, so the numbers
/// below are never a reading of the matcher that the matcher does not
/// share.
class PortionMatch {
  final int index;
  final MealPortionEntity portion;

  /// Another row scored the same, and the tie rule decided.
  final bool tie;
  final List<MealPortionEntity> tiedWith;

  /// The middle-rung rule fired: there was a tie, and the winner is a
  /// tied row whose English label names the middle of a size ladder. When
  /// it fired the earlier-row fallback was not consulted; whether it
  /// would have chosen differently is [movedByMiddleRung].
  final bool middleRung;

  /// The middle-rung rule picked a row the earlier-row fallback would not
  /// have: the winner is not the first of the tied rows.
  final bool movedByMiddleRung;

  /// False when no word of the text is a word of the winning label as
  /// written and the hit came through the matcher's two-letter inflection
  /// bound instead — `slice` on `1 slices`, `cup` on `cups`. Together with
  /// [tie] this is the false-match surface #1160 asks the report to show:
  /// the hits where the matcher's docstring says a wrong row is possible.
  final bool literal;

  const PortionMatch({
    required this.index,
    required this.portion,
    required this.tie,
    required this.tiedWith,
    required this.middleRung,
    required this.movedByMiddleRung,
    required this.literal,
  });

  /// A hit worth a second look: decided by row order, or not on the word
  /// as written.
  bool get suspect => tie || !literal;

  Map<String, Object?> toJson() => {
    'index': index,
    'label': portion.label,
    'englishLabel': portion.englishLabel,
    'gramWeight': portion.gramWeight,
    'tie': tie,
    'tiedWith': [for (final p in tiedWith) p.label],
    'middleRung': middleRung,
    'movedByMiddleRung': movedByMiddleRung,
    'literal': literal,
  };
}

/// `_words` (portion_match.dart:46-50): the tokens of a text the matcher
/// sees — runs of letters of at least three, lower-cased.
Set<String> _words(String text) => text
    .toLowerCase()
    .split(RegExp(r'[^\p{L}]+', unicode: true))
    .where((w) => w.length >= 3)
    .toSet();

/// `_termsOf` (portion_match.dart:55-56): the words of a label worth
/// matching on, parentheticals removed first. Restated to score a row and
/// to say whether a hit was literal.
Set<String> matcherWords(String label) =>
    _words(label.replaceAll(RegExp(r'\([^)]*\)'), ' '));

/// `_matches` (portion_match.dart:59-65): the term, or either the other
/// with at most two letters of ending.
bool _termMatches(String token, String term) {
  if (token == term) return true;
  if (token.startsWith(term) && token.length - term.length <= 2) return true;
  return term.startsWith(token) && term.length - token.length <= 2;
}

/// The matcher's score for one row (portion_match.dart:118-121): the
/// lengths of the label's terms that some token of [tokens] matches.
int _termScore(Set<String> tokens, String label) {
  var score = 0;
  for (final term in matcherWords(label)) {
    if (tokens.any((t) => _termMatches(t, term))) score += term.length;
  }
  return score;
}

/// `_englishLabelOf` (portion_match.dart:70-71).
String _englishLabelOf(MealPortionEntity p) => p.englishLabel ?? p.label;

/// `_middleRungWords` (portion_match.dart:135).
const _middleRungWords = {'medium', 'regular'};

/// A model's key against the food's portions, as `_initialUnit` tries it
/// first (bulk_add_bloc.dart:621-623): `matchPortionToKey`, the English
/// label.
PortionMatch? matchKey(String key, List<MealPortionEntity> portions) =>
    _detail(key, portions, _englishLabelOf, matchPortionToKey(key, portions));

/// The query words against the food's portions, as `_initialUnit` tries
/// them when the key missed: `matchPortionToQuery`, the label as it
/// arrived.
PortionMatch? matchQueryWords(String query, List<MealPortionEntity> portions) =>
    _detail(
      query,
      portions,
      (p) => p.label,
      matchPortionToQuery(query, portions),
    );

PortionMatch? _detail(
  String text,
  List<MealPortionEntity> portions,
  String Function(MealPortionEntity) labelOf,
  int? answer,
) {
  // `_match` (portion_match.dart:106-131), restated to see the tie.
  final tokens = _words(text);
  var bestScore = 0;
  final tied = <int>[];
  for (var i = 0; i < portions.length; i++) {
    final score = tokens.isEmpty ? 0 : _termScore(tokens, labelOf(portions[i]));
    if (score == 0 || score < bestScore) continue;
    if (score > bestScore) {
      bestScore = score;
      tied.clear();
    }
    tied.add(i);
  }
  int? rung;
  for (final i in tied) {
    if (matcherWords(_englishLabelOf(portions[i])).any(_middleRungWords.contains)) {
      rung = i;
      break;
    }
  }
  final predicted = tied.isEmpty ? null : (rung ?? tied.first);
  if (predicted != answer) {
    throw StateError(
      'portion_match parity: the restated score predicts $predicted, the '
      'app answered $answer for "$text" over ${portions.length} rows',
    );
  }
  if (answer == null) return null;
  final winner = portions[answer];
  return PortionMatch(
    index: answer,
    portion: winner,
    tie: tied.length > 1,
    tiedWith: [for (final i in tied) if (i != answer) portions[i]],
    middleRung: tied.length > 1 && rung != null,
    movedByMiddleRung: tied.length > 1 && answer != tied.first,
    literal: tokens.intersection(matcherWords(labelOf(winner))).isNotEmpty,
  );
}

/// `BulkAddRow.portionKeyMissed` (bulk_add_bloc.dart:203-211), conjunct for
/// conjunct: a key was given; the row resolved; not a photo read; a count
/// was stated; the lookup did not fail and the food has portions to choose
/// from; and neither the key (English label) nor the query words (the
/// label as it arrived) name one of them. [food] null is an unresolved
/// row, which the getter's `food == null` guard answers false.
bool rowPortionKeyMissed({
  required String? key,
  required String query,
  required double? quantity,
  required bool fromPhoto,
  required List<MealPortionEntity>? food,
  required bool portionsUnavailable,
}) {
  if (key == null || food == null || fromPhoto) return false;
  if (quantity == null) return false;
  if (portionsUnavailable || food.isEmpty) return false;
  return matchPortionToKey(key, food) == null &&
      matchPortionToQuery(query, food) == null;
}

/// Which step of `BulkAddBloc._initialUnit` (bulk_add_bloc.dart:594-646)
/// names the row's unit, for a resolved food.
enum InitialUnitStep {
  /// A unit was stated, and it is the unit (:599-600).
  statedUnit,

  /// A count and a key that named a row: `matchPortionToKey` (:615-624).
  key,

  /// A count, a key that missed or none, and query words that named a row:
  /// `matchPortionToQuery` (:621-624).
  queryWords,

  /// A count, no row named, and a scalable serving: `serving` (:638-640).
  serving,

  /// The record's serving unit, or the g/ml or oz fallback (:642-645).
  fallback,
}

/// The step that decides, and the portion index when it is a match.
InitialUnitStep initialUnitStep({
  required String? unit,
  required double? quantity,
  required String? key,
  required String query,
  required List<MealPortionEntity> portions,
  required double? servingQuantity,
}) {
  if (unit != null) return InitialUnitStep.statedUnit;
  if (quantity != null) {
    if (matchPortionToKey(key, portions) != null) return InitialUnitStep.key;
    if (matchPortionToQuery(query, portions) != null) {
      return InitialUnitStep.queryWords;
    }
    if (servingQuantity != null) return InitialUnitStep.serving;
  }
  return InitialUnitStep.fallback;
}

/// Why the photo guard (#1156) dropped a key, or `kept`.
enum PhotoGuardVerdict {
  kept,
  noKey,
  unit,
  fraction,
  noCount,
  containerWord,
  pieceWord,
  sizeLikeNotOneOfThree,
  otherWord,
}

/// What the guard leaves on the row.
class PhotoGuardResult {
  final double? quantity;
  final String? portion;
  final PhotoGuardVerdict verdict;

  const PhotoGuardResult(this.quantity, this.portion, this.verdict);
}

/// The #1156 rule as the app ships it — `_countsOnly` then `_sizesOnly` in
/// `model_meal_photo_interpreter.dart` (:107-162) — applied to a validated
/// item, the `parsed` those guards see after `validateParsedMealItems`,
/// with the one thing they do not say: *why* a key was dropped.
///
/// - a unit strips the count, and the key goes with it (:111-114, :159);
/// - a fraction strips the count, and the key goes with it (:120-121);
/// - no count: the key is dropped, size word or not (:159);
/// - a whole count with a key that, trimmed and lower-cased, is exactly
///   `small`, `medium` or `large`: kept, normalised (:160-161);
/// - a whole count with any other key: the count stays, the key is null.
///
/// The photo harness runs the interpreter itself, so the app's own output
/// is on every item beside this; the two are compared and a disagreement
/// is counted.
PhotoGuardResult applyPhotoGuard({
  required double? quantity,
  required String? unit,
  required String? portion,
}) {
  final key = portion?.trim().toLowerCase();
  if (unit != null) {
    return PhotoGuardResult(
      null,
      null,
      key == null ? PhotoGuardVerdict.noKey : PhotoGuardVerdict.unit,
    );
  }
  if (quantity != null && quantity != quantity.roundToDouble()) {
    return PhotoGuardResult(
      null,
      null,
      key == null ? PhotoGuardVerdict.noKey : PhotoGuardVerdict.fraction,
    );
  }
  if (key == null || key.isEmpty) {
    return PhotoGuardResult(quantity, null, PhotoGuardVerdict.noKey);
  }
  if (quantity == null) {
    return const PhotoGuardResult(null, null, PhotoGuardVerdict.noCount);
  }
  if (photoSizeWords.contains(key)) {
    return PhotoGuardResult(quantity, key, PhotoGuardVerdict.kept);
  }
  final verdict = _containerWord.hasMatch(key)
      ? PhotoGuardVerdict.containerWord
      : _pieceWord.hasMatch(key)
      ? PhotoGuardVerdict.pieceWord
      : _sizeLikeWord.hasMatch(key)
      ? PhotoGuardVerdict.sizeLikeNotOneOfThree
      : PhotoGuardVerdict.otherWord;
  return PhotoGuardResult(quantity, null, verdict);
}

/// The old harness's invariants, unchanged: must hold for any input at all.
/// Returns the violations found.
List<String> invariants(String input, MealTextParseResult r) {
  final bad = <String>[];
  final nutrition = RegExp(
    r'\b(kcal|calorie|calories|kilojoule|kj)\b',
    caseSensitive: false,
  );
  for (final item in r.items) {
    if (item.query.trim().isEmpty) bad.add('empty query');
    if (nutrition.hasMatch(item.query)) {
      bad.add('nutrition word in query "${item.query}"');
    }
    if (RegExp(r'^\s*\d').hasMatch(item.query)) {
      bad.add('query starts with a digit: "${item.query}"');
    }
    final u = item.unit;
    if (u != null && !validatedUnits.contains(u)) {
      bad.add('unit "$u" outside the app set');
    }
    final q = item.quantity;
    if (q != null && (!q.isFinite || q <= 0 || q > 10000)) {
      bad.add('quantity $q out of range after validation');
    }
    if (u != null && q == null) bad.add('unit with no quantity');
    final p = item.portion;
    if (p != null && RegExp(r'\d').hasMatch(p)) {
      bad.add('digit in portion key "$p"');
    }
    if (p != null && schemaUnits.contains(p.toLowerCase())) {
      bad.add('unit from the list in portion key "$p"');
    }
  }
  final commas = ','.allMatches(input).length + '，'.allMatches(input).length;
  if (r.items.length > commas + 4) {
    bad.add('${r.items.length} items from a line with $commas separators');
  }
  return bad;
}

/// A raw item as the wire carried it, typed loosely on purpose.
class RawItem {
  final String? query;
  final double? quantity;
  final String? unit;
  final String? portion;
  final Map<String, Object?> json;

  RawItem(this.json)
    : query = json['query'] is String ? json['query'] as String : null,
      quantity = switch (json['quantity']) {
        num n => n.toDouble(),
        String s => double.tryParse(s.replaceAll(',', '.')),
        _ => null,
      },
      unit = json['unit'] is String ? json['unit'] as String : null,
      portion = json['portion'] is String ? json['portion'] as String : null;
}

/// The raw item behind each validated item, by position; null where none
/// could be paired.
///
/// Both steps between the wire and `validated` keep order and only ever
/// drop: `mealItemsFromJson` skips an entry that is not a map or has no
/// string `query`, and `validateParsedMealItems` builds its list in one
/// forward pass over its candidates, `continue`-ing past an invalid name or
/// a count out of bounds (`meal_text_parser.dart`, the loop in
/// `validateParsedMealItems`). So the validated list is a subsequence of
/// the raw one, and a cursor walked forward over the raw items pairs each
/// validated item with the next raw item whose query, trimmed as the
/// validator trims it, is the validated query — the whitespace that made
/// an exact comparison lose `egg ` no longer matters, and two items with
/// the same query pair with their own entries rather than both with the
/// first. Should the walk fail — a client that reorders, say — a raw item
/// not yet taken whose query matches trimmed and case-folded is used; and
/// failing that the slot is null, never silently skipped: the caller
/// records the item flagged.
List<RawItem?> pairRawItems(
  List<Map<String, Object?>> rawItems,
  List<ParsedMealItem> validated,
) {
  final raw = rawItems.map(RawItem.new).toList();
  final taken = List<bool>.filled(raw.length, false);
  final out = <RawItem?>[];
  var cursor = 0;
  for (final item in validated) {
    RawItem? found;
    for (var i = cursor; i < raw.length; i++) {
      if (raw[i].query?.trim() == item.query) {
        found = raw[i];
        taken[i] = true;
        cursor = i + 1;
        break;
      }
    }
    if (found == null) {
      final wanted = item.query.trim().toLowerCase();
      for (var i = 0; i < raw.length; i++) {
        if (!taken[i] && raw[i].query?.trim().toLowerCase() == wanted) {
          found = raw[i];
          taken[i] = true;
          break;
        }
      }
    }
    out.add(found);
  }
  return out;
}

// --- small statistics and markdown helpers -------------------------------

int percentile(List<int> sorted, double p) =>
    sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * p).round()];

String pct(int part, int whole) =>
    whole == 0 ? '–' : '${(100 * part / whole).toStringAsFixed(1)}%';

String ratio(int part, int whole) => '$part/$whole (${pct(part, whole)})';

/// A markdown table. Cells are escaped for the pipe.
String table(List<String> header, List<List<Object?>> rows) {
  String cell(Object? v) =>
      (v ?? '').toString().replaceAll('|', r'\|').replaceAll('\n', ' ');
  final b = StringBuffer()
    ..writeln('| ${header.map(cell).join(' | ')} |')
    ..writeln('| ${header.map((_) => '---').join(' | ')} |');
  for (final row in rows) {
    b.writeln('| ${row.map(cell).join(' | ')} |');
  }
  return b.toString();
}

String code(Object? v) => v == null ? '–' : '`$v`';
