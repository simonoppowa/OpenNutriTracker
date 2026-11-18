import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/food_rpc_client.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:sqlite3/sqlite3.dart';

/// `meta.schema_version` this client reads. The backend's
/// `scripts/shared/build_sqlite.py` writes it as `SCHEMA_VERSION`; a file
/// with any other value is not opened.
const offlineFoodDbSchemaVersion = 1;

/// The five food functions, answered from a `foods.sqlite` built by
/// OpenNutriTracker-Backend's `scripts/shared/build_sqlite.py`.
///
/// Each statement is the one that script's `OfflineRpc` runs, which mirrors
/// the final Postgres definitions: the same filters, the same `has_portion
/// desc, title = term desc, length, food_id` order and the same columns. Rows
/// come back as the JSON PostgREST would have sent: booleans as `bool`, `tags`
/// as a list, numbers as stored (an integer where the Postgres numeric had no
/// decimal point, a double otherwise), so `SpFoodDTO.fromJson` and the
/// portion parsing read them unchanged.
///
/// Text matching is FTS5 rather than Postgres text search; the backend's
/// README lists where the two disagree on what matches.
class SqliteFoodRpcClient implements FoodRpcClient {
  SqliteFoodRpcClient(this.db);

  final Database db;

  static const _summaryColumns = [
    SPConst.foodId,
    SPConst.foodSource,
    SPConst.foodSourceCode,
    SPConst.foodName,
    SPConst.foodShortTitle,
    SPConst.foodBrands,
    SPConst.foodBarcode,
    SPConst.foodCategory,
    SPConst.servingQuantity,
    SPConst.servingUnit,
    SPConst.servingSize,
    SPConst.servingGramWeight,
    SPConst.thumbnailUrl,
    SPConst.mainImageUrl,
    SPConst.tags,
    'energy_kcal_100',
    'carbohydrates_100',
    'fat_100',
    'proteins_100',
    'sugars_100',
    'saturated_fat_100',
    'fiber_100',
    'monounsaturated_fat_100',
    'polyunsaturated_fat_100',
    'trans_fat_100',
    'cholesterol_100',
    'sodium_100',
    'potassium_100',
    'magnesium_100',
    'calcium_100',
    'iron_100',
    'zinc_100',
    'phosphorus_100',
    'vitamin_a_100',
    'vitamin_c_100',
    'vitamin_d_100',
    'vitamin_b6_100',
    'vitamin_b12_100',
    'niacin_100',
    SPConst.foodHasPortion,
  ];

  static final _summarySelect = _summaryColumns.map((c) => 'fs.$c').join(', ');

  @override
  Future<List<Map<String, dynamic>>> rpc(
    String fn,
    Map<String, dynamic> params,
  ) async => query(fn, params);

  /// [rpc], synchronously: SQLite answers on the calling isolate.
  List<Map<String, dynamic>> query(String fn, Map<String, dynamic> params) {
    switch (fn) {
      case SPConst.searchFoodSummaryFn:
        return _searchFoodSummary(params);
      case SPConst.searchFoodTranslationFn:
        return _searchFoodTranslation(params);
      case SPConst.foodSummaryByIdsFn:
        return _rows(
          '''
          select $_summarySelect from food_summary fs
          where fs.food_id in (select value from json_each(?1))
            and (?2 is null
                 or fs.source in (select value from json_each(?2)))
          order by fs.food_id''',
          [_json(params['ids']), _json(params['sources'])],
        );
      case SPConst.portionLabelsByFoodIdsFn:
        return _rows(
          '''
          select j.value as food_id, t.label as label
          from json_each(?1) j
          join food_summary fs on fs.food_id = j.value
          join food_portion_translation t
            on t.portion_description = fs.default_portion_description
           and t.locale = ?2 and t.source = 'verified'
          where t.label is not null and trim(t.label, ' ') <> ''
          order by j.key''',
          [_json(params['ids']), params['loc']],
        );
      case SPConst.portionsByFoodIdsFn:
        return _rows(
          '''
          select p.food_id, p.seq, coalesce(t.label, p.label_en) as label,
                 t.label is not null as localized, p.gram_weight, p.label_en
          from food_portion p
          left join food_portion_translation t
            on t.portion_description = p.label_en and t.locale = ?2
           and t.source = 'verified' and t.label is not null
           and trim(t.label, ' ') <> ''
          where p.food_id in (select value from json_each(?1))
          order by p.food_id, p.seq''',
          [_json(params['ids']), params['loc']],
        );
    }
    throw UnsupportedError('The offline food database has no function $fn');
  }

  List<Map<String, dynamic>> _searchFoodSummary(Map<String, dynamic> params) {
    final term = params['term'] as String?;
    final match = websearchToFts5(term, english: true);
    if (match == null) return const [];
    return _rows(
      '''
      select $_summarySelect
      from food_fts join food_summary fs on fs.food_id = food_fts.rowid
      where food_fts match ?1
        and (?2 is null or fs.source in (select value from json_each(?2)))
      order by fs.has_portion desc, (fs.title_key = ?3) desc,
               length(fs.name), fs.food_id
      limit max(coalesce(?4, 0), 0)''',
      [match, _json(params['sources']), pgBtrimLower(term!), _maxRows(params)],
    );
  }

