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
/// `steering` is one of the eight; `inputWord` is the measure word the line
/// itself carried (or an inflection of it), which is the failure #1157 names
/// — "a model that answers *Scheibe* to a German line"; `asciiOther` is
/// English-shaped and unverified (the long tail: "wedge", "can"); `nonAscii`
/// cannot be English.
enum KeyLanguage { steering, inputWord, asciiOther, nonAscii }

KeyLanguage keyLanguage(String key, {String? inputMeasureWord}) {
  final k = key.trim().toLowerCase();
  if (steeringWords.contains(k)) return KeyLanguage.steering;
  if (inputMeasureWord != null) {
    final w = inputMeasureWord.toLowerCase();
    if (_inflectionOf(k, w)) return KeyLanguage.inputWord;
  }
  return isAsciiLetters(k) ? KeyLanguage.asciiOther : KeyLanguage.nonAscii;
}

bool _inflectionOf(String a, String b) {
  if (a == b) return true;
  if (a.length < 3 || b.length < 3) return false;
  final shorter = a.length <= b.length ? a : b;
  final longer = a.length <= b.length ? b : a;
  return longer.startsWith(shorter) && longer.length - shorter.length <= 2;
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

/// `matchPortionToQuery` plus the one thing it does not report: whether the
/// winner won on a tie.
///
/// The matcher scores a portion by the length of its longest matched term
/// and gives ties to the earlier row. Those lengths are private to it, so the
/// tie is recovered through the public function alone: for the winner `i`
/// and another row `j`, `[j, i]` resolving to `j` means score(j) >= score(i),
/// and `[i, j]` resolving to `i` means score(i) >= score(j); both together
/// mean equal — a tie, decided by order.
class PortionMatch {
  final int index;
  final MealPortionEntity portion;
  final bool tie;
  final List<MealPortionEntity> tiedWith;

  const PortionMatch({
    required this.index,
    required this.portion,
    required this.tie,
    required this.tiedWith,
  });

  Map<String, Object?> toJson() => {
    'index': index,
    'label': portion.label,
    'gramWeight': portion.gramWeight,
    'tie': tie,
    'tiedWith': [for (final p in tiedWith) p.label],
  };
}

PortionMatch? matchWithTie(String key, List<MealPortionEntity> portions) {
  final index = matchPortionToQuery(key, portions);
  if (index == null) return null;
  final winner = portions[index];
  final tied = <MealPortionEntity>[];
  for (var j = 0; j < portions.length; j++) {
    if (j == index) continue;
    final other = portions[j];
    final otherFirst = matchPortionToQuery(key, [other, winner]);
    final winnerFirst = matchPortionToQuery(key, [winner, other]);
    if (otherFirst == 0 && winnerFirst == 0) tied.add(other);
  }
  return PortionMatch(
    index: index,
    portion: winner,
    tie: tied.isNotEmpty,
    tiedWith: tied,
  );
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

/// The #1156 rule, exactly as decided, applied to a validated item — the
/// `parsed` the app's guard would see, after `validateParsedMealItems` and
/// before the row is built:
///
/// - a unit strips the count, and the key goes with it;
/// - a fraction strips the count, and the key goes with it;
/// - no count: the key is dropped, size word or not;
/// - a whole count with a key that, trimmed and lower-cased, is exactly
///   `small`, `medium` or `large`: kept, normalised;
/// - a whole count with any other key: the count stays, the key is null.
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
