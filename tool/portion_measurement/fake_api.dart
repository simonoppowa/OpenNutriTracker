// A `MealItemsApi` that answers from a table instead of a model, so both
// harnesses can be run end to end — resolve, portions, match, tie, guard,
// report — without a single provider call.
//
// It is deliberately not a good model. Every branch the report has a column
// for is produced on purpose: the English key, the key in the line's own
// language, an abbreviation left as written, a unit substituted for a
// household measure, no key at all, a key on a line that named no measure,
// one line that fails outright; and on the photo side a container word, a
// piece word, a word of neither kind, a size on a fraction, a size beside a
// unit, a size with no count, `extra large`, a size that ties two rows, and
// the three words that survive. Which branch a line gets is a hash of the
// line, so a dry run is reproducible and a repeat of the same line answers
// the same way — except one photo, whose third pass moves, and two text
// lines whose third repeat moves (one the key alone, one the count), so
// the stability columns are exercised too.

import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

import 'corpus.dart';
import 'providers.dart';

class FakeMealItemsApi implements MealItemsApi, RawReplySource {
  final _raw = <({String needle, List<Map<String, Object?>> items})>[];
  final _photoPasses = <String, int>{};
  final _photoOrder = <String, int>{};
  final _textAsks = <String, int>{};
  String? _failingLine;
  var _keyMoved = false;
  var _countMoved = false;
  var calls = 0;

  @override
  Future<MealTextParseResult> requestItems({
    required MealContent content,
    required String system,
  }) async {
    calls++;
    final List<Map<String, Object?>> items;
    final String needle;
    final String? statedIn;
    switch (content) {
      case MealTextContent(:final text):
        needle = textNeedle(text);
        final ask = (_textAsks[needle] ?? 0) + 1;
        _textAsks[needle] = ask;
        // One line fails, every time it is asked: the first seen whose
        // hash lands on 3, so the harness's failure path runs once per
        // provider without a retry pause (the failure is not transient).
        _failingLine ??= _hash(text) % 10 == 3 ? text : null;
        if (text == _failingLine) {
          throw const MealInterpreterException(
            'the fake refuses this line',
            failure: MealInterpreterFailure.rejected,
            statusCode: 400,
          );
        }
        items = _textReply(text);
        // The third repeat of a line moves, once for the key alone and once
        // for the count, so both stability rows have something to show.
        // Ask 4 is the third of the stability probe's three; the corpus
        // pass was ask 1.
        if (ask == 4 && items.isNotEmpty) _moveOnce(items.first);
        statedIn = text;
      case MealPhotoContent(:final base64Data):
        needle = photoNeedle(base64Data);
        final pass = (_photoPasses[needle] ?? 0) + 1;
        _photoPasses[needle] = pass;
        _photoOrder[needle] ??= _photoOrder.length;
        items = _photoReply(_photoOrder[needle]!, pass);
        statedIn = null;
    }
    _raw.add((needle: needle, items: items));
    // The same two steps every real client takes after decoding.
    return validateParsedMealItems(
      mealItemsFromJson(items),
      statedIn: statedIn,
    );
  }

  @override
  List<Map<String, Object?>>? takeRawItems(String needle) {
    final i = _raw.indexWhere((r) => r.needle == needle);
    if (i < 0) return null;
    return _raw.removeAt(i).items;
  }

  void _moveOnce(Map<String, Object?> first) {
    if (!_keyMoved && first['portion'] is String) {
      first['portion'] = first['portion'] == 'piece' ? 'slice' : 'piece';
      _keyMoved = true;
    } else if (!_countMoved && first['quantity'] is num) {
      first['quantity'] = (first['quantity'] as num) + 1;
      _countMoved = true;
    }
  }

  /// Deterministic per line: a stable hash picks the branch.
  static int _hash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  /// Every written form of every measure word of every locale, longest
  /// first so "столова ложка" wins over "ложка"-shaped matches, "Esslöffel"
  /// over "EL" and "kleines" over "kleine".
  static final _vocabulary = () {
    final all = <(String word, String locale, Measure m)>[];
    for (final e in measures.entries) {
      for (final m in e.value) {
        for (final form in m.forms) {
          all.add((form, e.key, m));
        }
      }
    }
    all.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return all;
  }();

  List<Map<String, Object?>> _textReply(String text) {
    final parsed = parseMealText(text);
    final h = _hash(text);
    final out = <Map<String, Object?>>[];
    for (final (i, item) in parsed.items.indexed) {
      final query = item.query;
      final found = _findMeasure(query);
      final map = <String, Object?>{};
      if (found == null) {
        map['query'] = query;
        if (item.quantity != null) map['quantity'] = item.quantity;
        if (item.unit != null) map['unit'] = item.unit;
        // A key nobody asked for, now and then, so the report's "key on a
        // line that named no measure" row is not empty by construction.
        if (h % 10 == 5 && i == 0) map['portion'] = 'piece';
        out.add(map);
        continue;
      }
      final (word, _, measure) = found;
      final food = _stripMeasure(query, word);
      if (food.isEmpty && out.isNotEmpty && !out.last.containsKey('portion')) {
        // "olive oil, 4 handfuls": the measure names the item before it.
        out.last.remove('unit');
        map.addAll(out.removeLast());
      } else {
        map['query'] = food.isEmpty ? query : food;
      }
      final quantity = item.quantity ?? 1.0;
      if (measure.abbreviation && h % 3 == 0) {
        // An abbreviation left as written, which the prompt says to expand.
        // Its own draw, on the abbreviation lines alone: as one case of the
        // ten below it never once fell on an abbreviation line of the
        // default corpus.
        map['quantity'] = quantity;
        map['portion'] = word;
        out.add(map);
        continue;
      }
      switch (h % 10) {
        case 6:
          // The failure #1157 names: the key in the line's own language —
          // as its lemma, the way a model answers *Glas* to *Gläser* and
          // *tazza* to *tazze*, so the language test has a stem change to
          // recognise and not only the word as written.
          map['quantity'] = quantity;
          map['portion'] = measure.singular;
        case 8:
          // No key at all.
          map['quantity'] = quantity;
        case 9:
          // A unit from the list substituted for the household measure.
          map['quantity'] = quantity;
          map['unit'] = 'g';
        default:
          map['quantity'] = quantity;
          map['portion'] = h % 10 == 4 ? ' ${measure.key.toUpperCase()} ' : measure.key;
      }
      out.add(map);
    }
    return out;
  }