  List<Map<String, dynamic>> _searchFoodTranslation(
    Map<String, dynamic> params,
  ) {
    final term = params['term'] as String?;
    final match = websearchToFts5(term, english: false);
    if (match == null) return const [];
    return _rows(
      '''
      select ft.food_id, ft.description, ft.source,
             coalesce(fs.has_portion, 0) as has_portion
      from food_translation_fts
      join food_translation ft on ft.id = food_translation_fts.rowid
      left join food_summary fs on fs.food_id = ft.food_id
      where food_translation_fts match ?1 and ft.locale = ?2
      order by coalesce(fs.has_portion, 0) desc, (ft.title_key = ?3) desc,
               length(ft.description), ft.food_id
      limit max(coalesce(?4, 0), 0)''',
      [match, params['loc'], pgBtrimLower(term!), _maxRows(params)],
    );
  }

  /// The functions' `max_rows int default 100`: absent is 100, an explicit
  /// null is `greatest(null, 0)`, which Postgres reads as 0.
  static Object? _maxRows(Map<String, dynamic> params) =>
      params.containsKey('max_rows') ? params['max_rows'] : 100;

  static String? _json(Object? list) => list == null ? null : jsonEncode(list);

  List<Map<String, dynamic>> _rows(String sql, List<Object?> args) => [
    for (final row in db.select(sql, args))
      {
        for (final key in row.keys)
          key: switch (key) {
            SPConst.foodHasPortion ||
            'localized' => row[key] == null ? null : row[key] != 0,
            SPConst.tags =>
              row[key] == null ? null : jsonDecode(row[key] as String),
            _ => row[key],
          },
      },
  ];
}

/// `lower(btrim(term))`: Postgres's `btrim` strips spaces only.
@visibleForTesting
String pgBtrimLower(String term) {
  var start = 0;
  var end = term.length;
  while (start < end && term.codeUnitAt(start) == 0x20) {
    start++;
  }
  while (end > start && term.codeUnitAt(end - 1) == 0x20) {
    end--;
  }
  return term.substring(start, end).toLowerCase();
}

/// Postgres's `english.stop`, which `websearch_to_tsquery('english', …)`
/// drops. FTS5 has no stopwords, so the query drops them instead.
final _englishStopwords =
    '''
i me my myself we our ours ourselves you your yours yourself yourselves he
him his himself she her hers herself it its itself they them their theirs
themselves what which who whom this that these those am is are was were be
been being have has had having do does did doing a an the and but if or
because as until while of at by for with about against between into through
during before after above below to from up down in out on off over under
again further then once here there when where why how all any both each few
more most other some such no nor not only own same so than too very s t can
will just don should now'''
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toSet();

/// A query word as the FTS tables tokenize it: letters and digits, with '/'
/// kept inside, as Postgres keeps "mango/papaya" one token.
final _word = RegExp(
  r'(?:[\p{L}\p{N}]|/)*[\p{L}\p{N}](?:[\p{L}\p{N}]|/)*',
  unicode: true,
);
final _space = RegExp(r'\s');

/// `websearch_to_tsquery` syntax as an FTS5 MATCH expression, or null when
/// nothing searchable is left (Postgres's empty query, which matches no
/// row).
///
/// Unquoted words are ANDed, "quoted text" is a phrase, `or` between terms
/// is OR and a leading `-` is NOT. Each word or phrase becomes an FTS5
/// string, which FTS5 tokenizes with the table's own tokenizer, so stemming
/// and diacritic folding apply to both sides. With [english], stopwords go:
/// whole words, and the leading and trailing ones of a phrase. A group of
/// negations alone cannot be expressed (FTS5 has no unary NOT) and is
/// dropped. Same algorithm as `websearch_to_fts5` in build_sqlite.py.
@visibleForTesting
String? websearchToFts5(String? term, {required bool english}) {
  if (term == null) return null;
  final groups = <List<(bool, List<String>)>>[[]];
  var i = 0;
  final n = term.length;
  while (i < n) {
    if (_space.hasMatch(term[i])) {
      i++;
      continue;
    }
    var negated = false;
    if (term[i] == '-' && i + 1 < n && !_space.hasMatch(term[i + 1])) {
      negated = true;
      i++;
    }
    final String text;
    final bool quoted;
    if (term[i] == '"') {
      var end = term.indexOf('"', i + 1);
      if (end < 0) end = n;
      text = term.substring(i + 1, end);
      i = end + 1;
      quoted = true;
    } else {
      var j = i;
      while (j < n && !_space.hasMatch(term[j]) && term[j] != '"') {
        j++;
      }
      text = term.substring(i, j);
      i = j;
      quoted = false;
    }
    if (!quoted && !negated && text.toLowerCase() == 'or') {
      groups.add([]);
      continue;
    }
    final words = [for (final m in _word.allMatches(text)) m[0]!];
    if (english) {
      while (words.isNotEmpty &&
          _englishStopwords.contains(words.first.toLowerCase())) {
        words.removeAt(0);
      }
      while (words.isNotEmpty &&
          _englishStopwords.contains(words.last.toLowerCase())) {
        words.removeLast();
      }
    }
    if (words.isNotEmpty) groups.last.add((negated, words));
  }
  final exprs = <String>[];
  for (final group in groups) {
    final positive = [
      for (final (neg, words) in group)
        if (!neg) '"${words.join(' ')}"',
    ];
    if (positive.isEmpty) continue;
    final buffer = StringBuffer('(${positive.join(' AND ')})');
    for (final (neg, words) in group) {
      if (neg) buffer.write(' NOT "${words.join(' ')}"');
    }
    exprs.add('($buffer)');
  }
  return exprs.isEmpty ? null : exprs.join(' OR ');
}
