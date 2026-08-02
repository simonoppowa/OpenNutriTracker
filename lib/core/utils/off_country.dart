import 'package:opennutritracker/core/utils/locale_units.dart';

/// Derives the user's Open Food Facts country tag (e.g. `en:united-kingdom`)
/// from a platform locale name like `en_GB`, so the food search can softly
/// boost products sold in the user's country up the result ranking.
///
/// Returns null when the locale carries no country segment (e.g. `en`, `C`) or
/// the country isn't in the map — callers then simply skip the boost, which is
/// the safe default. The tag slugs are OFF's English country-name slugs,
/// verified against the live Search-a-licious index.
class OffCountry {
  OffCountry._();

  static const _isoToOffTag = <String, String>{
    'GB': 'en:united-kingdom',
    'US': 'en:united-states',
    'IE': 'en:ireland',
    'DE': 'en:germany',
    'AT': 'en:austria',
    'CH': 'en:switzerland',
    'FR': 'en:france',
    'IT': 'en:italy',
    'ES': 'en:spain',
    'PT': 'en:portugal',
    'NL': 'en:netherlands',
    'BE': 'en:belgium',
    'PL': 'en:poland',
    'CZ': 'en:czech-republic',
    'SK': 'en:slovakia',
    'TR': 'en:turkey',
    'UA': 'en:ukraine',
    'SE': 'en:sweden',
    'NO': 'en:norway',
    'DK': 'en:denmark',
    'FI': 'en:finland',
    'CA': 'en:canada',
    'AU': 'en:australia',
    'NZ': 'en:new-zealand',
    'JP': 'en:japan',
    'CN': 'en:china',
    'IN': 'en:india',
    'BR': 'en:brazil',
    'MX': 'en:mexico',
    'ZA': 'en:south-africa',
  };

  /// Maps a platform locale (`Platform.localeName`) to an OFF country tag.
  /// Handles forms like `en_GB`, `en-GB`, `en_GB.UTF-8`, `en` and `C`.
  static String? fromLocale(String localeName) {
    final country = countryCodeFromLocale(localeName);
    if (country == null) return null;
    return _isoToOffTag[country];
  }
}
