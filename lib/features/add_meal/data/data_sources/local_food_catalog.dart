import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';

/// A food list shipped with the app and searched offline by name: the BLS
/// (`LocalBlsCatalog`) and FoodData Central (`LocalFdcCatalog`).
class LocalFoodCatalog<F> {
  final List<F> foods;
  final List<({F food, String name, List<String> tokens, String joined})>
  _index;
  final Map<String, List<String>> _synonyms;
  final Set<String> _plainWords;

  /// [nameOf] gives the name searched for a food; [synonyms] maps everyday
  /// words to the catalog's wording; a name with one of [plainWords] (the
  /// catalog's word for raw) goes up a little.
  LocalFoodCatalog(
    this.foods, {
    required String Function(F food) nameOf,
    Map<String, String> synonyms = const {},
    Set<String> plainWords = const {},
  }) : _plainWords = plainWords,
       _index = [
         for (final food in foods)
           (
             food: food,
             name: nameOf(food),
             tokens: _tokens(nameOf(food)),
             joined: _normalize(
               nameOf(food),
             ).replaceAll(RegExp(r'[^a-z0-9]'), ''),
           ),
       ],
       _synonyms = {
         for (final entry in synonyms.entries)
           _normalize(entry.key): _tokens(entry.value),
       };

  /// The best [limit] foods for [query], best first, among those [where]
  /// accepts.
  ///
  /// Every word of the query has to match a word of the food name: exactly,
  /// as its singular ("Erbsen" → "Erbse"), as its start, inside it
  /// (compounds like "Haferflocken"), or, for words of five letters or more,
  /// with one typo; a name word in its English plural counts like the
  /// singular. Words found in the synonyms (also with one typo) are
  /// searched as the catalog's wording; filler words are dropped. Umlauts and
  /// their ae/oe/ue spelling match each other. Among equal matches, names
  /// that start with the query come first, then plain foods before dishes
  /// ("mit …", brackets), special variants ("glutenfrei") and preparations
  /// ("paniert") the query did not ask for, then shorter names.
  List<F> search(String query, {int limit = 20, bool Function(F food)? where}) {
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
    final scored = <({F food, double score})>[];
    for (final entry in _index) {
      if (where != null && !where(entry.food)) continue;
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
            (option) => _isWordOrPlural(option.first, entry.tokens.first),
          )) {
        score += 2;
      }
      if (entry.tokens.any(_plainWords.contains)) score += 0.5;
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
      if (entry.name.contains('(') && !asked.contains('mit')) {
        score -= 0.4;
      }
      score -= entry.name.length / 40;
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
      } else if ((word.length >= 5 && token == _singular(word)) ||
          _isWordOrPlural(word, token)) {
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

  /// A query word as itself and, when the synonyms have it, as the
  /// catalog's wording.
  List<List<String>> _alternativesFor(String word) {
    final synonym = _synonymFor(word);
    return [
      [word],
      if (synonym != null && synonym.isNotEmpty) synonym,
    ];
  }

  List<String>? _synonymFor(String word) {
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

  /// Whether [token] is [word] or its English plural ("bananas",
  /// "tomatoes").
  static bool _isWordOrPlural(String word, String token) =>
      token == word || token == '${word}s' || token == '${word}es';

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

/// The search record of a local catalog food: [values] per 100 g in app
/// units, keyed by app field name, a missing key meaning no value.
SpFoodDTO localFoodDto({
  required int foodId,
  required String source,
  required String sourceCode,
  required String? name,
  String? localizedName,
  required Map<String, double> values,
}) {
  double? value(String field) => values[field];
  return SpFoodDTO(
    foodId: foodId,
    source: source,
    sourceCode: sourceCode,
    name: name,
    localizedName: localizedName,
    energyKcal100: value('energyKcal100'),
    carbohydrates100: value('carbohydrates100'),
    fat100: value('fat100'),
    proteins100: value('proteins100'),
    sugars100: value('sugars100'),
    saturatedFat100: value('saturatedFat100'),
    fiber100: value('fiber100'),
    monounsaturatedFat100: value('monounsaturatedFat100'),
    polyunsaturatedFat100: value('polyunsaturatedFat100'),
    transFat100: value('transFat100'),
    cholesterol100: value('cholesterol100'),
    sodium100: value('sodium100'),
    potassium100: value('potassium100'),
    magnesium100: value('magnesium100'),
    calcium100: value('calcium100'),
    iron100: value('iron100'),
    zinc100: value('zinc100'),
    phosphorus100: value('phosphorus100'),
    vitaminA100: value('vitaminA100'),
    vitaminC100: value('vitaminC100'),
    vitaminD100: value('vitaminD100'),
    vitaminB6100: value('vitaminB6100'),
    vitaminB12100: value('vitaminB12100'),
    niacin100: value('niacin100'),
    vitaminE100: value('vitaminE100'),
    vitaminK100: value('vitaminK100'),
    thiamin100: value('thiamin100'),
    riboflavin100: value('riboflavin100'),
    pantothenicAcid100: value('pantothenicAcid100'),
    biotin100: value('biotin100'),
    folate100: value('folate100'),
    iodine100: value('iodine100'),
    selenium100: value('selenium100'),
    copper100: value('copper100'),
    manganese100: value('manganese100'),
  );
}
