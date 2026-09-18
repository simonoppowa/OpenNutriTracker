// Resolves a query to the food the app would land on, and fetches that
// food's portions with English labels — through the read-only RPCs the
// measurement is allowed to call.
//
// For an English line the search is `search_food_summary` over PostgREST
// with the anon key, exactly the POST `SpFoodDataSource._searchEnglish`
// makes. For any other locale it is what `fetchSearchWordResults` does for
// a user of that app language: `search_food_translation(term, loc)` first,
// the matched rows ranked and cut by `rankAndTruncateTranslationRows`, then
// `food_summary_by_ids` for those ids, the summary rows re-sorted onto the
// translation-relevance order and given the translated name as the shown
// name (`_searchByTranslation`); and when the translation search finds
// nothing, the English search on the same words, as the app falls through.
// Then the AI path's ranking as #1163 read it out of the code, with OFF
// empty and no custom meals, recipes or history:
//
//  1. `rankAndTruncateFoodsByName` — `textRelevanceScore` of the full
//     `name` against the query, stable, descending, the top 20 (the
//     English path; the translation path was cut on its own step above);
//  2. `MealEntity.fromSpFood` — the shown name is `localizedName ??
//     short_title ?? name`, the brand is `brands`, `detailed` is false,
//     `machineTranslatedName` is whether the translation shown came from
//     `food_translation.source = 'machine'`;
//  4. `mergeAndRankMeals` — `scoreMealRelevance` on the shown name and
//     brand, records sharing a normalized shown name (and brand, where
//     both name one) collapsed to the highest-scoring (first seen on a
//     tie), a stable sort, then `rankForResolution`'s soft Dice, stable
//     again — and index 0 is the food.
//
// Step 3, the search-cache round trip, is not modelled here either, for
// the reason #1163 gives: it can only reorder equal-scoring siblings, and
// the winner's *group* is fixed by the shown name. The portions are
// `portions_by_food_ids(ids, 'en')` on every path, so every label is the
// English `portion_description` the model's key is matched against
// (#1157); the query words are tried against the labels of the line's own
// locale, as the app tries them.
//
// The scorers are copied below rather than imported: `meal_relevance_ranker
// .dart` and `resolver_relevance.dart` reach `hive_ce_flutter` through
// `meal_entity.dart` and cannot be compiled by `dart run`; so is the
// decoration and re-sort of `_searchByTranslation`, which is private and
// needs a `SupabaseClient`. The copies, [aiPathWinner]'s truncation,
// collapse, tie and shown-name rules, and [translationPage]'s order and
// names are pinned to the originals by
// `test/unit_test/portion_measurement_parity_test.dart`. The RPC names and
// the locale mapping are the app's own `SPConst`, imported.

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

import 'cli.dart';

/// `SPConst.maxNumberOfItems * 5`, the pool `_searchEnglish` asks for, and
/// `SPConst.maxNumberOfItems`, what it keeps.
const candidatePoolSize = 100;
const maxNumberOfItems = 20;

/// Which search the record came out of: the English `search_food_summary`
/// (an English line), the locale's `search_food_translation` (a non-English
/// line the translation search answered), or the English search reached by
/// falling through when the translation search found nothing.
enum ResolvePath { english, translation, englishFallback }

/// The record the ranker put first, and everything the report needs to
/// name it.
class ResolvedFood {
  final int foodId;
  final String name;
  final String? shortTitle;
  final String source;
  final ResolvePath path;

  /// The `food_translation` locale the search ran in; null for English.
  final String? locale;

  /// The translated description the app shows for this record, when it
  /// came through the translation search; the shown name is then this, not
  /// the short title.
  final String? localizedName;

  /// Whether that translation is an unreviewed machine one, which both
  /// rankers dock 0.03 for.
  final bool machineTranslated;

  /// `scoreMealRelevance` of the shown name, the score the collapse kept.
  final double score;

  /// Rows the search returned before the cut to 20: `search_food_summary`'s
  /// on the English path, `search_food_translation`'s on the other.
  final int poolSize;

