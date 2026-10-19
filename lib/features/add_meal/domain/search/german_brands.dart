/// A brand as Open Food Facts files it: the tags of its spellings
/// (`brands_tags`) and the ways people type it.
typedef KnownBrand = ({List<String> tags, List<String> spellings});

/// German private labels and well-known brands the food search recognises
/// in a query (#41). Spellings are matched case-insensitively with umlauts
/// folded and `-`/`&` read as spaces; tags are Open Food Facts'
/// `brands_tags` slugs. Extend the list when a brand search misses.
const germanBrands = <String, KnownBrand>{
  'naturgut': (
    tags: ['naturgut', 'natur-gut'],
    spellings: ['naturgut bio', 'naturgut', 'natur gut'],
  ),
  'paradiso': (tags: ['paradiso'], spellings: ['paradiso']),
  'ja': (tags: ['ja'], spellings: ['ja!']),
  'milbona': (tags: ['milbona'], spellings: ['milbona']),
  'crownfield': (tags: ['crownfield'], spellings: ['crownfield']),
  'pilos': (tags: ['pilos'], spellings: ['pilos']),
  'solevita': (tags: ['solevita'], spellings: ['solevita']),
  'freeway': (tags: ['freeway'], spellings: ['freeway']),
  'rewe beste wahl': (
    tags: ['rewe-beste-wahl'],
    spellings: ['rewe beste wahl', 'beste wahl'],
  ),
  'rewe bio': (tags: ['rewe-bio'], spellings: ['rewe bio']),
  'gut & günstig': (
    tags: ['gut-gunstig', 'gut-und-gunstig'],
    spellings: ['gut und gunstig', 'gut gunstig', 'gut & gunstig'],
  ),
  'edeka bio': (tags: ['edeka-bio'], spellings: ['edeka bio']),
  'k-classic': (tags: ['k-classic'], spellings: ['k classic', 'kclassic']),
  'gut bio': (tags: ['gut-bio'], spellings: ['gut bio']),
  'milsani': (tags: ['milsani'], spellings: ['milsani']),
};

/// Stores, with their own tag and the brands they sell as their own: a
/// store name in a query stands for all of them (#41).
const germanStores = <String, ({List<String> tags, List<String> brands})>{
  'penny': (tags: ['penny'], brands: ['naturgut', 'paradiso', 'ja']),
  'lidl': (
    tags: ['lidl'],
    brands: ['milbona', 'crownfield', 'pilos', 'solevita', 'freeway'],
  ),
  'rewe': (tags: ['rewe'], brands: ['ja', 'rewe beste wahl', 'rewe bio']),
  'edeka': (tags: ['edeka'], brands: ['gut & günstig', 'edeka bio']),
  'kaufland': (tags: ['kaufland'], brands: ['k-classic']),
  'aldi': (
    tags: ['aldi', 'aldi-sud', 'aldi-nord'],
    brands: ['gut bio', 'milsani'],
  ),
};
