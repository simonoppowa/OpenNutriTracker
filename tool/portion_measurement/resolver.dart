// Resolves a query to the food the app would land on, and fetches that
// food's portions with English labels — the two read-only RPCs the
// measurement is allowed to call.
//
// The search is `search_food_summary` over PostgREST with the anon key,
// exactly the POST `SpFoodDataSource._searchEnglish` makes. Then the AI
// path's ranking as #1163 read it out of the code, with OFF empty and no
// custom meals, recipes or history:
//
//  1. `rankAndTruncateFoodsByName` — `textRelevanceScore` of the full
//     `name` against the query, stable, descending, the top 20;
//  2. `MealEntity.fromSpFood` — the shown name is `short_title ?? name`;
//  4. `mergeAndRankMeals` — `scoreMealRelevance` on the shown name, records
//     sharing a normalized shown name collapsed to the highest-scoring
//     (first seen on a tie), a stable sort, then `rankForResolution`'s soft
//     Dice, stable again — and index 0 is the food.
//
// Step 3, the search-cache round trip, is not modelled here either, for
// the reason #1163 gives: it can only reorder equal-scoring siblings, and
// the winner's *group* is fixed by the shown name. The portions are
// `portions_by_food_ids(ids, 'en')`, so every label is the English
// `portion_description` the model's key is matched against (#1157).
//
// The scorers are copied below rather than imported: `meal_relevance_ranker
// .dart` and `resolver_relevance.dart` reach `hive_ce_flutter` through
// `meal_entity.dart` and cannot be compiled by `dart run`. The copies are
// pinned to the originals by
// `test/unit_test/portion_measurement_parity_test.dart`.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

import 'cli.dart';

/// `SPConst.maxNumberOfItems * 5`, the pool `_searchEnglish` asks for, and
/// `SPConst.maxNumberOfItems`, what it keeps.
const candidatePoolSize = 100;
const maxNumberOfItems = 20;

/// The record the ranker put first, and everything the report needs to
/// name it.
class ResolvedFood {
  final int foodId;
  final String name;
  final String? shortTitle;
  final String source;

  /// `scoreMealRelevance` of the shown name, the score the collapse kept.
  final double score;
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
    required this.score,
    required this.poolSize,
    required this.poolTopName,
    required this.groupSize,
    required this.portions,
  });

  String get shownName => shortTitle ?? name;

  Map<String, Object?> toJson() => {
    'foodId': foodId,
    'name': name,
    'shortTitle': shortTitle,
    'source': source,
    'score': score,
    'poolSize': poolSize,
    'poolTopName': poolTopName,
    'groupSize': groupSize,
    'portions': [
      for (final p in portions) {'label': p.label, 'gramWeight': p.gramWeight},
    ],
  };
}

/// Caches per query, so a corpus that names the same forty foods a few
/// hundred times makes a few dozen backend calls.
class FoodResolver {
  final http.Client _client;
  final SupabaseAccess _access;
  /// Futures rather than values, so two lanes asking for the same food at
  /// the same moment share one call.
  final _cache = <String, Future<ResolvedFood?>>{};
  var rpcCalls = 0;

  FoodResolver(this._client, this._access);

  int get distinctQueries => _cache.length;

  /// The food [query] lands on, or null when the search returned nothing.
  Future<ResolvedFood?> resolve(String query) {
    final key = query.trim().toLowerCase();
    if (key.isEmpty) return Future.value(null);
    return _cache.putIfAbsent(key, () => _resolveUncached(query.trim()));
  }