  /// The full name of the record step 1 put first, when it is not this one
  /// — the difference between "the best-ranked row" and "what the AI path
  /// lands on".
  final String? poolTopName;

  /// How many of the 20 shared this record's shown name and collapsed into
  /// it. More than one means the sibling the app picks is the cache's call.
  final int groupSize;
  final List<MealPortionEntity> portions;

  const ResolvedFood({
    required this.foodId,
    required this.name,
    required this.shortTitle,
    required this.source,
    required this.path,
    required this.locale,
    required this.localizedName,
    required this.machineTranslated,
    required this.score,
    required this.poolSize,
    required this.poolTopName,
    required this.groupSize,
    required this.portions,
  });

  /// What the app's list shows for the record, `SpFoodDTO.displayName`.
  String get shownName => localizedName ?? shortTitle ?? name;

  Map<String, Object?> toJson() => {
    'foodId': foodId,
    'name': name,
    'shortTitle': shortTitle,
    'source': source,
    'path': path.name,
    'locale': locale,
    'localizedName': localizedName,
    'machineTranslated': machineTranslated,
    'score': score,
    'poolSize': poolSize,
    'poolTopName': poolTopName,
    'groupSize': groupSize,
    'portions': [
      for (final p in portions) {'label': p.label, 'gramWeight': p.gramWeight},
    ],
  };
}

/// The backend could not answer. Carries the function and the kind of
/// failure and nothing else: an `http.ClientException` prints its URI,
/// which here is the project URL, and that must not reach a log or a
/// report. A caller records the item as unchecked and carries on, so one
/// backend blip mid-run does not throw away every provider reply already
/// paid for.
class BackendException implements Exception {
  final String fn;
  final String kind;

  const BackendException(this.fn, this.kind);

  @override
  String toString() => 'backend $fn failed: $kind';
}

/// Caches per locale and query, so a corpus that names the same forty
/// foods a few hundred times makes a few dozen backend calls.
class FoodResolver {
  final http.Client _client;
  final SupabaseAccess _access;
  /// Futures rather than values, so two lanes asking for the same food at
  /// the same moment share one call.
  final _cache = <String, Future<ResolvedFood?>>{};
  final _localized = <String, Future<List<MealPortionEntity>>>{};
  var rpcCalls = 0;
  var backendFailures = 0;

  FoodResolver(this._client, this._access);

  int get distinctQueries => _cache.length;

  /// The food [query] lands on for a user whose app language is [locale],
  /// or null when the search returned nothing. English searches
  /// `search_food_summary`; every other locale searches the translation
  /// table first and falls through to the English search when it finds
  /// nothing, as `fetchSearchWordResults` does. Throws [BackendException]
  /// when the backend did not answer; the failed lookup is not cached, so a
  /// later item asking for the same food tries again.
  Future<ResolvedFood?> resolve(String query, {String locale = 'en'}) {
    final term = query.trim();
    if (term.isEmpty) return Future.value(null);
    final loc = SPConst.translationLocaleOf(SupportedLanguage.fromCode(locale));
    final key = '${loc ?? 'en'}|${term.toLowerCase()}';
    final pending = _cache.putIfAbsent(key, () => _resolveUncached(term, loc));
    return pending.catchError((Object e) {
      _cache.remove(key);
      throw e;
    });
  }

  /// The portions of [foodId] as the app fetches them for a user whose app
  /// language is [loc] — a verified translation where one exists, English
  /// otherwise — which is what the query words are matched against.
  Future<List<MealPortionEntity>> localizedPortions(int foodId, String loc) {
    final key = '$foodId|$loc';
    final pending = _localized.putIfAbsent(key, () => _portions(foodId, loc));
    return pending.catchError((Object e) {
      _localized.remove(key);
      throw e;
    });
  }

  Future<ResolvedFood?> _resolveUncached(String query, String? loc) async {
    if (loc != null) {
      final page = await _translationPage(query, loc);
      // The app returns the localized page when it has anything in it and
      // runs the English search only when it is empty.
      if (page.candidates.isNotEmpty) {
        return _land(page.candidates, page.poolSize, query, ResolvePath.translation, loc);
      }
    }
    final rows = await _rpc(SPConst.searchFoodSummaryFn, {
      'term': query,
      'sources': null,
      'max_rows': candidatePoolSize,
    });
    return _land(
      englishPage(rows, query),
      rows.length,
      query,
      loc == null ? ResolvePath.english : ResolvePath.englishFallback,
      loc,
    );
  }

