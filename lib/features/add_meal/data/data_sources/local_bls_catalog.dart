import 'dart:convert';
import 'dart:io';

import 'package:opennutritracker/features/add_meal/data/data_sources/bls_synonyms.dart';

/// One food of the local BLS asset (`assets/bls/bls_4_0.json.gz`).
class BlsFood {
  final String code;
  final String nameDe;
  final String? nameEn;

  /// Values per 100 g in app units, keyed by app field name; a missing key
  /// means BLS gives no value.
  final Map<String, double> values;

  const BlsFood({
    required this.code,
    required this.nameDe,
    required this.nameEn,
    required this.values,
  });
}

/// The decoded BLS asset with an offline name search.
class LocalBlsCatalog {
  final List<BlsFood> foods;
  final List<({BlsFood food, List<String> tokens, String joined})> _index;

  LocalBlsCatalog(this.foods)
    : _index = [
        for (final food in foods)
          (
            food: food,
            tokens: _tokens(food.nameDe),
            joined: _normalize(
              food.nameDe,
            ).replaceAll(RegExp(r'[^a-z0-9]'), ''),
          ),
      ];

  /// Decodes the gzip-compressed asset written by `tool/bls/bls_to_asset.py`.
  factory LocalBlsCatalog.decode(List<int> gzipBytes) {
    final json =
        jsonDecode(utf8.decode(gzip.decode(gzipBytes))) as Map<String, dynamic>;
    final fields = (json['fields'] as List).cast<String>();
    return LocalBlsCatalog([
      for (final row in json['foods'] as List)
        BlsFood(
          code: (row as List)[0] as String,
          nameDe: row[1] as String,
          nameEn: row[2] as String?,
          values: {
            for (var i = 0; i < fields.length; i++)
              if ((row[3] as List)[i] != null)
                fields[i]: ((row[3] as List)[i] as num).toDouble(),
          },
        ),
    ]);
  }

  /// The best [limit] foods for [query], best first.
  ///
  /// Every word of the query has to match a word of the food name: exactly,
  /// as its singular ("Erbsen" → "Erbse"), as its start, inside it
  /// (compounds like "Haferflocken"), or, for words of five letters or more,
  /// with one typo. Words found in [blsSynonyms] (also with one typo) are
  /// searched as their BLS wording; filler words are dropped. Umlauts and
  /// their ae/oe/ue spelling match each other. Among equal matches, names
  /// that start with the query come first, then plain foods before dishes
  /// ("mit …", brackets), special variants ("glutenfrei") and preparations
  /// ("paniert") the query did not ask for, then shorter names.
  List<BlsFood> search(String query, {int limit = 20}) {
    final words = [
      for (final word in _tokens(query))
        if (!_fillerWords.contains(word)) word,
    ];
    if (words.isEmpty) return const [];
    final alternatives = [for (final word in words) _alternativesFor(word)];
    final asked = {
      for (final options in alternatives)
        for (final option in options) ...option,
    };
    final scored = <({BlsFood food, double score})>[];
    for (final entry in _index) {
      var score = 0.0;
      var matchedAll = true;
      for (final options in alternatives) {
        final best = _bestAlternative(options, entry.tokens, entry.joined);
        if (best == 0) {
          matchedAll = false;
          break;
        }
        score += best;
      }
      if (!matchedAll) continue;
      if (entry.tokens.isNotEmpty &&
          alternatives.first.any(
            (option) => option.first == entry.tokens.first,
          )) {
        score += 2;
      }
      if (entry.tokens.contains('roh')) score += 0.5;
      for (final marker in _dietVariants) {
        if (entry.tokens.contains(marker) && !asked.contains(marker)) {
          score -= 3;
        }
      }
      for (final marker in _dishMarkers) {
        if (entry.tokens.contains(marker) && !asked.contains(marker)) {
          score -= 0.6;
        }
      }
      if (entry.food.nameDe.contains('(') && !asked.contains('mit')) {
        score -= 0.4;
      }
      score -= entry.food.nameDe.length / 40;
      scored.add((food: entry.food, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return [for (final hit in scored.take(limit)) hit.food];
  }

  /// The best score of the [options] a query word stands for (itself and its
  /// BLS wording), each option counting only when all its words match.
  static double _bestAlternative(
    List<List<String>> options,
    List<String> tokens,
    String joined,
  ) {
    var best = 0.0;
    for (final option in options) {
      var sum = 0.0;
      for (final word in option) {
        final match = _bestMatch(word, tokens, joined);
        if (match == 0) {
          sum = 0;
          break;
        }
        sum += match;
      }
      final perWord = option.isEmpty ? 0.0 : sum / option.length;
      if (perWord > best) best = perWord;
    }
    return best;
  }

  /// Words that make a food a special diet variant; a name with one goes
  /// well down unless the query names it.
  static const _dietVariants = [
    'glutenfrei',
    'laktosefrei',
    'energiereduziert',
    'kohlenhydratreduziert',
    'zuckerfrei',
  ];

  /// Words that make a food a dish, a preparation or a product made from
  /// it; they push a name down a little unless the query names them.
  static const _dishMarkers = [
    'mit',
    'paniert',
    'frittiert',
    'pulver',
    'konserve',
    'dip',
    'dressing',
    'riegel',
    'eintopf',
    'auflauf',
    'torte',
    'kuchen',
    'suppe',
    'bolognese',
    'platzchen',
  ];

  /// Query words that say nothing about which food is meant.
  static const _fillerWords = {'natur', 'pur', 'normal', 'klassisch'};

  static double _bestMatch(String word, List<String> tokens, String joined) {
    var best = 0.0;
    for (final token in tokens) {
      final double value;
      if (token == word) {
        value = 3;
      } else if (word.length >= 5 && token == _singular(word)) {
        value = 2.5;
      } else if (token.startsWith(word)) {
        value = 2;
      } else if (word.length >= 4 && token.contains(word)) {
        value = 1;
      } else if (word.length >= 5 && _withinOneEdit(word, token)) {
        value = 0.8;
      } else {
        value = 0;
      }
      if (value > best) best = value;
    }
    if (best == 0 && word.length >= 5 && joined.contains(word)) best = 1.5;
    return best;
  }

  static final _synonyms = {
    for (final entry in blsSynonyms.entries)
      _normalize(entry.key): _tokens(entry.value),
  };

  /// A query word as itself and, when [blsSynonyms] has it, as its BLS
  /// wording.
  static List<List<String>> _alternativesFor(String word) {
    final synonym = _synonymFor(word);
    return [
      [word],
      if (synonym != null && synonym.isNotEmpty) synonym,
    ];
  }

  static List<String>? _synonymFor(String word) {
    final exact = _synonyms[word];
    if (exact != null || word.length < 5) return exact;
    for (final entry in _synonyms.entries) {
      if (entry.key.length >= 5 && _withinOneEdit(word, entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// [word] without a German plural ending: "erbsen" → "erbse",
  /// "tomaten" → "tomate", "bohnen" → "bohne".
  static String _singular(String word) {
    if (word.endsWith('en')) return word.substring(0, word.length - 1);
    if (word.endsWith('n') || word.endsWith('s')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  static List<String> _tokens(String text) => _normalize(
    text,
  ).split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).toList();

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss')
      .replaceAll('ae', 'a')
      .replaceAll('oe', 'o')
      .replaceAll('ue', 'u');

  /// Whether [a] and [b] differ by at most one insertion, deletion or
  /// substitution.
  static bool _withinOneEdit(String a, String b) {
    if ((a.length - b.length).abs() > 1) return false;
    var i = 0, j = 0, edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (a.length < b.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }
}