  static (String, String, Measure)? _findMeasure(String query) {
    final lower = query.toLowerCase();
    final letter = RegExp(r'\p{L}', unicode: true);
    for (final entry in _vocabulary) {
      final w = entry.$1.toLowerCase();
      final at = lower.indexOf(w);
      if (at < 0) continue;
      final before = at == 0 ? ' ' : lower[at - 1];
      final afterAt = at + w.length;
      final after = afterAt >= lower.length ? ' ' : lower[afterAt];
      if (_hanScript.hasMatch(w)) {
        // A Chinese measure is one character that also occurs inside food
        // names (大 in 意大利面), so it counts only after a count or 个.
        if (!RegExp(r'[0-9个]').hasMatch(before)) continue;
      } else if (letter.hasMatch(before) || letter.hasMatch(after)) {
        // Latin and Cyrillic words must stand alone.
        continue;
      }
      return entry;
    }
    return null;
  }

  static final _hanScript = RegExp(r'\p{Script=Han}', unicode: true);

  static String _stripMeasure(String query, String word) {
    var s = query.replaceFirst(
      RegExp(RegExp.escape(word), caseSensitive: false),
      ' ',
    );
    // The template scaffolding around the food, as a model would drop it.
    s = s.replaceFirst(
      RegExp(
        r'^\s*(i had|ich hatte|k snídani|na śniadanie|na raňajky|kahvaltıda|'
        r'на сніданок|早餐)\s*',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceFirst(RegExp(r'^\s*\d+\s*'), '');
    s = s.replaceFirst(
      RegExp(
        r'^\s*(a|an|one|ein|eine|una|un|jedno|bir|одне|of|di)\s+',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceFirst(RegExp(r'^\s*(of|di)\s+', caseSensitive: false), '');
    s = s.replaceFirst(
      RegExp(
        r'\s+(and coffee|und Kaffee|for breakfast|zum Frühstück)$',
        caseSensitive: false,
      ),
      '',
    );
    return s
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '')
        .trim();
  }

  /// One canned plate per photo, taken in turn in the order the photos are
  /// first seen — the set is read sorted, so the same photo gets the same
  /// plate every run — and every plate is served as long as the set has at
  /// least ten photos. A hash of the bytes was tried first and left two
  /// branches unserved.
  List<Map<String, Object?>> _photoReply(int order, int pass) {
    switch (order % 10) {
      case 0:
        return [
          {'query': 'egg', 'quantity': 2, 'portion': 'large'},
          {'query': 'toast', 'quantity': 2, 'portion': 'slice'},
          {'query': 'orange juice'},
        ];
      case 1:
        return [
          {'query': 'rice', 'quantity': 2, 'portion': 'cup'},
          {'query': 'chicken breast', 'quantity': 1},
        ];
      case 2:
        return [
          {'query': 'banana', 'quantity': 1.5, 'portion': 'large'},
          {'query': 'yogurt'},
        ];
      case 3:
        return [
          {'query': 'salad', 'quantity': 200, 'unit': 'g', 'portion': 'medium'},
          {'query': 'bread', 'quantity': 1, 'portion': 'LARGE '},
        ];
      case 4:
        return [
          {'query': 'apple', 'portion': 'large'},
          {'query': 'almonds', 'portion': 'handful'},
        ];
      case 5:
        return [
          {'query': 'pizza', 'quantity': 3, 'portion': 'extra large'},
          {'query': 'salad', 'quantity': 1, 'portion': 'bowl'},
        ];
      case 6:
        return [
          {'query': 'egg', 'quantity': 3, 'portion': 'small'},
          {'query': 'bacon', 'quantity': 4},
          {'query': 'coffee', 'quantity': 1, 'portion': 'mug'},
        ];
      case 7:
        // The one plate whose third pass moves.
        if (pass == 3) {
          return [
            {'query': 'pancakes', 'quantity': 4, 'portion': 'medium'},
          ];
        }
        return [
          {'query': 'pancakes', 'quantity': 3, 'portion': 'medium'},
          {'query': 'maple syrup', 'quantity': 2, 'portion': 'tablespoon'},
        ];
      case 8:
        return [
          {'query': 'sushi', 'quantity': 8, 'portion': 'piece'},
          {'query': 'miso soup', 'quantity': 1, 'portion': 'bowl'},
          {'query': 'edamame', 'quantity': 1, 'portion': 'mini'},
        ];
      default:
        // A word of neither kind (`stalk` is in no class of #1155), and a
        // size that ties two rows of the resolved food — `small` on
        // watermelon matches `1 small wedge/slice` and `1 small melon`
        // alike, and row order decides.
        return [
          {'query': 'celery', 'quantity': 2, 'portion': 'stalk'},
          {'query': 'watermelon', 'quantity': 1, 'portion': 'small'},
        ];
    }
  }
}