  /// `_searchByTranslation`'s two calls, the replay of its decoration and
  /// re-sort between them.
  Future<({List<Candidate> candidates, int poolSize})> _translationPage(
    String query,
    String loc,
  ) async {
    final translationRows = await _rpc(SPConst.searchFoodTranslationFn, {
      'term': query,
      'loc': loc,
      'max_rows': candidatePoolSize,
    });
    if (translationRows.isEmpty) {
      return (candidates: const <Candidate>[], poolSize: 0);
    }
    final ids = translationIds(translationRows, query);
    final summaryRows = await _rpc(SPConst.foodSummaryByIdsFn, {
      'ids': ids,
      'sources': null,
    });
    return (
      candidates: translationPage(translationRows, summaryRows, query),
      poolSize: translationRows.length,
    );
  }

  Future<ResolvedFood?> _land(
    List<Candidate> page,
    int poolSize,
    String query,
    ResolvePath path,
    String? loc,
  ) async {
    final landed = landOn(page, query);
    if (landed == null) return null;
    final id = landed.candidate.row['food_id'];
    if (id is! int) return null;

    final portions = await localizedPortions(id, 'en');

    return ResolvedFood(
      foodId: id,
      name: (landed.candidate.row['name'] as String?) ?? '',
      shortTitle: landed.candidate.row['short_title'] as String?,
      source: (landed.candidate.row['source'] as String?) ?? '',
      path: path,
      locale: loc,
      localizedName: landed.candidate.localizedName,
      machineTranslated: landed.candidate.machineTranslated,
      score: landed.score,
      poolSize: poolSize,
      poolTopName: landed.poolTopName,
      groupSize: landed.groupSize,
      portions: portions,
    );
  }

  Future<List<MealPortionEntity>> _portions(int id, String loc) async {
    final portionRows = await _rpc(SPConst.portionsByFoodIdsFn, {
      'ids': [id],
      'loc': loc,
    });
    final portions = <MealPortionEntity>[];
    for (final row in portionRows) {
      final label = row['label'];
      final grams = row['gram_weight'];
      if (row['food_id'] != id || label is! String || grams is! num) continue;
      if (grams <= 0) continue;
      portions.add(
        MealPortionEntity(
          label: label,
          gramWeight: grams.toDouble(),
          localized: row['localized'] == true,
        ),
      );
    }
    return portions;
  }

