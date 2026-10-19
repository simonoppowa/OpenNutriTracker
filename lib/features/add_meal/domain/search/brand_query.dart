import 'package:opennutritracker/features/add_meal/domain/search/german_brands.dart';

/// A food search split into the product words and the brands or stores it
/// names ([germanBrands], [germanStores]), for filtering Open Food Facts by
/// brand and ranking that brand's products first (#41).
class BrandQuery {
  /// The query without the brand and store words.
  final String text;

  /// Open Food Facts `brands_tags` of the brands the query names.
  final Set<String> brandTags;

  const BrandQuery._(this.text, this.brandTags);

  bool get hasBrands => brandTags.isNotEmpty;

  /// The Search-a-licious query: the product words, filtered to the brands
  /// (as a Lucene `brands_tags` clause) when the query names any.
  String get offQuery {
    if (!hasBrands) return text;
    final tags = brandTags.toList()..sort();
    final filter = tags.length == 1
        ? 'brands_tags:${tags.single}'
        : '(${tags.map((tag) => 'brands_tags:$tag').join(' OR ')})';
    return text.isEmpty ? filter : '$text $filter';
  }

  /// Whether a result's [brands] (as Open Food Facts lists them) is one of
  /// the named brands.
  bool matchesBrands(String? brands) {
    if (brands == null || !hasBrands) return false;
    return brands
        .split(',')
        .map(_slug)
        .any((slug) => slug.isNotEmpty && brandTags.contains(slug));
  }

  static BrandQuery parse(String query) {
    var rest = ' ${_fold(query)} ';
    final tags = <String>{};

    void take(String spelling, Iterable<String> found) {
      final pattern = ' ${_fold(spelling)} ';
      if (rest.contains(pattern)) {
        rest = rest.replaceFirst(pattern, ' ');
        tags.addAll(found);
      }
    }

    final spellings = [
      for (final brand in germanBrands.values)
        for (final spelling in brand.spellings) (spelling, brand.tags),
    ]..sort((a, b) => b.$1.length.compareTo(a.$1.length));
    for (final (spelling, brandTags) in spellings) {
      take(spelling, brandTags);
    }
    for (final MapEntry(key: store, value: info) in germanStores.entries) {
      take(store, [
        ...info.tags,
        for (final brand in info.brands) ...germanBrands[brand]!.tags,
      ]);
    }
    if (tags.isEmpty) return BrandQuery._(query.trim(), const {});
    return BrandQuery._(_keepOriginalWords(query, rest), tags);
  }

  /// The words of [original] that are still in [foldedRest], in their
  /// original spelling.
  static String _keepOriginalWords(String original, String foldedRest) {
    final remaining = foldedRest.trim().split(' ').where((w) => w.isNotEmpty);
    final pool = [...remaining];
    final kept = <String>[];
    for (final word in original.trim().split(RegExp(r'\s+'))) {
      final folded = _fold(word).trim();
      if (folded.isEmpty) continue;
      final parts = folded.split(' ');
      if (parts.every(pool.contains)) {
        for (final part in parts) {
          pool.remove(part);
        }
        kept.add(word);
      }
    }
    return kept.join(' ');
  }

  /// Lower case, umlauts folded, `-`, `&` and `+` read as spaces, `!` kept
  /// so that "ja!" stays a brand.
  static String _fold(String text) => text
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'[-&+/,.]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  /// An Open Food Facts brands_tags slug of a brand name.
  static String _slug(String brand) =>
      _fold(brand).replaceAll('!', '').trim().replaceAll(' ', '-');
}