  Future<ResolvedFood?> _resolveUncached(String query) async {
    final rows = await _rpc('search_food_summary', {
      'term': query,
      'sources': null,
      'max_rows': candidatePoolSize,
    });
    if (rows.isEmpty) return null;

    final landed = _aiPathWinner(rows, query);
    if (landed == null) return null;
    final id = landed.row['food_id'];
    if (id is! int) return null;

    final portionRows = await _rpc('portions_by_food_ids', {
      'ids': [id],
      'loc': 'en',
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

    return ResolvedFood(
      foodId: id,
      name: (landed.row['name'] as String?) ?? '',
      shortTitle: landed.row['short_title'] as String?,
      source: (landed.row['source'] as String?) ?? '',
      score: landed.score,
      poolSize: rows.length,
      poolTopName: landed.poolTopName,
      groupSize: landed.groupSize,
      portions: portions,
    );
  }

  /// Steps 1, 2 and 4 above over the raw pool.
  static ({Map<String, dynamic> row, double score, String? poolTopName, int groupSize})?
  _aiPathWinner(List<Map<String, dynamic>> rows, String query) {
    // 1. rankAndTruncateFoodsByName.
    final ranked = [
      for (final row in rows)
        (row: row, score: textRelevanceScore(row['name'] as String?, query)),
    ];
    mergeSort(ranked, compare: (a, b) => b.score.compareTo(a.score));
    final top20 = ranked.take(maxNumberOfItems).toList();
    if (top20.isEmpty) return null;
    final poolTop = top20.first.row;

    // 2 + 4. Shown name, scoreMealRelevance on it, collapse by normalized
    // shown name keeping the highest (strict >, so first seen on a tie).
    String shown(Map<String, dynamic> row) =>
        (row['short_title'] as String?) ?? (row['name'] as String?) ?? '';
    final groupOrder = <String>[];
    final groups = <String, List<({Map<String, dynamic> row, double score})>>{};
    for (final entry in top20) {
      final key = _normalize(shown(entry.row));
      final scored = (row: entry.row, score: scoreMealRelevance(shown(entry.row), query));
      if (!groups.containsKey(key)) groupOrder.add(key);
      groups.putIfAbsent(key, () => []).add(scored);
    }
    final collapsed = <({Map<String, dynamic> row, double score, int groupSize})>[];
    for (final key in groupOrder) {
      final group = groups[key]!;
      var best = group.first;
      for (final candidate in group.skip(1)) {
        if (candidate.score > best.score) best = candidate;
      }
      collapsed.add((row: best.row, score: best.score, groupSize: group.length));
    }
    // rankMealsByRelevance, then rankForResolution, both stable.
    mergeSort(collapsed, compare: (a, b) => b.score.compareTo(a.score));
    final resolved = [
      for (final c in collapsed)
        (c: c, r: resolutionScore(shown(c.row), query)),
    ];
    mergeSort(resolved, compare: (a, b) => b.r.compareTo(a.r));
    final winner = resolved.first.c;
    return (
      row: winner.row,
      score: winner.score,
      poolTopName: identical(winner.row, poolTop) ? null : poolTop['name'] as String?,
      groupSize: winner.groupSize,
    );
  }

  /// One PostgREST RPC: a POST with the parameters as the JSON body, so the
  /// search term never enters a URL (#882).
  Future<List<Map<String, dynamic>>> _rpc(
    String fn,
    Map<String, Object?> params,
  ) async {
    rpcCalls++;
    final anon = _access.anonKey();
    final response = await _client.post(
      _access.projectUrl.replace(path: '/rest/v1/rpc/$fn'),
      headers: {
        'apikey': anon,
        'Authorization': 'Bearer $anon',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(params),
    );
    if (response.statusCode != 200) {
      throw StateError('$fn answered ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw StateError('$fn did not return rows');
    return decoded.cast<Map<String, dynamic>>();
  }
}

// --- copied from meal_relevance_ranker.dart --------------------------------

/// `scoreMealRelevance` from `lib/features/add_meal/util/meal_relevance_ranker.dart`
/// for a backend food: no brand, `detailed` false, no machine translation in
/// the English locale, so the score is the name's text score alone.
double scoreMealRelevance(String? shownName, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return 0.0;
  return _textScore(shownName, normalizedQuery).clamp(0.0, 1.0);
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
/// for a backend food: no brand, no bonuses, so the soft Dice of the shown
/// name alone.
double resolutionScore(String? shownName, String query) {
  final queryTokens = _tokenize(_normalize(query));
  if (queryTokens.isEmpty) return 0.0;
  final normalized = _normalize(shownName);
  if (normalized.isEmpty) return 0.0;
  return _softDice(_tokenize(normalized), queryTokens).clamp(0.0, 1.0);
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