  /// One PostgREST RPC: a POST with the parameters as the JSON body, so the
  /// search term never enters a URL (#882). Every way the call can fail is
  /// turned into a [BackendException] naming the function and the kind of
  /// failure, because the `http` exceptions carry the URI in their message.
  Future<List<Map<String, dynamic>>> _rpc(
    String fn,
    Map<String, Object?> params,
  ) async {
    rpcCalls++;
    final anon = _access.anonKey();
    final http.Response response;
    try {
      response = await _client.post(
        _access.projectUrl.replace(path: '/rest/v1/rpc/$fn'),
        headers: {
          'apikey': anon,
          'Authorization': 'Bearer $anon',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(params),
      );
    } on http.ClientException {
      backendFailures++;
      throw BackendException(fn, 'unreachable (ClientException)');
    } on IOException {
      backendFailures++;
      throw BackendException(fn, 'unreachable (IOException)');
    }
    if (response.statusCode != 200) {
      backendFailures++;
      throw BackendException(fn, 'HTTP ${response.statusCode}');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      backendFailures++;
      throw BackendException(fn, 'body is not JSON');
    }
    if (decoded is! List) {
      backendFailures++;
      throw BackendException(fn, 'body is not a list of rows');
    }
    return decoded.cast<Map<String, dynamic>>();
  }
}

/// One record of the page the ranker runs over, as `fromSpFood` reads it:
/// the raw `food_summary` row, the translated name carried over from
/// `food_translation` (null on the English path), and whether that
/// translation is a machine one.
typedef Candidate = ({
  Map<String, dynamic> row,
  String? localizedName,
  bool machineTranslated,
});

/// What [landOn] lands on.
typedef AiPathWinner = ({
  Candidate candidate,
  double score,
  String? poolTopName,
  int groupSize,
});

/// `SpFoodDTO.displayName`: the translation, else the short title, else the
/// full name.
String shownName(Candidate c) =>
    c.localizedName ??
    (c.row['short_title'] as String?) ??
    (c.row['name'] as String?) ??
    '';

String? _brand(Candidate c) => c.row['brands'] as String?;

/// Step 1 of the English path over the raw `search_food_summary` pool:
/// `rankAndTruncateFoodsByName`, the full `name` scored, stable, the top
/// 20. Nothing is translated on this path.
List<Candidate> englishPage(List<Map<String, dynamic>> rows, String query) {
  final ranked = [
    for (final row in rows)
      (row: row, score: textRelevanceScore(row['name'] as String?, query)),
  ];
  mergeSort(ranked, compare: (a, b) => b.score.compareTo(a.score));
  return [
    for (final entry in ranked.take(maxNumberOfItems))
      (row: entry.row, localizedName: null, machineTranslated: false),
  ];
}

/// The English path end to end: [englishPage], then [landOn]. A top-level
/// function so the parity test can run it beside the app's own pipeline on
/// the same rows.
AiPathWinner? aiPathWinner(List<Map<String, dynamic>> rows, String query) =>
    landOn(englishPage(rows, query), query);

/// The food ids `_searchByTranslation` asks `food_summary_by_ids` for, in
/// the order it asks: `rankAndTruncateTranslationRows` over the
/// `search_food_translation` rows — `textRelevanceScore` of the translated
/// description, stable, the top 20 — then the distinct ids in that order.
List<int> translationIds(List<Map<String, dynamic>> translationRows, String query) =>
    _decorate(translationRows, query).nameByFoodId.keys.toList();

/// The page `_searchByTranslation` returns for [summaryRows] fetched by
/// [translationIds]: each summary row given the translated description as
/// its shown name and the machine flag of its translation, then re-sorted
/// onto the translation-relevance order — a row whose id the translation
/// rows did not name sorts last, untranslated. Empty when the summary
/// fetch returned nothing, which is when the app falls through to English.
List<Candidate> translationPage(
  List<Map<String, dynamic>> translationRows,
  List<Map<String, dynamic>> summaryRows,
  String query,
) {
  final d = _decorate(translationRows, query);
  final rankByFoodId = {
    for (final (rank, foodId) in d.nameByFoodId.keys.indexed) foodId: rank,
  };
  int rank(Candidate c) => rankByFoodId[c.row['food_id']] ?? rankByFoodId.length;
  final page = [
    for (final row in summaryRows)
      (
        row: row,
        localizedName: d.nameByFoodId[row['food_id']],
        machineTranslated: d.machineIds.contains(row['food_id']),
      ),
  ];
  mergeSort(page, compare: (a, b) => rank(a).compareTo(rank(b)));
  return page;
}

/// The two maps `_searchByTranslation` builds from the ranked translation
/// rows, with the map literal's semantics kept: a food id named twice keeps
/// its first position and its last description, and is machine-translated
/// if any of its rows is.
({Map<int, String?> nameByFoodId, Set<int> machineIds}) _decorate(
  List<Map<String, dynamic>> translationRows,
  String query,
) {
  final ranked = [
    for (final row in translationRows)
      (
        row: row,
        score: textRelevanceScore(
          row[SPConst.translationDescription] as String?,
          query,
        ),
      ),
  ];
  mergeSort(ranked, compare: (a, b) => b.score.compareTo(a.score));
  final top = [for (final e in ranked.take(maxNumberOfItems)) e.row];
  final nameByFoodId = <int, String?>{};
  final machineIds = <int>{};
  for (final row in top) {
    final id = row[SPConst.translationFoodId] as int;
    nameByFoodId[id] = row[SPConst.translationDescription] as String?;
    if (row[SPConst.translationSource] == SPConst.translationSourceMachine) {
      machineIds.add(id);
    }
  }
  return (nameByFoodId: nameByFoodId, machineIds: machineIds);
}

/// The translation path end to end: [translationPage], then [landOn].
AiPathWinner? translationPathWinner(
  List<Map<String, dynamic>> translationRows,
  List<Map<String, dynamic>> summaryRows,
  String query,
) => landOn(translationPage(translationRows, summaryRows, query), query);

/// Steps 2 and 4 over a page already ordered and cut by its search — what
/// `fromSpFood`, `mergeAndRankMeals` and `rankForResolution` do to it — or
/// null for an empty page.
AiPathWinner? landOn(List<Candidate> page, String query) {
  if (page.isEmpty) return null;
  final poolTop = page.first;

  // 2 + 4. Shown name and brand, scoreMealRelevance on them, collapse by
  // `_nearDuplicateKey` keeping the highest (strict >, so first seen on a
  // tie).
  final groupOrder = <String>[];
  final groups = <String, List<({Candidate c, double score})>>{};
  for (final c in page) {
    final key = nearDuplicateKey(shownName(c), _brand(c), c.row);
    final scored = (
      c: c,
      score: scoreMealRelevance(
        shownName(c),
        query,
        brand: _brand(c),
        machineTranslated: c.machineTranslated,
      ),
    );
    if (!groups.containsKey(key)) groupOrder.add(key);
    groups.putIfAbsent(key, () => []).add(scored);
  }
  final collapsed = <({Candidate c, double score, int groupSize})>[];
  for (final key in groupOrder) {
    final group = groups[key]!;
    var best = group.first;
    for (final candidate in group.skip(1)) {
      if (candidate.score > best.score) best = candidate;
    }
    collapsed.add((c: best.c, score: best.score, groupSize: group.length));
  }
  // rankMealsByRelevance, then rankForResolution, both stable.
  mergeSort(collapsed, compare: (a, b) => b.score.compareTo(a.score));
  final resolved = [
    for (final c in collapsed)
      (
        c: c,
        r: resolutionScore(
          shownName(c.c),
          query,
          brand: _brand(c.c),
          machineTranslated: c.c.machineTranslated,
        ),
      ),
  ];
  mergeSort(resolved, compare: (a, b) => b.r.compareTo(a.r));
  final winner = resolved.first.c;
  return (
    candidate: winner.c,
    score: winner.score,
    poolTopName: identical(winner.c.row, poolTop.row)
        ? null
        : poolTop.row['name'] as String?,
    groupSize: winner.groupSize,
  );
}

// --- copied from meal_relevance_ranker.dart --------------------------------

/// The two rankers' quality tie-breaker for a machine translation, the
/// only one a backend food can carry (`detailed` is false on every path).
const machineTranslatedPenalty = 0.03;

/// `scoreMealRelevance` from `lib/features/add_meal/util/meal_relevance_ranker.dart`
/// for a backend food: `detailed` false (the parity test pins it to
/// `MealEntity.fromSpFood`), so the score is the name's text score, or the
/// brand's at 60% where that is higher, less the penalty when the shown
/// name is a machine translation.
double scoreMealRelevance(
  String? shownName,
  String query, {
  String? brand,
  bool machineTranslated = false,
}) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return 0.0;
  final nameScore = _textScore(shownName, normalizedQuery);
  final brandScore = _textScore(brand, normalizedQuery);
  var score = nameScore >= brandScore ? nameScore : brandScore * 0.6;
  if (machineTranslated) score -= machineTranslatedPenalty;
  return score.clamp(0.0, 1.0);
}

/// `_nearDuplicateKey` from the same file: the normalized shown name, with
/// the normalized brand appended when there is one; a nameless row keys on
/// `source:code`, which for a backend food is `fdc` and the food id.
String nearDuplicateKey(String? shownName, String? brand, Map<String, dynamic> row) {
  final name = _normalize(shownName);
  if (name.isEmpty) return 'noname:fdc:${row['food_id'] ?? identityHashCode(row)}';
  final b = _normalize(brand);
  return b.isEmpty ? name : '$name|$b';
}

/// `textRelevanceScore` from the same file, verbatim apart from the names.
double textRelevanceScore(String? text, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return 0.0;
  return _textScore(text, normalizedQuery);
}

double _textScore(String? text, String normalizedQuery) {
  final normalizedText = _normalize(text);
  if (normalizedText.isEmpty) return 0.0;
  if (normalizedText == normalizedQuery) return 1.0;

  final textTokens = _tokenize(normalizedText);
  final queryTokens = _tokenize(normalizedQuery);
  final overlap = _diceCoefficient(textTokens, queryTokens);

  final containsBonus = normalizedText.contains(normalizedQuery) ? 0.2 : 0.0;
  final prefixBonus = normalizedText.startsWith(normalizedQuery) ? 0.15 : 0.0;

  return (overlap + containsBonus + prefixBonus).clamp(0.0, 0.9);
}

String _normalize(String? text) =>
    text?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ?? '';

Set<String> _tokenize(String normalizedText) => normalizedText
    .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
    .where((token) => token.isNotEmpty)
    .toSet();

double _diceCoefficient(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  final intersectionSize = a.intersection(b).length;
  return 2 * intersectionSize / (a.length + b.length);
}

// --- copied from resolver_relevance.dart -----------------------------------

/// `scoreMealForResolution` from `lib/features/add_meal/util/resolver_relevance.dart`
/// for a backend food: no `detailed` bonus, so the soft Dice of the shown
/// name, or the brand's at 60% where that is higher, less the penalty when
/// the shown name is a machine translation.
double resolutionScore(
  String? shownName,
  String query, {
  String? brand,
  bool machineTranslated = false,
}) {
  final queryTokens = _tokenize(_normalize(query));
  if (queryTokens.isEmpty) return 0.0;
  final nameScore = _resolutionTextScore(shownName, queryTokens);
  final brandScore = _resolutionTextScore(brand, queryTokens);
  var score = nameScore >= brandScore ? nameScore : brandScore * 0.6;
  if (machineTranslated) score -= machineTranslatedPenalty;
  return score.clamp(0.0, 1.0);
}

double _resolutionTextScore(String? text, Set<String> queryTokens) {
  final normalized = _normalize(text);
  if (normalized.isEmpty) return 0.0;
  return _softDice(_tokenize(normalized), queryTokens);
}

const _minPrefix = 3;

final _unspacedScript = RegExp(
  r'[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}'
  r'\p{Script=Hangul}]',
  unicode: true,
);

Set<String> _bigrams(String text) {
  if (text.length < 2) return {text};
  return {for (var i = 0; i < text.length - 1; i++) text.substring(i, i + 2)};
}

double _tokenSimilarity(String a, String b) {
  if (a == b) return 1.0;
  if (_unspacedScript.hasMatch(a) || _unspacedScript.hasMatch(b)) {
    final aGrams = _bigrams(a);
    final bGrams = _bigrams(b);
    final shared = aGrams.intersection(bGrams).length;
    if (shared == 0) return 0.0;
    return 2 * shared / (aGrams.length + bGrams.length);
  }
  final shorter = a.length < b.length ? a.length : b.length;
  final longer = a.length > b.length ? a.length : b.length;
  var shared = 0;
  while (shared < shorter && a.codeUnitAt(shared) == b.codeUnitAt(shared)) {
    shared++;
  }
  final required = _minPrefix < shorter ? _minPrefix : shorter;
  if (shared < required) return 0.0;
  return shared / longer;
}

double _softDice(Set<String> textTokens, Set<String> queryTokens) {
  if (textTokens.isEmpty || queryTokens.isEmpty) return 0.0;
  double bestSum(Set<String> from, Set<String> against) => from.fold(
    0.0,
    (sum, token) =>
        sum +
        against.fold<double>(0.0, (best, other) {
          final similarity = _tokenSimilarity(token, other);
          return similarity > best ? similarity : best;
        }),
  );
  final matched =
      bestSum(queryTokens, textTokens) + bestSum(textTokens, queryTokens);
  return matched / (queryTokens.length + textTokens.length);
}
